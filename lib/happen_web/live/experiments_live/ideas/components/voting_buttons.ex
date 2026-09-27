defmodule HappenWeb.ExperimentsLive.Ideas.Components.VotingButtons do
  use HappenWeb, :html

  alias HappenWeb.ExperimentsLive.Ideas.Utils

  attr :idea, :map, required: true

  def render(assigns) do
    ~H"""
    <div class={[
      "grid",
      "bg-base-200",
      "rounded-r-box",
      "[&_button]:btn",
      "[&_button]:btn-ghost",
      "[&_button]:btn-sm",
      "[&_button]:opacity-70",
      "[&_button]:hover:opacity-100",
      "[&_button]:pr-1",
      "[&_button]:pl-0",
      "[&_button]:flex",
      "[&_button]:gap-1",
      "[&_button]:justify-end",
      "[&_.count]:opacity-75",
      "[&_.count]:text-xs",
      "[&_.count]:text-right",
      "[&_.count]:min-w-[3ch]"
    ]}>
      <button
        type="button"
        data-testid={"idea-upvote-#{@idea.id}"}
        aria-label="Vote up"
        aria-pressed={to_string(Utils.voted?(@idea, @user_id, :up))}
        class={[
          "hover:btn-info",
          Utils.voted?(@idea, @user_id, :up) && "btn-info"
        ]}
        phx-click="ideas:vote_up"
        phx-value-idea-id={@idea.id}
      >
        <span class="count">{Utils.vote_count(@idea, :up)}</span>
        <.icon name="hero-chevron-up-micro" />
      </button>

      <button
        type="button"
        data-testid={"idea-downvote-#{@idea.id}"}
        aria-label="Vote down"
        aria-pressed={to_string(Utils.voted?(@idea, @user_id, :down))}
        class={[
          "self-end",
          "hover:btn-warning",
          Utils.voted?(@idea, @user_id, :down) && "btn-warning"
        ]}
        phx-click="ideas:vote_down"
        phx-value-idea-id={@idea.id}
      >
        <span class="count">{Utils.vote_count(@idea, :down)}</span>
        <.icon name="hero-chevron-down-micro" />
      </button>
    </div>
    """
  end
end
