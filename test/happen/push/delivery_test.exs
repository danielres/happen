defmodule Happen.Push.DeliveryTest do
  use Happen.DataCase, async: false

  alias Happen.Accounts
  alias Happen.Push
  alias Happen.Push.Delivery
  alias Happen.Push.Focus

  defmodule Sender do
    @behaviour Happen.Push.Sender

    @impl true
    def send(subscription, payload) do
      Kernel.send(Application.fetch_env!(:happen, __MODULE__)[:test_pid], {
        :push_sent,
        subscription,
        payload
      })

      if String.ends_with?(subscription.endpoint, "/expired"), do: :expired, else: :ok
    end
  end

  setup do
    previous = Application.get_env(:happen, Delivery)
    previous_sender = Application.get_env(:happen, Sender)
    Application.put_env(:happen, Delivery, sender: Sender)
    Application.put_env(:happen, Sender, test_pid: self())

    on_exit(fn ->
      restore_env(Delivery, previous)
      restore_env(Sender, previous_sender)
    end)
  end

  test "delivery excludes the author, focused guests, and disabled invitations" do
    room_name = "delivery-#{System.unique_integer([:positive])}"
    {:ok, invitation} = Accounts.create_invitation()
    {:ok, disabled_invitation} = Accounts.create_invitation()
    {:ok, _disabled_invitation} = Accounts.disable_invitation(disabled_invitation)

    author = %{id: Ash.UUID.generate(), name: "Author"}
    focused_guest_id = Ash.UUID.generate()
    recipient_id = Ash.UUID.generate()

    subscribe("author", room_name, author.id, invitation.id)
    subscribe("focused", room_name, focused_guest_id, invitation.id)
    subscribe("disabled", room_name, Ash.UUID.generate(), disabled_invitation.id)
    subscribe("recipient", room_name, recipient_id, invitation.id)

    :ok = Focus.set(room_name, focused_guest_id, true)
    assert :ok = Delivery.deliver(room_name, author, :message, "Hello")

    assert_receive {:push_sent, subscription, payload}
    assert subscription.guest_id == recipient_id
    assert payload.body == "Author: Hello"
    assert payload.title == room_name
    refute_receive {:push_sent, _subscription, _payload}
  end

  test "expired endpoints are deleted" do
    room_name = "expired-#{System.unique_integer([:positive])}"
    {:ok, invitation} = Accounts.create_invitation()
    author = %{id: Ash.UUID.generate(), name: "Author"}

    subscribe("expired", room_name, Ash.UUID.generate(), invitation.id)

    assert :ok = Delivery.deliver(room_name, author, :idea, "An idea")
    assert_receive {:push_sent, _subscription, _payload}
    assert {:ok, []} = Push.subscriptions_for_room(room_name)
  end

  defp subscribe(name, room_name, guest_id, invitation_id) do
    {public_key, _private_key} = :crypto.generate_key(:ecdh, :prime256v1)

    attributes = %{
      "endpoint" => "https://fcm.googleapis.com/fcm/send/#{name}",
      "keys" => %{
        "auth" => Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false),
        "p256dh" => Base.url_encode64(public_key, padding: false)
      }
    }

    {:ok, subscription} =
      Push.sync_subscription(attributes, room_name, guest_id, invitation_id)

    subscription
  end

  defp restore_env(module, nil), do: Application.delete_env(:happen, module)
  defp restore_env(module, value), do: Application.put_env(:happen, module, value)
end
