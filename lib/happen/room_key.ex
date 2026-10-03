defmodule Happen.RoomKey do
  def decode(room_key) when is_binary(room_key) do
    with {:ok, room_name} <- Base.url_decode64(room_key, padding: false),
         true <- String.valid?(room_name) do
      {:ok, room_name}
    else
      _ -> :error
    end
  end

  def encode(room_name) when is_binary(room_name) do
    Base.url_encode64(room_name, padding: false)
  end
end
