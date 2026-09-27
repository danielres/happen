defmodule HappenWeb.ExperimentsLive.Stash.Counter do
  use HappenWeb, :html

  def init(socket) do
    socket
    |> LiveStash.recover_state()
    |> case do
      {:recovered, recovered_socket} ->
        recovered_socket

      {_a, socket} ->
        socket |> assign(counter: 0)
    end
  end

  def handle_event("dec", _, socket) do
    socket =
      socket
      |> assign(:counter, socket.assigns.counter - 1)
      |> LiveStash.stash()

    {:noreply, socket}
  end

  def handle_event("inc", _, socket) do
    socket =
      socket
      |> assign(:counter, socket.assigns.counter + 1)
      |> LiveStash.stash()

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-1">
      <div class="flex gap-2">
        <.button phx-click="counter:dec">dec</.button>
        <.button phx-click="counter:inc">inc</.button>
      </div>

      <div class="text-center bg-base-200 p-4 rounded">{@counter}</div>
    </div>
    """
  end
end
