defmodule Happen.Push.Delivery do
  require Logger

  alias Happen.Push
  alias Happen.Push.Focus
  alias Happen.RoomKey

  def deliver(room_name, author, kind, body) do
    with {:ok, subscriptions} <- Push.subscriptions_for_room(room_name) do
      focused_guest_ids = Focus.focused_guest_ids(room_name)

      subscriptions
      |> Enum.reject(&excluded?(&1, author.id, focused_guest_ids))
      |> Enum.each(&deliver_to(&1, payload(room_name, author, kind, body)))
    end
  end

  defp deliver_to(subscription, payload) do
    case sender().send(subscription, payload) do
      :ok ->
        :ok

      :expired ->
        Ash.destroy(subscription, domain: Push)
        :ok

      {:error, reason} ->
        Logger.warning("Web Push delivery failed: #{inspect(reason)}")
        :error
    end
  rescue
    error ->
      Logger.warning("Web Push delivery crashed: #{Exception.message(error)}")
      :error
  end

  defp excluded?(subscription, author_id, focused_guest_ids) do
    subscription.guest_id == author_id or
      MapSet.member?(focused_guest_ids, subscription.guest_id) or
      disabled_invitation?(subscription)
  end

  defp disabled_invitation?(%{invitation_id: nil}), do: false
  defp disabled_invitation?(%{invitation: %{disabled_at: nil}}), do: false
  defp disabled_invitation?(_subscription), do: true

  defp payload(room_name, author, :message, body) do
    %{
      body: "#{author.name}: #{body}",
      tag: "happen-room-#{RoomKey.encode(room_name)}",
      title: room_name,
      url: HappenWeb.Endpoint.url() <> "/" <> RoomKey.encode(room_name)
    }
  end

  defp payload(room_name, author, :idea, body) do
    %{
      body: "#{author.name} added an idea: #{body}",
      tag: "happen-room-#{RoomKey.encode(room_name)}",
      title: room_name,
      url: HappenWeb.Endpoint.url() <> "/" <> RoomKey.encode(room_name)
    }
  end

  defp sender do
    Application.get_env(:happen, __MODULE__, [])
    |> Keyword.get(:sender, Happen.Push.WebPushSender)
  end
end
