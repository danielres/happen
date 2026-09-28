defmodule HappenWeb.ExperimentsLive.Ideas.Components.VotersList do
  use HappenWeb, :html

  alias HappenWeb.ExperimentsLive.Ideas.Utils
  alias HappenWeb.ExperimentsLive.User

  attr :direction, :atom, values: [:up, :down], required: true
  attr :idea, :map, required: true

  def render(assigns) do
    ~H"""
    <div
      :if={Utils.voters(@idea, @direction) |> length > 0}
      class="flex flex-wrap items-center gap-1"
    >
      <div class="flex items-center gap-1">
        <div class="small-caps opacity-75 tracking-wider text-sm">
          {if(@direction == :up, do: "Upvotes", else: "Downvotes")}:
        </div>
      </div>

      <ul class="flex flex-wrap gap-1 pl-2">
        <li :for={vote <- Utils.voters(@idea, @direction)}>
          <User.badge user={vote.user} />
        </li>
      </ul>
    </div>
    """
  end
end
