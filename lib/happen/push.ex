defmodule Happen.Push do
  use Ash.Domain, otp_app: :happen

  require Ash.Query

  alias Happen.Push.RoomSubscription
  alias Happen.Push.Subscription

  resources do
    resource RoomSubscription
    resource Subscription
  end

  def configured? do
    is_binary(config()[:vapid_public_key])
  end

  def vapid_public_key, do: config()[:vapid_public_key]

  def sync_subscription(attributes, room_name, guest_id, invitation_id)
      when is_map(attributes) and is_binary(room_name) and is_binary(guest_id) do
    endpoint = attributes["endpoint"]

    Ash.transact([Subscription, RoomSubscription], fn ->
      previous = get_subscription_by_endpoint(endpoint)

      with {:ok, subscription} <- upsert_subscription(attributes, guest_id, invitation_id),
           :ok <- clear_rooms_if_owner_changed(previous, subscription),
           {:ok, _room_subscription} <- associate_room(subscription.id, room_name) do
        subscription
      else
        {:error, error} -> Ash.DataLayer.rollback(Subscription, error)
      end
    end)
  end

  def disable_subscription(endpoint, guest_id)
      when is_binary(endpoint) and is_binary(guest_id) do
    case get_subscription_by_endpoint(endpoint) do
      %Subscription{guest_id: ^guest_id} = subscription ->
        Ash.destroy(subscription, domain: __MODULE__)

      _subscription ->
        :ok
    end
  end

  def leave_room(guest_id, room_name) when is_binary(guest_id) and is_binary(room_name) do
    RoomSubscription
    |> Ash.Query.filter(room_name == ^room_name and subscription.guest_id == ^guest_id)
    |> Ash.bulk_destroy(:destroy, %{}, domain: __MODULE__, return_errors?: true)
    |> case do
      %Ash.BulkResult{status: :success} -> :ok
      %Ash.BulkResult{errors: errors} -> {:error, errors}
    end
  end

  def remove_for_invitation(invitation_id) do
    Subscription
    |> Ash.Query.filter(invitation_id == ^invitation_id)
    |> Ash.bulk_destroy(:destroy, %{}, domain: __MODULE__, return_errors?: true)
    |> case do
      %Ash.BulkResult{status: :success} -> :ok
      %Ash.BulkResult{errors: errors} -> {:error, errors}
    end
  end

  def subscriptions_for_room(room_name) do
    Subscription
    |> Ash.Query.filter(room_subscriptions.room_name == ^room_name)
    |> Ash.Query.load(:invitation)
    |> Ash.read(domain: __MODULE__)
  end

  defp upsert_subscription(attributes, guest_id, invitation_id) do
    keys = Map.get(attributes, "keys", %{})

    params = %{
      endpoint: attributes["endpoint"],
      guest_id: guest_id,
      invitation_id: invitation_id,
      p256dh: keys["p256dh"],
      auth: keys["auth"]
    }

    Subscription
    |> Ash.Changeset.for_create(:sync, params)
    |> Ash.create(domain: __MODULE__)
  end

  defp associate_room(subscription_id, room_name) do
    RoomSubscription
    |> Ash.Changeset.for_create(:associate, %{
      subscription_id: subscription_id,
      room_name: room_name
    })
    |> Ash.create(domain: __MODULE__)
  end

  defp clear_rooms_if_owner_changed(nil, _subscription), do: :ok

  defp clear_rooms_if_owner_changed(previous, subscription) do
    if {previous.guest_id, previous.invitation_id} ==
         {subscription.guest_id, subscription.invitation_id} do
      :ok
    else
      previous
      |> Ash.load!(:room_subscriptions, domain: __MODULE__)
      |> Map.fetch!(:room_subscriptions)
      |> Enum.each(&Ash.destroy!(&1, domain: __MODULE__))
    end
  end

  defp get_subscription_by_endpoint(endpoint) when is_binary(endpoint) do
    Subscription
    |> Ash.Query.filter(endpoint == ^endpoint)
    |> Ash.read_one!(domain: __MODULE__)
  end

  defp get_subscription_by_endpoint(_endpoint), do: nil

  defp config, do: Application.get_env(:happen, __MODULE__, [])
end
