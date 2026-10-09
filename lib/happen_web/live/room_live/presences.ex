defmodule HappenWeb.RoomLive.Presences do
  use HappenWeb, :live_view
  use LiveDelegate, path: [:presences]

  def on_mount(_params, _session, socket) do
    socket
    |> delegate_assign([])
    |> monitor()
    |> join()
  end

  def leave_event, do: delegate_event("leave")

  def handle_event("leave", _payload, socket) do
    room = socket.assigns.room
    user = socket.assigns.user.data
    _result = Happen.Push.leave_room(user.id, room.data.name)
    :ok = Group.leave(:happen, room.data.name)
    {:noreply, redirect(socket, to: ~p"/guest/logout")}
  end

  def handle_info({_events, _info}, socket) do
    room = socket.assigns.room
    {:noreply, socket |> delegate_assign(get_presences(room))}
  end

  defp join(socket) do
    if connected?(socket) && socket.assigns.user.data do
      room_name = socket.assigns.room.data.name
      user = socket.assigns.user.data
      presences = Group.members(:happen, room_name)
      user = %{user | hue: pick_hue(presences, user.id)}

      :ok = Group.join(:happen, room_name, user)

      update(socket, :user, fn user_assign ->
        %{user_assign | data: user}
      end)
    else
      socket
    end
  end

  defp monitor(socket) do
    if connected?(socket) do
      :ok = Group.monitor(:happen, socket.assigns.room.data.name)
    end

    socket
  end

  defp get_presences(room) do
    Group.members(:happen, room.data.name)
    |> Enum.uniq_by(fn {_pid, member} -> member.id end)
    |> Enum.sort_by(fn {_pid, member} -> member.since end, DateTime)
  end

  defp pick_hue(presences, user_id) do
    case Enum.find(presences, fn {_pid, presence} -> presence.id == user_id end) do
      {_pid, presence} -> presence.hue
      nil -> pick_unused_hue(presences)
    end
  end

  defp pick_unused_hue([]), do: 40

  defp pick_unused_hue(presences) do
    hues =
      presences
      |> Enum.map(fn {_pid, presence} -> Integer.mod(presence.hue, 360) end)
      |> Enum.uniq()
      |> Enum.sort()

    first_hue = hd(hues)

    {left_hue, right_hue} =
      hues
      |> Enum.zip(tl(hues) ++ [first_hue + 360])
      |> Enum.max_by(fn {left_hue, right_hue} -> right_hue - left_hue end)

    Integer.mod(div(left_hue + right_hue, 2), 360)
  end

  def render(assigns) do
    ~H"""
    <ul class="flex gap-2">
      <li :for={{_pid, presence} <- @presences}>
        <HappenWeb.RoomLive.User.badge user={presence} />
      </li>
    </ul>
    """
  end
end
