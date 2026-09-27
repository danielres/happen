defmodule HappenWeb.ExperimentsLive.Messages.StoreTest do
  use ExUnit.Case, async: false

  alias HappenWeb.ExperimentsLive.Messages.Store

  test "keeps messages and broadcasts isolated by room" do
    first_room = "first-room-#{System.unique_integer([:positive])}"
    second_room = "second-room-#{System.unique_integer([:positive])}"
    user = %{id: Ash.UUID.generate(), name: "Test guest", hue: 0}

    :ok = Store.subscribe(first_room)

    second_message = Store.add_message(second_room, user, "Second room")

    refute_receive {:messages, {:added, ^second_message}}
    assert Store.list_messages(first_room) == []
    assert Store.list_messages(second_room) == [second_message]

    first_message = Store.add_message(first_room, user, "First room")

    assert_receive {:messages, {:added, ^first_message}}
    assert Store.list_messages(first_room) == [first_message]
    assert Store.list_messages(second_room) == [second_message]
  end
end
