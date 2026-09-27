defmodule HappenWeb.Presence do
  use HappenWeb, :live_view

  def init(socket, room, user) do
    socket
    |> assign(presences: [])
    |> monitor(room)
    |> join(room, user)
  end

  def handle_event("leave", %{"room" => room}, socket) do
    leave(room)
    {:noreply, redirect(socket, to: ~p"/guest/logout")}
  end

  def handle_info(msg, socket) do
    {:noreply, socket}
  end

  def sync(socket, room) do
    presences = get_presences(room)
    socket |> assign(presences: presences)
  end

  defp join(socket, room, user) do
    if connected?(socket) do
      if user, do: join(room, user)
    end

    socket
  end

  defp monitor(socket, room) do
    if connected?(socket) do
      :ok = Group.monitor(:happen, room)
    end

    socket
  end

  def get_members(room) do
    Group.members(:happen, room)
    |> Enum.uniq_by(fn {_pid, member} -> member.id end)
  end

  defp get_presences(room) do
    Group.members(:happen, room)
    |> Enum.uniq_by(fn {_pid, member} -> member.id end)
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
