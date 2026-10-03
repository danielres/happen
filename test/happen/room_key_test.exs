defmodule Happen.RoomKeyTest do
  use ExUnit.Case, async: true

  alias Happen.RoomKey

  test "encodes and decodes a room name" do
    room_name = "Café room"

    assert {:ok, ^room_name} = room_name |> RoomKey.encode() |> RoomKey.decode()
  end

  test "rejects malformed room keys" do
    assert :error = RoomKey.decode("invalid!")
  end
end
