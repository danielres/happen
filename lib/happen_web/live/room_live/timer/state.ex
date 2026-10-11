defmodule HappenWeb.RoomLive.Timer.State do
  use HappenWeb, :live_view
  use LiveDelegate, path: [:timer]

  # def init(socket, deadline) do
  #   socket |> schedule_tick() |> set_deadline(deadline)
  # end
  def default_deadline(), do: DateTime.now!("Etc/UTC") |> DateTime.add(15, :minute)

  def set_deadline(socket, deadline) do
    remaining_ms = deadline |> DateTime.diff(DateTime.now!("Etc/UTC"), :millisecond)
    remaining_min = ms_to_rounded_up_min(remaining_ms)

    socket
    |> delegate_assign(:deadline, deadline)
    |> delegate_assign(:remaining_min, remaining_min)
  end

  def schedule_tick(socket) do
    if connected?(socket) do
      Process.send_after(self(), {:timer, :tick}, :timer.seconds(1))
    end

    socket
  end

  def tick(socket) do
    deadline = socket.assigns.timer.deadline

    socket
    |> set_deadline(deadline)
    |> schedule_tick()
  end

  defp ms_to_rounded_up_min(ms) do
    non_neg_ms = max(ms, 0)
    ceil(non_neg_ms / :timer.minutes(1))
  end
end
