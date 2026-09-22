defmodule Happen.PS do
  alias Phoenix.PubSub

  def messages_subscribe(socket, room) do
    if Phoenix.LiveView.connected?(socket) do
      PubSub.subscribe(Happen.PubSub, "messages:#{room.id}")
    end
  end

  def message_broadcast(room, msg) do
    PubSub.broadcast(Happen.PubSub, "messages:#{room.id}", %{message: msg})
  end
end
