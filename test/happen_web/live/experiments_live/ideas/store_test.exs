defmodule HappenWeb.RoomLive.Ideas.StoreTest do
  use ExUnit.Case, async: false

  alias HappenWeb.RoomLive.Ideas.Store

  test "toggles and switches one vote per user" do
    room_name = "ideas-#{System.unique_integer([:positive])}"
    user = %{id: Ash.UUID.generate(), name: "Test guest", hue: 40}
    idea = Store.add_idea(room_name, user, "An idea")
    upvote = %{direction: :up, user: user}
    downvote = %{direction: :down, user: user}

    assert {:ok, upvoted_idea} = Store.vote(room_name, idea.id, user, :up)
    assert upvoted_idea.votes == %{user.id => upvote}

    assert {:ok, unvoted_idea} = Store.vote(room_name, idea.id, user, :up)
    assert unvoted_idea.votes == %{}

    assert {:ok, downvoted_idea} = Store.vote(room_name, idea.id, user, :down)
    assert downvoted_idea.votes == %{user.id => downvote}

    assert {:ok, switched_idea} = Store.vote(room_name, idea.id, user, :up)
    assert switched_idea.votes == %{user.id => upvote}
  end

  test "resets every vote in one room" do
    first_room = "ideas-#{System.unique_integer([:positive])}"
    second_room = "ideas-#{System.unique_integer([:positive])}"
    user = %{id: Ash.UUID.generate(), name: "Test guest", hue: 40}

    first_idea = Store.add_idea(first_room, user, "First idea")
    second_idea = Store.add_idea(first_room, user, "Second idea")
    other_room_idea = Store.add_idea(second_room, user, "Other room idea")

    assert {:ok, _idea} = Store.vote(first_room, first_idea.id, user, :up)
    assert {:ok, _idea} = Store.vote(first_room, second_idea.id, user, :down)
    assert {:ok, other_room_idea} = Store.vote(second_room, other_room_idea.id, user, :up)

    :ok = Store.subscribe(first_room)
    assert :ok = Store.reset_all_votes(first_room, user)

    assert_receive {:ideas, {:votes_reset, ^user}}
    assert Enum.all?(Store.list_ideas(first_room), &(&1.votes == %{}))
    assert Store.list_ideas(second_room) == [other_room_idea]
  end
end
