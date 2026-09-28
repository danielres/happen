defmodule HappenWeb.ExperimentsLive.Ideas do
  use HappenWeb, :live_view

  alias HappenWeb.ExperimentsLive.Ideas.Components
  alias HappenWeb.ExperimentsLive.Ideas.Store
  alias HappenWeb.ExperimentsLive.Ideas.Utils
  alias HappenWeb.ExperimentsLive.User

  def on_mount(_params, _session, socket) do
    socket
    |> assign(
      ideas: %{
        form: nil,
        # tools: nil,
        tools: :start
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
          {Utils.score(idea), DateTime.to_unix(idea.created_at, :microsecond)}
        end,
        :desc
      )

    stream(socket, :ideas, ideas, reset: true)
  end

  def handle_event("tools_toggle", _params, socket) do
    tools_active? = socket.assigns.ideas.tools != nil
    tools = if tools_active?, do: nil, else: :start
    socket = socket |> update(:ideas, &Map.put(&1, :tools, tools))
    {:noreply, socket}
  end

  def handle_event("tools_reset_all_votes_start", _params, socket) do
    socket = socket |> update(:ideas, &Map.put(&1, :tools, :reset_all_votes))
    {:noreply, socket}
  end

  def handle_event("tools_remove_unpopular_ideas_start", _params, socket) do
    socket = socket |> update(:ideas, &Map.put(&1, :tools, :remove_unpopular_ideas))
    {:noreply, socket}
  end

  def handle_event("tools_remove_all_ideas_start", _params, socket) do
    socket = socket |> update(:ideas, &Map.put(&1, :tools, :remove_all_ideas))
    {:noreply, socket}
  end

  def handle_event("add_start", _params, socket) do
    socket = socket |> assign_form()
    socket = socket |> update(:ideas, &Map.put(&1, :tools, nil))
    {:noreply, socket}
  end

  def handle_event("add", %{"body" => body}, socket) do
    room_name = socket.assigns.room.data.name
    user = socket.assigns.user.data

    Store.add_idea(room_name, user, body)

    {:noreply, socket |> assign_form()}
  end

  def handle_event("add_cancel", _params, socket) do
    socket = socket |> update(:ideas, &Map.put(&1, :form, nil))
    {:noreply, socket}
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

  def button_tools(assigns), do: Components.Tools.button(assigns)
  def render_tools(assigns), do: Components.Tools.render(assigns)
  def render_form(assigns), do: Components.Form.render(assigns)

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

  attr :stream, :list, required: true
  attr :user_id, :string, required: true

  def render(assigns) do
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
        <Components.Idea.render idea={idea} />
        <Components.VotingButtons.render idea={idea} user_id={@user_id} />
      </li>
    </ul>
    """
  end
end
