defmodule HappenWeb.ExperimentsLive.Ideas.Tools do
  use HappenWeb, :live_view

  def on_mount(params, session, socket) do
     socket |> update(:ideas, &Map.put(&1, :tools, :start))
  end

  def handle_event("toggle", _params, socket) do
    tools_active? = socket.assigns.ideas.tools != nil
    tools = if tools_active?, do: nil, else: :start
    socket = socket |> update(:ideas, &Map.put(&1, :tools, tools))
    {:noreply, socket}
  end

  def handle_event("reset_all_votes_start", _params, socket) do
    socket = socket |> update(:ideas, &Map.put(&1, :tools, :reset_all_votes))
    {:noreply, socket}
  end

  def handle_event("remove_unpopular_ideas_start", _params, socket) do
    socket = socket |> update(:ideas, &Map.put(&1, :tools, :remove_unpopular_ideas))
    {:noreply, socket}
  end

  def handle_event("remove_all_ideas_start", _params, socket) do
    socket = socket |> update(:ideas, &Map.put(&1, :tools, :remove_all_ideas))
    {:noreply, socket}
  end

  attr :active?, :boolean, required: true

  def button(assigns) do
    ~H"""
    <button
      data-testid="ideas-tools"
      class={[
        "btn btn-xs btn-circle",
        !@active? && "opacity-50 hover:opacity-100 transition",
        @active? && "btn-warning"
      ]}
      phx-click="ideas:tools:toggle"
      type="button"
    >
      <.icon name="hero-cog-6-tooth-micro" />
    </button>
    """
  end

  def render(assigns) do
    ~H"""
    <div
      class={[
        "border-2 border-warning/75 bg-warning/10 rounded-box p-2 mb-2"
      ]}
      phx-click-away="ideas:tools:toggle"
    >
      <div :if={@tools == :start} class="grid gap-2">
        <button
          class="btn btn-ghost btn-warning flex justify-between"
          phx-click="ideas:tools:reset_all_votes_start"
        >
          Reset all votes <.icon name="hero-chevron-right-micro" />
        </button>

        <button
          class="btn btn-ghost btn-warning flex justify-between"
          phx-click="ideas:tools:remove_unpopular_ideas_start"
        >
          Remove unpopular ideas <.icon name="hero-chevron-right-micro" />
        </button>

        <button
          class="btn btn-ghost btn-error flex justify-between"
          phx-click="ideas:tools:remove_all_ideas_start"
        >
          Remove all ideas <.icon name="hero-chevron-right-micro" />
        </button>
      </div>

      <div :if={@tools == :reset_all_votes}>
        Are you sure?
      </div>

      <div :if={@tools == :remove_unpopular_ideas}>
        Are you sure? (remove unpopular)
      </div>

      <div :if={@tools == :remove_all_ideas}>
        Are you sure? (remove all)
      </div>
    </div>
    """
  end
end
