defmodule HappenWeb.RoomLive.PushNotifications do
  use HappenWeb, :html
  use LiveDelegate, path: [:push_notifications]

  alias Happen.Push
  alias Happen.Push.Focus

  def on_mount(_params, _session, socket) do
    status = if Push.configured?(), do: :loading, else: :unavailable

    delegate_assign(socket, %{
      public_key: Push.vapid_public_key(),
      status: status
    })
  end

  def handle_event("sync", %{"status" => "enabled", "subscription" => attributes}, socket) do
    room_name = socket.assigns.room.data.name
    guest_id = socket.assigns.user.data.id
    invitation_id = socket.assigns.current_invitation && socket.assigns.current_invitation.id

    case Push.sync_subscription(attributes, room_name, guest_id, invitation_id) do
      {:ok, _subscription} ->
        {:noreply, delegate_assign(socket, :status, :enabled)}

      {:error, _error} ->
        {:noreply, delegate_assign(socket, :status, :error)}
    end
  end

  def handle_event("sync", %{"status" => "disabled"}, socket) do
    {:noreply, delegate_assign(socket, :status, :disabled)}
  end

  def handle_event("sync", %{"status" => "denied"}, socket) do
    {:noreply, delegate_assign(socket, :status, :denied)}
  end

  def handle_event("sync", %{"status" => "unavailable"}, socket) do
    {:noreply, delegate_assign(socket, :status, :unavailable)}
  end

  def handle_event("disable", %{"endpoint" => endpoint}, socket) do
    :ok = Push.disable_subscription(endpoint, socket.assigns.user.data.id)
    {:noreply, delegate_assign(socket, :status, :disabled)}
  end

  def handle_event("focus", %{"focused" => focused}, socket) when is_boolean(focused) do
    room_name = socket.assigns.room.data.name
    guest_id = socket.assigns.user.data.id
    :ok = Focus.set(room_name, guest_id, focused)
    {:noreply, socket}
  end

  attr :push_notifications, :map, required: true
  slot :inner_block, required: true

  def root(assigns) do
    ~H"""
    <div
      id="push-notifications"
      data-disable-event={delegate_event("disable")}
      data-focus-event={delegate_event("focus")}
      data-public-key={@push_notifications.public_key}
      data-sync-event={delegate_event("sync")}
      phx-hook="PushNotifications"
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :push_notifications, :map, required: true

  def prompt(assigns) do
    ~H"""
    <div
      :if={@push_notifications.status == :disabled}
      data-testid="push-notifications-prompt"
    >
      <button
        class="btn btn-info btn-sm"
        data-testid="push-notifications-prompt-enable"
        phx-click={JS.dispatch("happen:push-enable")}
        type="button"
      >
        <.icon name="hero-bell-alert-mini" /> Enable notifications
      </button>
    </div>
    """
  end

  attr :push_notifications, :map, required: true

  def menu_item(assigns) do
    ~H"""
    <li :if={@push_notifications.status == :enabled}>
      <button
        data-testid="push-notifications-disable"
        phx-click={JS.dispatch("happen:push-disable")}
        type="button"
      >
        Disable notifications
      </button>
    </li>
    <li :if={@push_notifications.status == :disabled}>
      <button
        data-testid="push-notifications-enable"
        phx-click={JS.dispatch("happen:push-enable")}
        type="button"
      >
        Enable notifications
      </button>
    </li>
    <li :if={@push_notifications.status == :denied}>
      <span class="text-base-content/60">Notifications blocked by browser</span>
    </li>
    <li :if={@push_notifications.status == :error}>
      <span class="text-error">Notifications could not be enabled</span>
    </li>
    """
  end
end
