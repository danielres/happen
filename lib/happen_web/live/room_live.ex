defmodule HappenWeb.RoomLive do
  use HappenWeb, :live_view
  alias HappenWeb.Presence
  alias Happen.PS

  def mount(params, _session, socket) do
    room_id = params["room_id"]

    case Happen.Rooms.get(Happen.Rooms.Room, room_id) do
      {:ok, room} ->
        Presence.monitor(socket, room_id)
        PS.messages_subscribe(socket, room)
        member = %{name: "toto", available?: true}

        socket =
          socket
          |> assign(room: room)
          |> assign(members: [])
          |> assign(member: nil)
          |> assign(messages: [])
          # |> assign(member: member)

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
    room_id = socket.assigns.room.id
    Presence.toggle(room_id, socket.assigns.member)
    member = socket.assigns.member
    member = %{name: member.name, available?: !member.available?}
    socket = socket |> assign(member: member)
    {:noreply, socket}
  end

  def handle_event("join", %{"name" => name}, socket) do
    room_id = socket.assigns.room.id
    member = %{name: name, available?: true}
    Presence.join(room_id, member)
    socket = socket |> assign(member: member)
    {:noreply, socket}
  end

  def handle_info({:group, _events, _info}, socket) do
    room_id = socket.assigns.room.id
    members = Presence.get_members(room_id)
    socket = socket |> assign(members: members)
    {:noreply, socket}
  end

  def handle_info(%{message: msg}, socket) do
    message = %{member: socket.assigns.member, body: msg}
    messages = socket.assigns.messages
    messages = messages ++ [message]
    socket = socket |> assign(messages: messages)
    {:noreply, socket}
  end

  def handle_event("say", params, socket) do
    message = %{member: socket.assigns.member, body: params["message"]}
    PS.message_broadcast(socket.assigns.room, params["message"])
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <%= if @member do %>
      <Layouts.app flash={@flash}>
        <header class="bg-base-300 p-4 flex justify-between gap-4 items-end">
          <h1>
            <div class="uppercase text-xs opacity-50">Room</div>
            <div class="font-semibold opacity-60">{@room.name}</div>
          </h1>

          <button
            phx-click="toggle"
            type="button"
            class="flex items-baseline gap-2 cursor-pointer text-xs"
          >
            <span :if={@member.available?} class="text-success">Available now</span>
            <span :if={!@member.available?} class="text-warning">Not available now</span>
            <.badge member={@member} />
          </button>
        </header>

        <main class="p-4 space-y-8">
          <section>
            <h3 class="font-semibold">Online now</h3>

            <ul class="flex flew-wrap gap-2">
              <li :for={{_pid, member} <- @members}>
                <.badge member={member} />
              </li>
            </ul>
          </section>

          <section class="space-y-2">
            <h3 class="font-semibold">Messages</h3>

            <ul class="space-y-1">
              <li :for={message <- @messages} class="bg-base-200 py-2 px-4">
                <div class="text-sm opacity-50">{message.member.name}</div>
                <div>{message.body}</div>
              </li>
            </ul>

            <form phx-submit="say" class="join grid grid-cols-[1fr_auto]">
              <input
                class="join-item input w-full"
                type="text"
                name="message"
                placeholder="Say something"
              />

              <.button class="join-item btn" type="submit">Say</.button>
            </form>
          </section>
        </main>
      </Layouts.app>
    <% else %>
      <Layouts.app mode="centered" flash={@flash}>
        <form phx-submit="join" class="grid gap-2">
          <input type="text" class="input" name="name" placeholder="How should we call you?" />
          <.button type="submit">Join room</.button>
        </form>
      </Layouts.app>
    <% end %>
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
