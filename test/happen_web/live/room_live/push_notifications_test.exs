defmodule HappenWeb.RoomLive.PushNotificationsTest do
  use HappenWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Happen.Accounts
  alias Happen.Push
  alias Happen.Push.Focus
  alias Happen.RoomKey

  setup do
    previous = Application.get_env(:happen, Push)
    Application.put_env(:happen, Push, vapid_public_key: "test-public-key")

    on_exit(fn ->
      if previous do
        Application.put_env(:happen, Push, previous)
      else
        Application.delete_env(:happen, Push)
      end
    end)

    {:ok, invitation} = Accounts.create_invitation()
    %{invitation: invitation}
  end

  test "enables and disables notifications for the current browser", %{
    conn: conn,
    invitation: invitation
  } do
    room_name = "push-#{System.unique_integer([:positive])}"
    guest_id = Ash.UUID.generate()

    conn = invitation_session(conn, invitation.id, guest_id)
    {:ok, view, _html} = live(conn, room_path(room_name))

    render_hook(view, "push_notifications:sync", %{"status" => "disabled"})
    assert has_element?(view, "[data-testid='push-notifications-prompt']")
    assert has_element?(view, "[data-testid='push-notifications-enable']")

    attributes = subscription_attributes("current-browser")

    render_hook(view, "push_notifications:sync", %{
      "status" => "enabled",
      "subscription" => attributes
    })

    refute has_element?(view, "[data-testid='push-notifications-prompt']")
    assert has_element?(view, "[data-testid='push-notifications-disable']")
    assert {:ok, [subscription]} = Push.subscriptions_for_room(room_name)
    assert subscription.guest_id == guest_id
    assert subscription.invitation_id == invitation.id

    render_hook(view, "push_notifications:disable", %{"endpoint" => attributes["endpoint"]})

    assert has_element?(view, "[data-testid='push-notifications-prompt']")
    assert {:ok, []} = Push.subscriptions_for_room(room_name)
  end

  test "tracks whether the current browser is focused in the room", %{
    conn: conn,
    invitation: invitation
  } do
    room_name = "focus-#{System.unique_integer([:positive])}"
    guest_id = Ash.UUID.generate()

    conn = invitation_session(conn, invitation.id, guest_id)
    {:ok, view, _html} = live(conn, room_path(room_name))

    render_hook(view, "push_notifications:focus", %{"focused" => true})
    assert MapSet.member?(Focus.focused_guest_ids(room_name), guest_id)

    render_hook(view, "push_notifications:focus", %{"focused" => false})
    refute MapSet.member?(Focus.focused_guest_ids(room_name), guest_id)
  end

  defp invitation_session(conn, invitation_id, guest_id) do
    init_test_session(conn, %{
      "guest_id" => guest_id,
      "guest_name" => "Test guest",
      "guest_since" => DateTime.now!("Etc/UTC"),
      "invitation_id" => invitation_id
    })
  end

  defp room_path(room_name), do: ~p"/#{RoomKey.encode(room_name)}"

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
