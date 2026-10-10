defmodule HappenWeb.RoomLive.Ideas.Components.Idea do
  use HappenWeb, :html

  alias HappenWeb.RoomLive.Ideas.Utils
  alias HappenWeb.RoomLive.User

  attr :idea, :map, required: true
  attr :active?, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div
      class="text text-base-content/75"
      phx-hook="AutoAnimate"
      id={"idea-#{@idea.id}-card"}
    >
      <div
        :if={!@active?}
        class="px-4 py-3 text-sm"
        id={"idea-#{@idea.id}-body"}
      >
        {@idea.body}
      </div>

      <div
        :if={@active?}
        data-testid={"idea-voters-#{@idea.id}"}
        id={"idea-#{@idea.id}-details"}
      >
        <% class_title = "small-caps tracking-wider text-sm min-w-[8ch]" %>
        <% class_subgrid = "grid grid-cols-subgrid col-span-2 items-baseline" %>
        <% class_border = "border-t border-base-content/10 pt-4 mt-4" %>

        <div class="p-4 grid grid-cols-[auto_1fr] gap-x-4">
          <dl class={class_subgrid}>
            <dt class={class_title}>By:</dt>
            <dd><User.badge user={@idea.user} /></dd>
          </dl>

          <dl
            :if={Utils.voters(@idea, :up) |> length > 0}
            class={[class_subgrid, class_border]}
          >
            <dt class={class_title}>Upvotes:</dt>
            <dd class="flex flex-wrap gap-1">
              <span :for={vote <- Utils.voters(@idea, :up)}>
                <User.badge user={vote.user} />
              </span>
            </dd>
          </dl>
          <dl
            :if={Utils.voters(@idea, :down) |> length > 0}
            class={[class_subgrid, class_border]}
          >
            <dt class={class_title}>Downvotes:</dt>
            <dd class="flex flex-wrap gap-1">
              <span :for={vote <- Utils.voters(@idea, :down)}>
                <User.badge user={vote.user} />
              </span>
            </dd>
          </dl>
        </div>
      </div>
    </div>
    """
  end
end
