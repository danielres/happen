defmodule HappenWeb.ExperimentsLive.Ideas.Components.Tools do
  use HappenWeb, :html

  alias HappenWeb.ExperimentsLive.Ideas.Utils
  alias HappenWeb.ExperimentsLive.User

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
      phx-click="ideas:tools_toggle"
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
      phx-click-away="ideas:tools_toggle"
    >
      <div :if={@tools == :start} class="grid gap-2">
        <button
          class="btn btn-ghost btn-warning flex justify-between"
          phx-click="ideas:tools_reset_all_votes_start"
        >
          Reset all votes <.icon name="hero-chevron-right-micro" />
        </button>

        <button
          class="btn btn-ghost btn-warning flex justify-between"
          phx-click="ideas:tools_remove_unpopular_ideas_start"
        >
          Remove unpopular ideas <.icon name="hero-chevron-right-micro" />
        </button>

        <button
          class="btn btn-ghost btn-error flex justify-between"
          phx-click="ideas:tools_remove_all_ideas_start"
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
