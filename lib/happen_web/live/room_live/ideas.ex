defmodule HappenWeb.RoomLive.Ideas do
  use HappenWeb, :live_view
  use LiveDelegate, path: [:ideas]

  alias HappenWeb.RoomLive.Ideas.Tools
  alias HappenWeb.RoomLive.Ideas.Components
  alias HappenWeb.RoomLive.Ideas.Store
  alias HappenWeb.RoomLive.Ideas.Utils

  delegate(:tools, Tools)

  def on_mount(params, session, socket) do
    socket
    |> delegate_assign(%{data: [], form: nil, active: nil})
    |> assign_form("")
    |> delegate_mount(params, session)
    |> assign_ideas()
    |> subscribe()
  end

  defp subscribe(socket) do
    if connected?(socket), do: Store.subscribe(socket.assigns.room.data.name)
    socket
  end

  defp assign_ideas(socket) do
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

    socket |> delegate_assign(:data, ideas)
  end

  def handle_event("add", %{"body" => body}, socket) do
    room_name = socket.assigns.room.data.name
    user = socket.assigns.user.data

    Store.add_idea(room_name, user, body)

    {:noreply, socket |> assign_form()}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    room_name = socket.assigns.room.data.name

    with {idea_id, ""} <- Integer.parse(id),
         {:ok, _idea} <- Store.delete_idea(room_name, idea_id) do
      {:noreply, socket}
    else
      _invalid_idea -> {:noreply, socket}
    end
  end

  def handle_event("add_cancel", _params, socket) do
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

  def handle_event("toggle_active", params, socket) do
    {id, _} = params["id"] |> Integer.parse()
    active = if id == socket.assigns.ideas.active, do: nil, else: id
    {:noreply, socket |> delegate_assign(:active, active)}
  end

  def handle_event("clear_active", _params, socket) do
    if socket.assigns.ideas.active do
      {:noreply, socket |> delegate_assign(:active, nil)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:votes_reset, user}, socket) do
    socket =
      socket
      |> assign_ideas()
      |> Toast.put_toast(:info, "Votes have been reset by #{user.name}")

    {:noreply, socket}
  end

  def handle_info({event, _idea}, socket) when event in [:added, :deleted, :updated] do
    {:noreply, assign_ideas(socket)}
  end

  defp assign_form(socket, body \\ "") do
    form = %{"body" => body}
    socket |> delegate_assign(:form, to_form(form))
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

  def button_tools(assigns), do: Tools.button(assigns)
  def render_tools(assigns), do: Tools.render(assigns)
  def render_form(assigns), do: Components.Form.render(assigns)

  attr :ideas, :list, required: true
  attr :user_id, :string, required: true

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <ul
      id="ideas"
      data-testid="ideas-list"
      phx-hook="AutoAnimate"
      class="space-y-2"
      phx-click-away={delegate_event("clear_active")}
    >
      <li
        :for={idea <- @ideas.data}
        id={"idea-#{idea.id}"}
        data-testid={"idea-#{idea.id}"}
        class="flex gap-2"
      >
        <div class={[
          "grow",
          "stacked",
          "group"
        ]}>
          <button
            phx-click={delegate_event("toggle_active")}
            phx-value-id={idea.id}
            class={[
              "w-full",
              "text-left",
              "cursor-pointer",
              "grid grid-cols-[1fr_auto]",
              "rounded-box",
              "border-2",
              idea.id != @ideas.active && "bg-base-300/40 group-hover:bg-base-300/60 transition",
              idea.id != @ideas.active && "border-transparent",
              idea.id == @ideas.active && "bg-base-300/60",
              idea.id == @ideas.active && "border-black"
            ]}
          >
            <Components.Idea.render idea={idea} active?={idea.id == @ideas.active} />
          </button>

          <div
            :if={idea.id == @ideas.active && "border-black"}
            class="self-start justify-self-end"
          >
            <button
              class={[
                "btn btn-xs btn-ghost hover:btn-error btn-square",
                "opacity-30 hover:opacity-100 transition",
                "m-2"
              ]}
              phx-click={delegate_event("delete")}
              phx-value-id={idea.id}
              data-confirm="Delete this idea permanently?"
              data-testid={"idea-delete-#{idea.id}"}
              type="button"
            >
              <.icon name="hero-trash-micro" />
            </button>
          </div>
        </div>

        <div class={[
          "rounded-box",
          "h-fit",
          "bg-base-300/80",
          "grid grid-cols-[1fr_auto]"
        ]}>
          <Components.VotingButtons.render idea={idea} user_id={@user_id} />
        </div>
      </li>
    </ul>
    """
  end
end
