defmodule HappenWeb.RoomLive do
  use HappenWeb, :live_view
  use LiveDelegate

  alias Happen.RoomKey
  alias HappenWeb.Components.Tabs
  alias HappenWeb.RoomLive.Components
  alias HappenWeb.RoomLive.Ideas
  alias HappenWeb.RoomLive.Invitation
  alias HappenWeb.RoomLive.Messages
  alias HappenWeb.RoomLive.Messages.Notification
  alias HappenWeb.RoomLive.Presences
  alias HappenWeb.RoomLive.PushNotifications
  alias HappenWeb.RoomLive.Timer
  alias HappenWeb.RoomLive.User

  delegate(:user, User)
  delegate(:push_notifications, PushNotifications)
  delegate(:messages, Messages)
  delegate(:presences, Presences, info: [:group])
  delegate(:ideas, Ideas)
  delegate(:invitation, Invitation, mount: false, info: false)
  delegate(:timer, Timer)

  @impl Phoenix.LiveView
  def mount(%{"room_key" => room_key} = params, session, socket) do
    case RoomKey.decode(room_key) do
      {:ok, room_name} ->
        params = Map.put(params, "room_name", room_name)

        tz =
          case get_connect_params(socket) do
            %{"tz" => timezone} -> timezone
            _ -> "Etc/UTC"
          end

        socket =
          socket
          |> assign(room: %{data: %{key: room_key, name: room_name}})
          |> assign(view: "timer")
          |> assign(tz: tz)
          |> assign(active_tab: "ideas")
          |> delegate_mount(params, session)

        {:ok, socket}

      :error ->
        {:ok, redirect(socket, to: ~p"/")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_view", %{"view" => view}, socket) do
    view = if view == socket.assigns.view, do: "main", else: view
    {:noreply, socket |> assign(view: view)}
  end

  @impl Phoenix.LiveView
  def handle_event("tabs:select", %{"tab" => tab}, socket)
      when tab in ["ideas", "messages", "presences"] do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app :if={!@user.data} mode="centered" flash={@flash}>
      <div class="bg-base-200 p-4 rounded-box">
        <User.form form={@user.form} room={@room.data} />
      </div>
    </Layouts.app>

    <Layouts.app :if={@user.data} flash={@flash}>
      <PushNotifications.root push_notifications={@push_notifications}>
        <div class="max-w-md mx-auto space-y-3 px-4 py-2">
          <div
            class="flex justify-end"
            phx-hook="AutoAnimate"
            id="push-notifications-prompt"
          >
            <PushNotifications.prompt push_notifications={@push_notifications} />
          </div>

          <header>
            <Components.Header.render
              push_notifications={@push_notifications}
              room={@room}
              timer={@timer}
              user={@user}
            />
          </header>

          <div phx-hook="AutoAnimate" id="room-views">
            <.view_main
              :if={@view == "main"}
              active_tab={@active_tab}
              ideas={@ideas}
              messages={@messages}
              presences={@presences}
              streams={@streams}
              user={@user}
            />

            <div :if={@view == "timer"}>
              <.section>
                <:actions><Timer.render_deadline tz={@tz} timer={@timer} /></:actions>
                <:title>Make me available for</:title>
                <Timer.render_form timer={@timer} />
              </.section>
            </div>
          </div>
        </div>
      </PushNotifications.root>
    </Layouts.app>
    """
  end

  slot :title, required: false
  slot :head, required: false
  slot :actions, required: false

  defp section(assigns) do
    ~H"""
    <section>
      <div :if={@head != []}>
        {render_slot(@head)}
      </div>

      <div class="flex gap-4 justify-between items-baseline">
        <h3 :if={@title != []} class="small-caps tracking-wider font-bold">
          {render_slot(@title)}
        </h3>
        <div :if={@actions != []}>{render_slot(@actions)}</div>
      </div>

      <div class="mt-2">{render_slot(@inner_block)}</div>
    </section>
    """
  end

  attr :active_tab, :string, required: true
  attr :ideas, :map, required: true
  attr :messages, :map, required: true
  attr :presences, :list, required: true
  attr :streams, :list, required: true
  attr :user, :map, required: true

  defp view_main(assigns) do
    ~H"""
    <Tabs.render>
      <Tabs.tab
        active?={@active_tab == "ideas"}
        name="main"
        phx-click="tabs:select"
        phx-value-tab="ideas"
      >
        <:label><.icon name="hero-light-bulb-mini" class="size-5" /></:label>
        <:indicator>
          <Tabs.count count={@ideas.data |> length()} data-testid="ideas-count" />
        </:indicator>

        <.section>
          <:title>Ideas</:title>
          <:actions><Ideas.button_tools active?={@ideas.tools != nil} /></:actions>

          <div id="ideas-editor" class="grid gap-2" phx-hook="AutoAnimate">
            <div :if={is_nil(@ideas.tools)} id="ideas-form-panel">
              <Ideas.render_form form={@ideas.form} />
            </div>
            <div :if={@ideas.tools} id="ideas-tools-panel">
              <Ideas.render_tools ideas={@ideas.data} tools={@ideas.tools} />
            </div>
            <Ideas.render ideas={@ideas} user_id={@user.data.id} />
          </div>
        </.section>
      </Tabs.tab>

      <Tabs.tab
        active?={@active_tab == "messages"}
        data-testid="messages-tab"
        name="main"
        phx-click="tabs:select"
        phx-value-tab="messages"
      >
        <:label>
          <Notification.render notification={@messages.notification}>
            <.icon name="hero-chat-bubble-left-mini" class="size-5" />
          </Notification.render>
        </:label>
        <:indicator>
          <Tabs.count count={@messages.count} data-testid="messages-count" />
        </:indicator>

        <.section>
          <:title>Ephemeral chit-chat</:title>
          <Messages.render_form :if={@active_tab == "messages"} messages={@messages} />
          <Messages.render messages={@messages} stream={@streams.messages} />
        </.section>
      </Tabs.tab>

      <Tabs.tab
        active?={@active_tab == "presences"}
        name="main"
        phx-click="tabs:select"
        phx-value-tab="presences"
      >
        <:label><.icon name="hero-users-solid" class="size-5" /></:label>
        <:indicator>
          <Tabs.count count={length(@presences)} data-testid="presences-count" />
        </:indicator>
        <.section>
          <:title>Available now</:title>
          <:actions><Invitation.render_button /></:actions>
          <Presences.render presences={@presences} />
        </.section>
      </Tabs.tab>
    </Tabs.render>
    """
  end
end
