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
    :ok = PS.message_broadcast(socket.assigns.room, params["message"])
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
              <.badge member={@member} />
            </button>
          </header>

          <main class="flex min-h-0 flex-1 flex-col gap-8 p-4">
            <section class="shrink-0">
              <h3 class="font-semibold">Online now</h3>

              <ul class="flex flew-wrap gap-2">
                <li :for={{_pid, member} <- @members}>
                  <.badge member={member} />
                </li>
              </ul>
            </section>

            <section class="flex min-h-0 flex-1 flex-col gap-2">
              <h3 class="shrink-0 font-semibold">Messages</h3>

              <ul
                id="messages"
                class="min-h-0 flex-1 space-y-1 overflow-y-auto"
                phx-hook=".AutoScroll"
              >
                <li :for={message <- @messages} class="bg-base-200 py-2 px-4">
                  <div class="text-sm opacity-50">{message.member.name}</div>
                  <div>{message.body}</div>
                </li>
              </ul>

              <form
                id="message-form"
                class="join grid shrink-0 grid-cols-[1fr_auto]"
                phx-hook=".ClearMessage"
                phx-submit="say"
              >
                <input
                  class="join-item input w-full input-primary"
                  type="text"
                  name="message"
                  placeholder="Say something"
                  phx-mounted={JS.focus()}
                />

                <.button class="join-item btn btn-primary" type="submit">
                  <.icon name="hero-paper-airplane -rotate-45" />
                  <span class="sr-only">Say</span>
                </.button>
              </form>

              <script :type={Phoenix.LiveView.ColocatedHook} name=".ClearMessage">
                export default {
                  mounted() {
                    this.handleEvent("message-sent", () => this.el.reset())
                  }
                }
              </script>

              <script :type={Phoenix.LiveView.ColocatedHook} name=".AutoScroll">
                export default {
                  mounted() {
                    this.scrollToBottom()
                  },

                  beforeUpdate() {
                    this.followingLatest =
                      this.el.scrollHeight - this.el.scrollTop - this.el.clientHeight < 64
                  },

                  updated() {
                    if (this.followingLatest) this.scrollToBottom()
                  },

                  scrollToBottom() {
                    this.el.scrollTop = this.el.scrollHeight
                  }
                }
              </script>
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
