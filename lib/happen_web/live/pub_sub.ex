defmodule Happen.PS do
  alias Phoenix.PubSub

  def subscribe(socket) do
    if Phoenix.LiveView.connected?(socket) do
      PubSub.subscribe(Happen.PubSub, "room")
    end
  end

  def broadcast(msg) do
    PubSub.broadcast(Happen.PubSub, "room", msg)
  end
end
