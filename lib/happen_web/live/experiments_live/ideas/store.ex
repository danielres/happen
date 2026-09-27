defmodule HappenWeb.ExperimentsLive.Ideas.Store do
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  def list_ideas(room_name) do
    GenServer.call(__MODULE__, {:list_ideas, room_name})
  end

  def add_idea(room_name, user, body) do
    GenServer.call(__MODULE__, {:add_idea, room_name, user, body})
  end

  def vote(room_name, idea_id, user, direction) when is_map(user) and direction in [:up, :down] do
    GenServer.call(__MODULE__, {:vote, room_name, idea_id, user, direction})
  end

  def subscribe(room_name) do
    Phoenix.PubSub.subscribe(Happen.PubSub, topic(room_name))
  end

  @impl true
  def handle_call({:list_ideas, room_name}, _from, rooms) do
    {:reply, Map.get(rooms, room_name, []), rooms}
  end

  @impl true
  def handle_call({:add_idea, room_name, user, body}, _from, rooms) do
    idea = %{
      id: System.unique_integer([:positive, :monotonic]),
      created_at: DateTime.now!("Etc/UTC"),
      user: user,
      body: body,
      votes: %{}
    }

    ideas =
      rooms
      |> Map.get(room_name, [])
      |> Kernel.++([idea])

    rooms = Map.put(rooms, room_name, ideas)

    broadcast(room_name, {:added, idea})

    {:reply, idea, rooms}
  end

  @impl true
  def handle_call({:vote, room_name, idea_id, user, direction}, _from, rooms) do
    ideas = Map.get(rooms, room_name, [])

    case Enum.find_index(ideas, &(&1.id == idea_id)) do
      nil ->
        {:reply, {:error, :not_found}, rooms}

      index ->
        idea = Enum.at(ideas, index)
        votes = toggle_vote(Map.get(idea, :votes, %{}), user, direction)
        idea = Map.put(idea, :votes, votes)
        rooms = Map.put(rooms, room_name, List.replace_at(ideas, index, idea))

        broadcast(room_name, {:updated, idea})

        {:reply, {:ok, idea}, rooms}
    end
  end

  @impl true
  def handle_info({:delete_idea, room_name, idea_id}, rooms) do
    ideas =
      rooms
      |> Map.get(room_name, [])
      |> Enum.reject(fn idea ->
        idea.id == idea_id
      end)

    rooms =
      if ideas == [] do
        Map.delete(rooms, room_name)
      else
        Map.put(rooms, room_name, ideas)
      end

    broadcast(room_name, {:deleted_idea, idea_id})

    {:noreply, rooms}
  end

  defp broadcast(room_name, event) do
    Phoenix.PubSub.broadcast(
      Happen.PubSub,
      topic(room_name),
      {:ideas, event}
    )
  end

  defp toggle_vote(votes, user, direction) do
    case Map.get(votes, user.id) do
      %{direction: ^direction} ->
        Map.delete(votes, user.id)

      _other ->
        Map.put(votes, user.id, %{direction: direction, user: user})
    end
  end

  defp topic(room_name), do: "ideas:#{room_name}"
end
