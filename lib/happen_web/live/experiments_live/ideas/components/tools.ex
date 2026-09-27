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
    <div class={[
      "border border-warning/50 bg-warning/10 rounded-box p-2 mb-2"
    ]}>
      <div class="grid gap-2">
        <button class="btn btn-warning">Reset all votes</button>
        <button class="btn btn-warning">Delete unpopular ideas</button>
        <button class="btn btn-error">Delete all ideas</button>
      </div>
    </div>
    """
  end
end
