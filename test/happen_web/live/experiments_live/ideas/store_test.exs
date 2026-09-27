defmodule HappenWeb.ExperimentsLive.Ideas.StoreTest do
  use ExUnit.Case, async: false

  alias HappenWeb.ExperimentsLive.Ideas.Store

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
end
