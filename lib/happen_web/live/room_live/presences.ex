defmodule HappenWeb.RoomLive.Presences do
  use HappenWeb, :live_view
  use LiveDelegate, path: [:presences]

  alias HappenWeb.RoomLive.User

  def on_mount(_params, _session, socket) do
    socket
    |> delegate_assign([])
    |> monitor()
    |> join()
  end

  def leave_event, do: delegate_event("leave")

  def set_deadline(socket, deadline) do
    if connected?(socket) && socket.assigns.user.data do
      room_name = socket.assigns.room.data.name
      presence = Map.put(socket.assigns.user.data, :deadline, deadline)
      :ok = Group.join(:happen, room_name, presence)
    end

    socket
  end

  def handle_event("leave", _payload, socket) do
    room = socket.assigns.room
    user = socket.assigns.user.data
    _result = Happen.Push.leave_room(user.id, room.data.name)
    :ok = Group.leave(:happen, room.data.name)
    {:noreply, redirect(socket, to: ~p"/guest/logout")}
  end

  def handle_info({_events, _info}, socket) do
    room = socket.assigns.room
    {:noreply, socket |> delegate_assign(get_presences(room))}
  end

  defp join(socket) do
    if connected?(socket) && socket.assigns.user.data do
      room_name = socket.assigns.room.data.name
      user = socket.assigns.user.data
      presences = Group.members(:happen, room_name)
      user = %{user | hue: pick_hue(presences, user.id)}

      :ok = Group.join(:happen, room_name, user)

      update(socket, :user, fn user_assign ->
        %{user_assign | data: user}
      end)
    else
      socket
    end
  end

  defp monitor(socket) do
    if connected?(socket) do
      :ok = Group.monitor(:happen, socket.assigns.room.data.name)
    end

    socket
  end

  defp get_presences(room) do
    Group.members(:happen, room.data.name)
    |> Enum.uniq_by(fn {_pid, member} -> member.id end)
    |> Enum.sort_by(fn {_pid, presence} ->
      case presence[:deadline] do
        %DateTime{} = deadline -> {0, DateTime.to_unix(deadline, :millisecond)}
        nil -> {1, 0}
      end
    end)
  end

  defp pick_hue(presences, user_id) do
    case Enum.find(presences, fn {_pid, presence} -> presence.id == user_id end) do
      {_pid, presence} -> presence.hue
      nil -> pick_unused_hue(presences)
    end
  end

  defp pick_unused_hue([]), do: 40

  defp pick_unused_hue(presences) do
    hues =
      presences
      |> Enum.map(fn {_pid, presence} -> Integer.mod(presence.hue, 360) end)
      |> Enum.uniq()
      |> Enum.sort()

    first_hue = hd(hues)

    {left_hue, right_hue} =
      hues
      |> Enum.zip(tl(hues) ++ [first_hue + 360])
      |> Enum.max_by(fn {left_hue, right_hue} -> right_hue - left_hue end)

    Integer.mod(div(left_hue + right_hue, 2), 360)
  end

  attr :presences, :list, required: true
  attr :tz, :string, required: true

  def render(assigns) do
    ~H"""
    <div class="bg-base-200 rounded-box">
      <table class="table">
        <thead>
          <tr>
            <th></th>
            <th class="w-0">
              <div class="flex items-center gap-1 justify-end">
                <.icon name="hero-clock-mini" class="opacity-60 size-4" />
                <span>Until</span>
              </div>
            </th>
          </tr>
        </thead>
        <tbody id="presences-list" phx-hook="AutoAnimate">
          <tr :for={{_pid, presence} <- @presences} id={presence.id}>
            <td><User.badge user={presence} /></td>
            <td class="text-right">
              <div
                :if={presence[:deadline]}
                id={"presence-deadline-#{presence.id}"}
                class="opacity-60 whitespace-nowrap flex gap-4 items-baseline justify-end"
                data-deadline={DateTime.to_unix(presence.deadline, :millisecond)}
                data-formatted-deadline={format_deadline(presence.deadline, @tz)}
                data-testid={"presence-deadline-#{presence.id}"}
                phx-hook=".RemainingMinutes"
                phx-update="ignore"
              >
                <span data-remaining-minutes class="text-xs"></span>
                <span data-deadline-time class="font-bold text-sm">{format_deadline(
                  presence.deadline,
                  @tz
                )}</span>
                <span data-expired hidden>—</span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".RemainingMinutes">
      export default {
        mounted() {
          this.handleVisibilityChange = () => {
            if (!document.hidden) this.renderRemainingMinutes()
          }

          document.addEventListener("visibilitychange", this.handleVisibilityChange)
          this.renderRemainingMinutes()
        },

        updated() {
          this.renderRemainingMinutes()
        },

        destroyed() {
          window.clearTimeout(this.timeout)
          document.removeEventListener("visibilitychange", this.handleVisibilityChange)
        },

        renderRemainingMinutes() {
          window.clearTimeout(this.timeout)

          const deadline = Number(this.el.dataset.deadline)
          const remainingMilliseconds = deadline - Date.now()
          const deadlineElement = this.el.querySelector("[data-deadline-time]")
          const remainingElement = this.el.querySelector("[data-remaining-minutes]")
          const expiredElement = this.el.querySelector("[data-expired]")

          if (remainingMilliseconds <= 0) {
            deadlineElement.hidden = true
            remainingElement.hidden = true
            expiredElement.hidden = false
            return
          }

          const millisecondsPerMinute = 60_000
          const remainingMinutes = Math.ceil(remainingMilliseconds / millisecondsPerMinute)
          const millisecondsUntilChange =
            remainingMilliseconds - (remainingMinutes - 1) * millisecondsPerMinute

          deadlineElement.hidden = false
          deadlineElement.textContent = this.el.dataset.formattedDeadline
          remainingElement.hidden = false
          remainingElement.textContent = `${remainingMinutes} min`
          expiredElement.hidden = true

          this.timeout = window.setTimeout(
            () => this.renderRemainingMinutes(),
            millisecondsUntilChange + 10,
          )
        },
      }
    </script>
    """
  end

  defp format_deadline(deadline, timezone) do
    case DateTime.shift_zone(deadline, timezone) do
      {:ok, local_deadline} -> Calendar.strftime(local_deadline, "%H:%M")
      {:error, _reason} -> Calendar.strftime(deadline, "%H:%M UTC")
    end
  end
end
