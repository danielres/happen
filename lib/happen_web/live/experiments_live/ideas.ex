defmodule HappenWeb.ExperimentsLive.Ideas do
  use HappenWeb, :live_view

  alias HappenWeb.ExperimentsLive.Ideas.Store
  alias HappenWeb.ExperimentsLive.User

  def on_mount(_params, _session, socket) do
    socket
    |> assign(
      ideas: %{
        form: nil,
        tools?: false
      }
    )
    |> assign_stream()
    |> subscribe()
  end

  defp subscribe(socket) do
    if connected?(socket), do: Store.subscribe(socket.assigns.room.data.name)
    socket
  end

  defp assign_stream(socket) do
    room_name = socket.assigns.room.data.name

    ideas =
      room_name
      |> Store.list_ideas()
      |> Enum.sort_by(
        fn idea ->
          {score(idea), DateTime.to_unix(idea.created_at, :microsecond)}
        end,
        :desc
      )

    stream(socket, :ideas, ideas, reset: true)
  end

  def handle_event("tools_toggle", _params, socket) do
    tools? = socket.assigns.ideas.tools?
    socket = socket |> update(:ideas, &Map.put(&1, :tools?, !tools?))
    {:noreply, socket}
  end

  def handle_event("add_start", _params, socket) do
    socket = socket |> assign_form()
    {:noreply, socket}
  end

  def handle_event("add_cancel", _params, socket) do
    socket = socket |> update(:ideas, &Map.put(&1, :form, nil))
    {:noreply, socket}
  end

  def handle_event("add", %{"body" => body}, socket) do
    room_name = socket.assigns.room.data.name
    user = socket.assigns.user.data

    Store.add_idea(room_name, user, body)

    {:noreply, socket |> assign_form()}
  end

  def handle_event("change", %{"body" => body}, socket) do
    {:noreply, socket |> assign_form(body)}
  end

  def handle_event("vote_up", params, socket) do
    vote(params, socket, :up)
  end

  def handle_event("vote_down", params, socket) do
    vote(params, socket, :down)
  end

  def handle_info({event, _idea}, socket) when event in [:added, :updated] do
    {:noreply, assign_stream(socket)}
  end

  defp assign_form(socket, body \\ "") do
    form = %{"body" => body}
    socket |> update(:ideas, &Map.put(&1, :form, to_form(form)))
  end

  defp vote(%{"idea-id" => idea_id}, socket, direction) do
    room_name = socket.assigns.room.data.name
    user = socket.assigns.user.data

    with {idea_id, ""} <- Integer.parse(idea_id),
         {:ok, _idea} <- Store.vote(room_name, idea_id, user, direction) do
      {:noreply, socket}
    else
      _error -> {:noreply, socket}
    end
  end

  def button_add(assigns) do
    ~H"""
    <button
      data-testid="ideas-add"
      class="btn btn-sm btn-info btn-circle"
      phx-click="ideas:add_start"
      type="button"
    >
      <.icon name="hero-plus-micro" />
    </button>
    """
  end

  attr :active?, :boolean, required: true

  def button_tools(assigns) do
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

  def render_tools(assigns) do
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

  attr :stream, :list, required: true
  attr :user_id, :string, required: true

  def render_list(assigns) do
    ~H"""
    <ul
      id="ideas"
      data-testid="ideas-list"
      phx-hook="AutoAnimate"
      phx-update="stream"
      class="space-y-2"
    >
      <li
        :for={{id, idea} <- @stream}
        id={id}
        data-testid={"idea-#{idea.id}"}
        class={[
          "rounded-box",
          "bg-base-200/50",
          "border-2 border-base-300",
          "hover:border-base-content/25 transition",
          "grid grid-cols-[1fr_auto]"
        ]}
      >
        <% has_votes_up? = voters(idea, :up) |> length() > 0 %>
        <% has_votes_down? = voters(idea, :down) |> length() > 0 %>
        <% has_votes? = has_votes_up? || has_votes_down? %>

        <label class={[
          has_votes? && "cursor-pointer",
          "block",
          "text text-base-content/75",
          "relative",
          "group"
        ]}>
          <input :if={has_votes?} type="checkbox" class="peer sr-only" />

          <div class={[
            "peer-checked:hidden",
            "h-full",
            "px-4 py-3"
          ]}>
            <div class="text-sm">{idea.body}</div>
          </div>

          <div
            data-testid={"idea-voters-#{idea.id}"}
            class={[
              "hidden peer-checked:block"
            ]}
          >
            <div class="p-4">
              <.render_voters direction={:up} idea={idea} />

              <div
                :if={voters(idea, :up) |> length() > 0 && voters(idea, :down) |> length() > 0}
                class="h-0 border-b my-4 border-base-300"
              >
              </div>
              <.render_voters direction={:down} idea={idea} />
            </div>
          </div>

          <div :if={has_votes?} class="absolute right-1 bottom-0">
            <.icon
              name="hero-ellipsis-horizontal-micro"
              class={[
                "opacity-20 transition",
                "group-hover:opacity-100"
              ]}
            />
          </div>
        </label>

        <.render_voting_buttons idea={idea} user_id={@user_id} />
      </li>
    </ul>
    """
  end

  def render_form(assigns) do
    ~H"""
    <.form
      for={@form}
      id="idea-body-form"
      phx-change="ideas:change"
      phx-submit="ideas:add"
      phx-click-away="ideas:add_cancel"
      phx-window-keydown="ideas:add_cancel"
      phx-key="Escape"
      class="mb-2"
    >
      <label class="input input-info pr-0 w-full">
        <input
          type="text"
          autocomplete="off"
          name={@form[:body].name}
          value={Phoenix.HTML.Form.normalize_value("text", @form[:body].value)}
          placeholder="Suggest an idea"
          required
          class="grow"
          phx-mounted={JS.focus()}
        />
        <button class="btn btn-square btn-info btn-soft h-full">
          <.icon name="hero-check-micro" />
        </button>
      </label>
    </.form>
    """
  end

  attr :idea, :map, required: true

  defp render_voting_buttons(assigns) do
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
        aria-pressed={to_string(voted?(@idea, @user_id, :up))}
        class={[
          "hover:btn-info",
          voted?(@idea, @user_id, :up) && "btn-info"
        ]}
        phx-click="ideas:vote_up"
        phx-value-idea-id={@idea.id}
      >
        <span class="count">{vote_count(@idea, :up)}</span>
        <.icon name="hero-chevron-up-micro" />
      </button>

      <button
        type="button"
        data-testid={"idea-downvote-#{@idea.id}"}
        aria-label="Vote down"
        aria-pressed={to_string(voted?(@idea, @user_id, :down))}
        class={[
          "self-end",
          "hover:btn-warning",
          voted?(@idea, @user_id, :down) && "btn-warning"
        ]}
        phx-click="ideas:vote_down"
        phx-value-idea-id={@idea.id}
      >
        <span class="count">{vote_count(@idea, :down)}</span>
        <.icon name="hero-chevron-down-micro" />
      </button>
    </div>
    """
  end

  attr :direction, :atom, values: [:up, :down], required: true

  defp render_voters(assigns) do
    ~H"""
    <div
      :if={voters(@idea, @direction) |> length > 0}
      class="space-y-1"
    >
      <div class="flex items-center gap-1">
        <div class={[
          "size-5 flex items-center justify-center"
        ]}>
          <.icon :if={@direction == :up} name="hero-chevron-up-micro" />
          <.icon :if={@direction == :down} name="hero-chevron-down-micro" />
        </div>

        <div class="small-caps opacity-75 tracking-wider text-sm">
          {if(@direction == :up, do: "Upvotes", else: "Downvotes")}
        </div>
      </div>

      <ul class="flex flex-wrap gap-1">
        <li :for={vote <- voters(@idea, @direction)}>
          <User.badge user={vote.user} />
        </li>
      </ul>
    </div>
    """
  end

  defp score(idea) do
    vote_count(idea, :up) - vote_count(idea, :down)
  end

  defp vote_count(idea, direction) do
    idea
    |> Map.get(:votes, %{})
    |> Enum.count(fn {_user_id, vote} -> vote.direction == direction end)
  end

  defp voted?(idea, user_id, direction) do
    case idea |> Map.get(:votes, %{}) |> Map.get(user_id) do
      %{direction: ^direction} -> true
      _other -> false
    end
  end

  defp voters(idea, direction) do
    idea
    |> Map.get(:votes, %{})
    |> Map.values()
    |> Enum.filter(&(&1.direction == direction))
    |> Enum.sort_by(&String.downcase(&1.user.name))
  end
end
