defmodule HappenWeb.RoomLive do
  use HappenWeb, :live_view

  alias Happen.PS
  alias HappenWeb.Components
  alias HappenWeb.Presence

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

  def handle_info(%{message: message}, socket) do
    messages = socket.assigns.messages
    messages = messages ++ [message]
    socket = socket |> assign(messages: messages)
    {:noreply, socket}
  end

  def handle_event("say", params, socket) do
    :ok =
      PS.message_broadcast(socket.assigns.room, %{
        member: socket.assigns.member,
        body: params["message"]
      })

    {:noreply, push_event(socket, "message-sent", %{})}
  end

  def render(assigns) do
    ~H"""
    <%= if @member do %>
      <Layouts.app flash={@flash}>
        <div class="flex h-dvh min-h-0 flex-col overflow-hidden">
          <header class="bg-base-300 flex shrink-0 items-end justify-between gap-4 p-4">
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
              <HappenWeb.Components.Badge.render member={@member} />
            </button>
          </header>

          <main class="flex min-h-0 flex-1 flex-col gap-8 p-4">
            <section class="shrink-0">
              <h3 class="small-caps opacity-60">Online now</h3>

              <ul class="flex flew-wrap gap-2">
                <li :for={{_pid, member} <- @members}>
                  <HappenWeb.Components.Badge.render member={member} />
                </li>
              </ul>
            </section>

            <section class="flex min-h-0 flex-1 flex-col gap-2">
              <h3 :if={@messages |> length() > 0} class="small-caps opacity-60">Messages</h3>
              <HappenWeb.Sections.Messages.render messages={@messages} />
            </section>
          </main>
        </div>
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
end
