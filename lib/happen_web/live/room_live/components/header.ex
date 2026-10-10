defmodule HappenWeb.RoomLive.Components.Header do
  use HappenWeb, :html

  alias HappenWeb.Components.Dropdown
  alias HappenWeb.RoomLive.Presences
  alias HappenWeb.RoomLive.PushNotifications
  alias HappenWeb.RoomLive.Timer
  alias HappenWeb.RoomLive.User

  attr :push_notifications, :map, required: true
  attr :room, :map, required: true
  attr :user, :map, required: true
  attr :timer, :map, required: true

  def render(assigns) do
    ~H"""
    <div class={[
      "flex justify-between gap-1 items-baseline",
      "bg-base-200 px-4 py-3 rounded-lg grow"
    ]}>
      <div
        data-testid="room-name"
        class={[
          "max-w-2/3",
          "opacity-40",
          "truncate text-sm font-bold"
        ]}
      >
        {@room.data.name}
      </div>

      <div class="ml-auto">
        <Timer.render_button timer={@timer} room={@room.data} />
      </div>

      <.dropdown_user user={@user.data} push_notifications={@push_notifications} />
    </div>
    """
  end

  attr :push_notifications, :map, required: true
  attr :user, :map, required: true

  defp dropdown_user(assigns) do
    ~H"""
    <Dropdown.render id="user-dropdown">
      <:trigger class="cursor-pointer opacity-90 hover:opacity-100 transition">
        <User.badge data-testid="current-user-badge" user={@user} />
      </:trigger>

      <:pane class={class_pane()}>
        <div class={["space-y-1"]}>
          <PushNotifications.render_button
            class={class_pane_item()}
            push_notifications={@push_notifications}
          />

          <div class={[class_pane_item(), "flex items-center gap-2"]}>
            <.icon name="hero-arrow-right-start-on-rectangle" />
            <.link data-testid="presences-leave" phx-click={Presences.leave_event()}>leave</.link>
          </div>
        </div>
      </:pane>
    </Dropdown.render>
    """
  end

  defp class_pane_item,
    do: [
      "cursor-pointer",
      "bg-base-100/80 hover:bg-base-100 rounded",
      "px-4 py-2"
    ]

  defp class_pane,
    do: [
      "dropdown-end",
      "bg-base-300 p-1",
      "rounded-box",
      "text-xs",
      "font-semibold",
      "mt-4",
      "-mr-4"
    ]
end
