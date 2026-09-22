defmodule HappenWeb.Presence do
  def monitor(socket, room) do
    if Phoenix.LiveView.connected?(socket) do
      :ok = Group.monitor(:happen, room)
    end
  end

  def get_members(room) do
    Group.members(:happen, room)
  end

  def join(room, user) do
    :ok = Group.join(:happen, room, user)
  end

  def leave(room) do
    :ok = Group.leave(:happen, room)
  end

  def toggle(room, user) do
    leave(room)
    join(room, %{name: user.name, available?: !user.available?})
  end
end
