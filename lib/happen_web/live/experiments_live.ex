defmodule HappenWeb.ExperimentsLive do
  use HappenWeb, :live_view
  use LiveDelegate

  alias HappenWeb.ExperimentsLive.Components
  alias HappenWeb.ExperimentsLive.Messages
  alias HappenWeb.ExperimentsLive.Presences
  alias HappenWeb.ExperimentsLive.Ideas
  alias HappenWeb.ExperimentsLive.User
  alias HappenWeb.Components.Tabs

  delegate(:user, User)
  delegate(:messages, Messages)
  delegate(:presences, Presences, info: [:group])
  delegate(:ideas, Ideas)

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    socket =
      socket
      |> assign(room: %{data: %{name: params["room_name"]}})
      |> assign(active_tab: "ideas")
      |> delegate_mount(params, session)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("tabs:select", %{"tab" => tab}, socket)
      when tab in ["ideas", "messages", "presences"] do
    {:noreply, socket |> assign(:active_tab, tab)}
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
      <div class="max-w-md mx-auto space-y-3 px-4 py-2">
        <header>
          <Components.Header.render user={@user.data} room={@room.data} />
        </header>

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
              <:title>
                <div class="flex justify-between gap-4 items-end">
                  <div class="grow">Ideas</div>

                  <div class="h-0 flex items-end mr-1">
                    <Ideas.button_tools active?={@ideas.tools != nil} />
                  </div>
                </div>
              </:title>

              <div class="grid gap-2">
                <Ideas.render_form :if={is_nil(@ideas.tools)} form={@ideas.form} />
                <Ideas.render_tools :if={@ideas.tools} ideas={@ideas.data} tools={@ideas.tools} />
                <Ideas.render ideas={@ideas.data} user_id={@user.data.id} />
              </div>
            </.section>
          </Tabs.tab>

          <Tabs.tab
            active?={@active_tab == "messages"}
            name="main"
            phx-click="tabs:select"
            phx-value-tab="messages"
          >
            <:label><.icon name="hero-chat-bubble-left-mini" class="size-5" /></:label>
            <:indicator>
              <Tabs.count count={@messages.count} data-testid="messages-count" />
            </:indicator>

            <.section>
              <:title>Ephemeral chit-chat</:title>
              <Messages.render messages={@messages} stream={@streams.messages} />
            </.section>
          </Tabs.tab>

          <Tabs.tab
            active?={@active_tab == "presences"}
            name="main"
            phx-click="tabs:select"
            phx-value-tab="presences"
          >
            <:label><.icon name="hero-user-solid" class="size-5" /></:label>
            <:indicator>
              <Tabs.count count={length(@presences)} data-testid="presences-count" />
            </:indicator>
            <.section>
              <:title>Online now</:title>
              <Presences.render presences={@presences} />
            </.section>
          </Tabs.tab>
        </Tabs.render>
      </div>
    </Layouts.app>
    """
  end

  slot :title, required: false

  defp section(assigns) do
    ~H"""
    <section class="space-y-2">
      <h3 :if={@title != []} class="small-caps tracking-wider font-bold">
        {render_slot(@title)}
      </h3>

      <div>{render_slot(@inner_block)}</div>
    </section>
    """
  end
end
