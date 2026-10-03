defmodule Happen.RoomKey do
  def encode(room_name) when is_binary(room_name) do
    Base.url_encode64(room_name, padding: false)
  end
end
