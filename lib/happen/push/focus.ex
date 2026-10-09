defmodule Happen.Push.Focus do
  def set(room_name, guest_id, true) do
    Group.join(:happen, group(room_name), %{guest_id: guest_id})
  end

  def set(room_name, _guest_id, false) do
    case Group.leave(:happen, group(room_name)) do
      :ok -> :ok
      {:error, :not_in_group} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def focused_guest_ids(room_name) do
    :happen
    |> Group.members(group(room_name))
    |> Enum.map(fn {_pid, %{guest_id: guest_id}} -> guest_id end)
    |> MapSet.new()
  end

  defp group(room_name), do: "push-focus:#{room_name}"
end
