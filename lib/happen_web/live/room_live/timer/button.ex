defmodule HappenWeb.RoomLive.Timer.Button do
  use HappenWeb, :live_view
  use LiveDelegate, path: [:timer, :button]

  alias HappenWeb.RoomLive.Timer.State

  def store_deadline(socket, deadline) do
    deadline = DateTime.to_unix(deadline, :millisecond)
    push_event(socket, "availability-timer:set", %{deadline: deadline})
  end

  attr :room, :map, required: true
  attr :timer, :map, required: true

  def render(assigns) do
    ~H"""
    <button
      phx-click="toggle_view"
      phx-value-view="timer"
      class={[
        "bg-base-100",
        "opacity-80 hover:opacity-100 transition",
        "cursor-pointer",
        "badge",
        "rounded-full gap-1",
        "text-[12px] font-semibold",
        "oldstyle-nums"
      ]}
      type="button"
    >
      <span
        id={"availability-timer-#{@room.key}"}
        data-room-key={@room.key}
        phx-hook=".AvailabilityTimer"
        class={@timer.remaining_min <= 5 && "text-red-300 animate-pulse"}
      >
        {@timer.remaining_min}
      </span>
      <.icon name="hero-clock-micro" class="size-3" />
    </button>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".AvailabilityTimer">
      export default {
        mounted() {
          const storedDeadline = this.readStoredDeadline()

          if (storedDeadline) this.pushEvent("timer:button:restore_deadline", { deadline: storedDeadline })

          this.handleEvent("availability-timer:set", ({ deadline }) => {
            this.storeDeadline(deadline)
          })

        },

        storageKey() {
          return `happen:availability:${this.el.dataset.roomKey}`
        },

        readStoredDeadline() {
          try {
            const deadline = Number(localStorage.getItem(this.storageKey()))

            if (Number.isFinite(deadline) && deadline > Date.now()) return deadline

            localStorage.removeItem(this.storageKey())
            return null
          } catch (_error) {
            return null
          }
        },

        storeDeadline(deadline) {
          try {
            localStorage.setItem(this.storageKey(), String(deadline))
          } catch (_error) {
            // Storage can be unavailable in private browsing modes.
          }
        },

      }
    </script>
    """
  end

  def handle_event("restore_deadline", %{"deadline" => unix_ms}, socket)
      when is_integer(unix_ms) do
    socket =
      with {:ok, deadline} <- DateTime.from_unix(unix_ms, :millisecond),
           :gt <- DateTime.compare(deadline, DateTime.now!("Etc/UTC")) do
        State.set_deadline(socket, deadline)
      else
        _invalid_deadline -> socket
      end

    {:noreply, socket}
  end

  def handle_event("restore_deadline", _params, socket), do: {:noreply, socket}
end
