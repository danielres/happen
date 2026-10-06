defmodule HappenWeb.RoomLive.Messages.Notification do
  use HappenWeb, :live_view
  use LiveDelegate, path: [:messages, :notification]

  @exit_timeout 300
  @timeout :timer.seconds(4)

  def on_mount(_params, _session, socket) do
    socket
    |> delegate_assign(%{message: nil, visible?: false})
    |> attach_hook(
      :dismiss_message_notification_on_tab_selection,
      :handle_event,
      &handle_tab_selection/3
    )
  end

  def show(%{assigns: %{active_tab: "messages"}} = socket, _message), do: socket

  def show(socket, message) do
    Process.send_after(
      self(),
      {:messages, {:notification, {:dismiss, message.id}}},
      @timeout
    )

    socket
    |> delegate_assign(:message, message)
    |> delegate_assign(:visible?, true)
  end

  @impl Phoenix.LiveView
  def handle_info({:dismiss, message_id}, socket) do
    notification = socket.assigns.messages.notification

    socket =
      if notification.message && notification.message.id == message_id do
        dismiss(socket)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info({:clear, message_id}, socket) do
    notification = socket.assigns.messages.notification

    socket =
      if notification.message && notification.message.id == message_id &&
           !notification.visible? do
        delegate_assign(socket, :message, nil)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_tab_selection("tabs:select", %{"tab" => "messages"}, socket) do
    {:cont, dismiss(socket)}
  end

  def handle_tab_selection(_event, _params, socket), do: {:cont, socket}

  attr :notification, :map, required: true
  slot :inner_block, required: true

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div
      class={[
        "tooltip tooltip-bottom tooltip-info",
        "pointer-events-none",
        @notification.visible? && "tooltip-open",
        "[--tt-off:3rem]",
        "[--tt-tail:2.8rem]"
      ]}
      data-testid="message-notification-trigger"
    >
      {render_slot(@inner_block)}
      <div
        class="tooltip-content max-w-64 shadow"
        data-testid={if(@notification.message, do: "message-notification")}
      >
        <div
          :if={@notification.message}
          class="py-0 px-1 gap-2 items-baseline opacity-90 text-xs"
        >
          <span class="font-bold">{@notification.message.user.name}</span>
          <div class="truncate">
            {@notification.message.body}
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp dismiss(socket) do
    notification = socket.assigns.messages.notification

    cond do
      notification.message == nil ->
        socket

      !notification.visible? ->
        socket

      true ->
        Process.send_after(
          self(),
          {:messages, {:notification, {:clear, notification.message.id}}},
          @exit_timeout
        )

        delegate_assign(socket, :visible?, false)
    end
  end
end
