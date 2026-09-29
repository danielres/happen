defmodule HappenWeb.ExperimentsLive.Ideas.Tools do
  use HappenWeb, :html
  use LiveDelegate, path: [:ideas, :tools]

  alias HappenWeb.ExperimentsLive.Ideas.Utils

  def on_mount(_params, _session, socket) do
    socket |> delegate_assign(nil)
  end

  def handle_event("open", _params, socket) do
    {:noreply, socket |> delegate_assign(:start)}
  end

  def handle_event("close", _params, socket) do
    {:noreply, socket |> delegate_assign(nil)}
  end

  def handle_event("reset_all_votes_start", _params, socket) do
    {:noreply, socket |> delegate_assign(:reset_all_votes)}
  end

  def handle_event("remove_unpopular_ideas_start", _params, socket) do
    {:noreply, socket |> delegate_assign(:remove_unpopular_ideas)}
  end

  def handle_event("remove_all_ideas_start", _params, socket) do
    {:noreply, socket |> delegate_assign(:remove_all_ideas)}
  end

  attr :active?, :boolean, required: true

  def button(assigns) do
    ~H"""
    <button
      data-testid={delegate_dom_id("button")}
      class={[
        "btn btn-sm btn-circle",
        !@active? && "opacity-50 hover:opacity-100 transition",
        @active? && "btn-warning"
      ]}
      phx-click={if(@active?, do: delegate_event("close"), else: delegate_event("open"))}
      type="button"
    >
      <.icon name="hero-cog-6-tooth-micro" />
    </button>
    """
  end

  attr :ideas, :list, required: true

  attr :tools, :atom,
    values: [:start, :reset_all_votes, :remove_unpopular_ideas, :remove_all_ideas],
    required: true

  def render(assigns) do
    ~H"""
    <div
      data-testid={delegate_dom_id("panel")}
      class="border-2 border-warning/75 bg-warning/10 rounded-box p-2 mb-2"
      phx-click-away={delegate_event("close")}
    >
      <div :if={@tools == :start} class="grid gap-2">
        <button
          class="btn btn-ghost btn-warning flex justify-between"
          data-testid={delegate_dom_id("reset-all-votes")}
          disabled={!Utils.has_votes?(@ideas)}
          phx-click={delegate_event("reset_all_votes_start")}
          type="button"
        >
          Reset all votes <.icon name="hero-chevron-right-micro" />
        </button>

        <button
          class="btn btn-ghost btn-warning flex justify-between"
          data-testid={delegate_dom_id("remove-unpopular-ideas")}
          disabled={!Utils.has_unpopular_ideas?(@ideas)}
          phx-click={delegate_event("remove_unpopular_ideas_start")}
          type="button"
        >
          Remove unpopular ideas <.icon name="hero-chevron-right-micro" />
        </button>

        <button
          class="btn btn-ghost btn-error flex justify-between"
          phx-click={delegate_event("remove_all_ideas_start")}
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
