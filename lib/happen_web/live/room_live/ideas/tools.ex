defmodule HappenWeb.RoomLive.Ideas.Tools do
  use HappenWeb, :html
  use LiveDelegate, path: [:ideas, :tools]

  alias HappenWeb.RoomLive.Ideas.Store
  alias HappenWeb.RoomLive.Ideas.Utils

  def on_mount(_params, _session, socket) do
    socket |> delegate_assign(nil)
  end

  def handle_event("start", _params, socket) do
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

  def handle_event("reset_all_votes", _params, socket) do
    room_name = socket.assigns.room.data.name
    user = socket.assigns.user.data

    :ok = Store.reset_all_votes(room_name, user)
    {:noreply, socket |> delegate_assign(nil)}
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
      phx-click={if(@active?, do: delegate_event("close"), else: delegate_event("start"))}
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
      class={[
        "border-4 rounded-box p-2",
        @tools != :remove_all_ideas && "border-warning/30 bg-warning/3",
        @tools == :remove_all_ideas && "border-error/30 bg-error/10",
        "transition"
      ]}
      phx-click-away={delegate_event("close")}
      phx-key="Escape"
      phx-window-keydown={delegate_event((@tools == :start && "close") || "start")}
    >
      <div class="overflow-hidden">
        <div
          data-testid={delegate_dom_id("track")}
          class={[
            "flex items-center",
            "transition-transform duration-200 ease-out",
            "motion-reduce:transition-none",
            @tools == :start && "translate-x-0",
            @tools != :start && "-translate-x-full"
          ]}
        >
          <div
            class="grid w-full shrink-0 gap-2"
            inert={@tools != :start}
          >
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
              data-testid={delegate_dom_id("remove-all-ideas")}
              disabled={Enum.empty?(@ideas)}
              phx-click={delegate_event("remove_all_ideas_start")}
              type="button"
            >
              Remove all ideas <.icon name="hero-chevron-right-micro" />
            </button>
          </div>

          <div
            class={[
              "w-full shrink-0",
              "flex justify-center text-center",
              "font-bold",
              "text-balance",
              "text-sm",
              "leading-tight",
              "*:space-y-3"
            ]}
            inert={@tools == :start}
          >
            <div
              :if={@tools == :reset_all_votes}
              class="text-warning"
            >
              <p>Are you sure?</p>
              <button
                data-testid={delegate_dom_id("reset-all-votes-confirm")}
                class="btn btn-warning"
                type="button"
                phx-click={delegate_event("reset_all_votes")}
              >
                Reset all votes
              </button>
            </div>

            <div
              :if={@tools == :remove_unpopular_ideas}
              class="text-warning"
            >
              <p>Remove ideas with more downvotes than upvotes?</p>
              <button class="btn btn-warning" type="button">
                Remove unpopular ideas
              </button>
            </div>

            <div
              :if={@tools == :remove_all_ideas}
              class="text-error"
            >
              <p>Are you sure?</p>
              <button class="btn btn-error" type="button">
                Remove all ideas
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
