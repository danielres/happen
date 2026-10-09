defmodule Happen.PushTest do
  use Happen.DataCase, async: true

  alias Happen.Accounts
  alias Happen.Push

  test "a browser subscription accumulates visited rooms without duplicates" do
    {:ok, invitation} = Accounts.create_invitation()
    guest_id = Ash.UUID.generate()
    attributes = subscription_attributes("rooms")

    assert {:ok, subscription} =
             Push.sync_subscription(attributes, "First room", guest_id, invitation.id)

    assert {:ok, ^subscription} =
             Push.sync_subscription(attributes, "First room", guest_id, invitation.id)

    assert {:ok, _subscription} =
             Push.sync_subscription(attributes, "Second room", guest_id, invitation.id)

    assert {:ok, [first]} = Push.subscriptions_for_room("First room")
    assert {:ok, [second]} = Push.subscriptions_for_room("Second room")
    assert first.id == second.id
  end

  test "reassigning an endpoint clears rooms belonging to its previous owner" do
    {:ok, first_invitation} = Accounts.create_invitation()
    {:ok, second_invitation} = Accounts.create_invitation()
    attributes = subscription_attributes("reassigned")

    assert {:ok, _subscription} =
             Push.sync_subscription(
               attributes,
               "Old room",
               Ash.UUID.generate(),
               first_invitation.id
             )

    second_guest_id = Ash.UUID.generate()

    assert {:ok, subscription} =
             Push.sync_subscription(
               attributes,
               "New room",
               second_guest_id,
               second_invitation.id
             )

    assert {:ok, []} = Push.subscriptions_for_room("Old room")
    assert {:ok, [current]} = Push.subscriptions_for_room("New room")
    assert current.id == subscription.id
    assert current.guest_id == second_guest_id
  end

  test "leaving a room only removes that room association" do
    {:ok, invitation} = Accounts.create_invitation()
    guest_id = Ash.UUID.generate()
    attributes = subscription_attributes("leave")

    assert {:ok, _subscription} =
             Push.sync_subscription(attributes, "First room", guest_id, invitation.id)

    assert {:ok, _subscription} =
             Push.sync_subscription(attributes, "Second room", guest_id, invitation.id)

    assert :ok = Push.leave_room(guest_id, "First room")
    assert {:ok, []} = Push.subscriptions_for_room("First room")
    assert {:ok, [_subscription]} = Push.subscriptions_for_room("Second room")
  end

  test "removing an invitation removes all of its browser subscriptions" do
    {:ok, invitation} = Accounts.create_invitation()

    assert {:ok, _subscription} =
             Push.sync_subscription(
               subscription_attributes("invitation"),
               "Room",
               Ash.UUID.generate(),
               invitation.id
             )

    assert :ok = Push.remove_for_invitation(invitation.id)
    assert {:ok, []} = Push.subscriptions_for_room("Room")
  end

  test "subscription data rejects unknown providers and malformed keys" do
    {:ok, invitation} = Accounts.create_invitation()
    guest_id = Ash.UUID.generate()

    attributes =
      subscription_attributes("invalid")
      |> put_in(["endpoint"], "https://example.com/push/invalid")
      |> put_in(["keys", "auth"], "invalid")

    assert {:error, error} =
             Push.sync_subscription(attributes, "Room", guest_id, invitation.id)

    message = Exception.message(error)
    assert message =~ "supported Web Push provider"
  end

  defp subscription_attributes(name) do
    {public_key, _private_key} = :crypto.generate_key(:ecdh, :prime256v1)

    %{
      "endpoint" => "https://fcm.googleapis.com/fcm/send/#{name}",
      "keys" => %{
        "auth" => Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false),
        "p256dh" => Base.url_encode64(public_key, padding: false)
      }
    }
  end
end
