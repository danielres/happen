defmodule HappenWeb.RoomLive.Ideas.Utils do
  def score(idea) do
    vote_count(idea, :up) - vote_count(idea, :down)
  end

  def voters(idea, direction) do
    idea
    |> Map.get(:votes, %{})
    |> Map.values()
    |> Enum.filter(&(&1.direction == direction))
    |> Enum.sort_by(&String.downcase(&1.user.name))
  end

  def voted?(idea, user_id, direction) do
    case idea |> Map.get(:votes, %{}) |> Map.get(user_id) do
      %{direction: ^direction} -> true
      _other -> false
    end
  end

  def has_votes?(ideas) when is_list(ideas) do
    Enum.any?(ideas, &has_votes?/1)
  end

  def has_votes?(idea) when is_map(idea) do
    has_votes_up?(idea) || has_votes_down?(idea)
  end

  def has_unpopular_ideas?(ideas) when is_list(ideas) do
    Enum.any?(ideas, &(score(&1) < 0))
  end

  defp has_votes_up?(idea) do
    vote_count(idea, :up) > 0
  end

  defp has_votes_down?(idea) do
    vote_count(idea, :down) > 0
  end

  def has_votes_up_and_down?(idea) do
    vote_count(idea, :up) > 0 && vote_count(idea, :down) > 0
  end

  def vote_count(idea, direction) do
    idea
    |> Map.get(:votes, %{})
    |> Enum.count(fn {_user_id, vote} -> vote.direction == direction end)
  end
end
