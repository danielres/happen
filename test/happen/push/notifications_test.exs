defmodule Happen.Push.NotificationsTest do
  use ExUnit.Case, async: false

  alias Happen.Push
  alias Happen.Push.Notifications
  alias HappenWeb.RoomLive.Ideas.Store, as: IdeasStore
  alias HappenWeb.RoomLive.Messages.Store, as: MessagesStore

  defmodule Delivery do
    def deliver(room_name, author, kind, body) do
      Kernel.send(Application.fetch_env!(:happen, __MODULE__)[:test_pid], {
        :push_delivery,
        room_name,
        author,
        kind,
        body
      })
    end
  end

  setup do
    previous_push = Application.get_env(:happen, Push)
    previous_notifications = Application.get_env(:happen, Notifications)
    previous_delivery = Application.get_env(:happen, Delivery)

    Application.put_env(:happen, Push, vapid_public_key: "test-public-key")
    Application.put_env(:happen, Notifications, delivery: Delivery)
    Application.put_env(:happen, Delivery, test_pid: self())

    on_exit(fn ->
      restore_env(Push, previous_push)
      restore_env(Notifications, previous_notifications)
      restore_env(Delivery, previous_delivery)
    end)
  end

  test "new messages and ideas dispatch push delivery" do
    room_name = "events-#{System.unique_integer([:positive])}"
    author = %{id: Ash.UUID.generate(), name: "Author", hue: 40}

    MessagesStore.add_message(room_name, author, "Hello")
    IdeasStore.add_idea(room_name, author, "An idea")

    assert_receive {:push_delivery, ^room_name, ^author, :message, "Hello"}
    assert_receive {:push_delivery, ^room_name, ^author, :idea, "An idea"}
  end

  defp restore_env(module, nil), do: Application.delete_env(:happen, module)
  defp restore_env(module, value), do: Application.put_env(:happen, module, value)
end
