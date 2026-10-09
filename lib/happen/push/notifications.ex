defmodule Happen.Push.Notifications do
  alias Happen.Push

  def message_added(room_name, author, body) do
    dispatch(room_name, author, :message, body)
  end

  def idea_added(room_name, author, body) do
    dispatch(room_name, author, :idea, body)
  end

  defp dispatch(room_name, author, kind, body) do
    if Push.configured?() do
      Task.Supervisor.start_child(Happen.Push.TaskSupervisor, fn ->
        delivery().deliver(room_name, author, kind, body)
      end)
    else
      :disabled
    end
  end

  defp delivery do
    Application.get_env(:happen, __MODULE__, [])
    |> Keyword.get(:delivery, Happen.Push.Delivery)
  end
end
