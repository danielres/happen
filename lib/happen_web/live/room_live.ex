defmodule HappenWeb.RoomLive do
  use HappenWeb, :live_view
  alias HappenWeb.Presence

  def mount(params, _session, socket) do
    room_id = params["room_id"]

    case Happen.Rooms.get(Happen.Rooms.Room, room_id) do
      {:ok, room} ->
        Presence.monitor(socket, room_id)

        socket =
          socket
          |> assign(room_id: room_id)
          |> assign(members: [])
          |> assign(member: nil)

        {:ok, socket}

      {:error, error} ->
        socket =
          socket
          |> put_flash(:info, "group not found")
          |> push_navigate(to: ~p"/")

        {:ok, socket}
    end
  end

  def handle_event("toggle", _, socket) do
    room_id = socket.assigns.room_id
    Presence.toggle(room_id, socket.assigns.member)
    member = socket.assigns.member
    member = %{name: member.name, available?: !member.available?}
    socket = socket |> assign(member: member)
    {:noreply, socket}
  end

  def handle_event("join", %{"name" => name}, socket) do
    room_id = socket.assigns.room_id
    member = %{name: name, available?: true}
    Presence.join(room_id, member)
    socket = socket |> assign(member: member)
    {:noreply, socket}
  end

  def handle_info({:group, _events, _info}, socket) do
    room_id = socket.assigns.room_id
    members = Presence.get_members(room_id)
    socket = socket |> assign(members: members)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <%= if @member do %>
        <header class="bg-base-300 p-4 flex justify-end">
          <button phx-click="toggle" type="button" class="flex items-baseline gap-2 cursor-pointer">
            <span :if={@member.available?} class="text-success">Available now</span>
            <span :if={!@member.available?} class="text-warning">Not available now</span>
            <.badge member={@member} />
          </button>
        </header>

        <main class="p-4">
          <section>
            <h3 class="flex gap-4 items-baseline">
              <span class="font-semibold">Online now</span>
              <span class="text-success text-xs">Available</span>
              <span class="text-warning text-xs">Not available</span>
            </h3>
            <ul class="flex flew-wrap gap-2">
              <li :for={{_pid, member} <- @members}>
                <.badge member={member} />
              </li>
            </ul>
          </section>
        </main>
      <% else %>
        <form phx-submit="join">
          <input type="text" class="input" name="name" placeholder="Enter your name" />
          <button class="btn" type="submit">Join room</button>
        </form>
      <% end %>
    </Layouts.app>
    """
  end

  def badge(assigns) do
    ~H"""
    <span class={[
      "badge ",
      @member.available? && "bg-success",
      !@member.available? && "bg-warning"
    ]}>
      {@member.name}
    </span>
    """
  end
end
