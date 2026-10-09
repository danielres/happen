defmodule HappenWeb.RoomLive.Messages.Store do
  use GenServer

  def max_count, do: 15
  def ttl, do: 180

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  def list_messages(room_name) do
    GenServer.call(__MODULE__, {:list_messages, room_name})
  end

  def add_message(room_name, user, body) do
    GenServer.call(__MODULE__, {:add_message, room_name, user, body})
  end

  def subscribe(room_name) do
    Phoenix.PubSub.subscribe(Happen.PubSub, topic(room_name))
  end

  @impl true
  def handle_call({:list_messages, room_name}, _from, rooms) do
    {:reply, Map.get(rooms, room_name, []), rooms}
  end

  @impl true
  def handle_call({:add_message, room_name, user, body}, _from, rooms) do
    message = %{
      id: System.unique_integer([:positive, :monotonic]),
      created_at: DateTime.now!("Etc/UTC"),
      user: user,
      body: body
    }

    Process.send_after(
      self(),
      {:delete_message, room_name, message.id},
      :timer.seconds(ttl())
    )

    messages =
      rooms
      |> Map.get(room_name, [])
      |> Kernel.++([message])
      |> Enum.take(-max_count())

    rooms = Map.put(rooms, room_name, messages)

    broadcast(room_name, {:added, message})
    Happen.Push.Notifications.message_added(room_name, user, body)

    {:reply, message, rooms}
  end

  @impl true
  def handle_info({:delete_message, room_name, message_id}, rooms) do
    messages =
      rooms
      |> Map.get(room_name, [])
      |> Enum.reject(fn message ->
        message.id == message_id
      end)

    rooms =
      if messages == [] do
        Map.delete(rooms, room_name)
      else
        Map.put(rooms, room_name, messages)
      end

    broadcast(room_name, {:deleted, message_id})

    {:noreply, rooms}
  end

  defp broadcast(room_name, event) do
    Phoenix.PubSub.broadcast(
      Happen.PubSub,
      topic(room_name),
      {:messages, event}
    )
  end

  defp topic(room_name), do: "messages:#{room_name}"
end
