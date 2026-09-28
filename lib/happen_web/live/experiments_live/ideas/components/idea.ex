defmodule HappenWeb.ExperimentsLive.Ideas.Components.Idea do
  use HappenWeb, :html

  alias HappenWeb.ExperimentsLive.Ideas.Components
  alias HappenWeb.ExperimentsLive.Ideas.Utils

  attr :idea, :map, required: true

  def render(assigns) do
    ~H"""
    <label class={[
      Utils.has_votes?(@idea) && "cursor-pointer",
      "block",
      "text text-base-content/75",
      "relative",
      "group"
    ]}>
      <input :if={Utils.has_votes?(@idea)} type="checkbox" class="peer sr-only" />

      <div class={[
        "peer-checked:hidden",
        "h-full",
        "px-4 py-3"
      ]}>
        <div class="text-sm">{@idea.body}</div>
        <div :if={Utils.has_votes?(@idea)} class="absolute right-2 top-0">
          <.icon
            name="hero-ellipsis-horizontal-micro"
            class={[
              "opacity-30 transition",
              "group-hover:opacity-100"
            ]}
          />
        </div>
      </div>

      <div
        data-testid={"idea-voters-#{@idea.id}"}
        class="hidden peer-checked:block"
      >
        <div class="p-4">
          <Components.VotersList.render idea={@idea} direction={:up} />
          <div
            :if={Utils.has_votes_up_and_down?(@idea)}
            class="h-0 border-b my-4 border-base-300"
          >
          </div>

          <Components.VotersList.render idea={@idea} direction={:down} />
        </div>
      </div>
    </label>
    """
  end
end
