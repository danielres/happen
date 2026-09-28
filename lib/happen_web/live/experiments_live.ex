defmodule HappenWeb.ExperimentsLive do
  use HappenWeb, :live_view
  use LiveDelegate

  alias HappenWeb.ExperimentsLive.Components
  alias HappenWeb.ExperimentsLive.Messages
  alias HappenWeb.ExperimentsLive.Presences
  alias HappenWeb.ExperimentsLive.Ideas
  alias HappenWeb.ExperimentsLive.User

  delegate(:messages, Messages)
  delegate(:ideas, Ideas)
  delegate(:presence, Presences, info: [:group])

  def mount(params, session, socket) do
    socket =
      socket
      |> assign(room: %{data: %{name: params["room_name"]}})
      |> then(&User.on_mount(params, session, &1))
      |> then(&Messages.on_mount(params, session, &1))
      |> then(&Presences.on_mount(params, session, &1))
      |> then(&Ideas.on_mount(params, session, &1))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app :if={!@user.data} mode="centered" flash={@flash}>
      <div class="bg-base-200 p-4 rounded-box">
        <User.form form={@user.form} room={@room.data} />
      </div>
    </Layouts.app>

    <Layouts.app :if={@user.data} flash={@flash}>
      <div>
        <header class={["bg-base-300 px-4 py-4"]}>
          <Components.Header.render user={@user.data} room={@room.data} />
        </header>

        <main class={[
          "grid gap-6 sm:gap-12",
          "sm:grid-cols-2 max-w-[40ch] sm:max-w-[80ch] mx-auto",
          "px-4 py-8"
        ]}>
          <div class={[
            "grid gap-6 sm:gap-12"
          ]}>
            <.section>
              <:title>Online now</:title>
              <Presences.list presences={@presences} />
            </.section>

            <.section>
              <:title>
                <div class="flex justify-between gap-4 items-end">
                  <div class="grow">Ideas</div>
                  <Ideas.button_tools :if={!@ideas[:form]} active?={@ideas.tools} />
                  <Ideas.button_add :if={!@ideas[:form]} />
                </div>
              </:title>

              <div class="grid gap-2">
                <Ideas.render_form :if={@ideas.form} form={@ideas.form} />
                <Ideas.render_tools :if={@ideas.tools} tools={@ideas.tools} />
                <Ideas.render stream={@streams.ideas} user_id={@user.data.id} />
              </div>
            </.section>
          </div>

          <.section>
            <:title>Ephemeral chit-chat</:title>
            <Messages.render
              form={@messages.form}
              stream={@streams.messages}
              ttl={@messages.ttl}
            />
          </.section>
        </main>
      </div>
    </Layouts.app>
    """
  end

  slot :title, required: false

  defp section(assigns) do
    ~H"""
    <section class="space-y-2">
      <h3 :if={@title != []} class="small-caps tracking-wider opacity-75">
        {render_slot(@title)}
      </h3>
      <div>{render_slot(@inner_block)}</div>
    </section>
    """
  end
end
