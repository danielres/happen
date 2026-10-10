defmodule HappenWeb.RoomLive.Components.Header do
  use HappenWeb, :html

  alias HappenWeb.Components.Dropdown
  alias HappenWeb.RoomLive.Presences
  alias HappenWeb.RoomLive.PushNotifications
  alias HappenWeb.RoomLive.User

  def render(assigns) do
    ~H"""
    <div class={[
      "flex justify-between gap-4 items-end",
      "bg-base-200 px-4 py-3 rounded-lg grow"
    ]}>
      <div data-testid="room-name" class="font-bold opacity-40 truncate text-sm max-w-2/3">
        {@room.name}
      </div>

      <Dropdown.render id="user-dropdown">
        <:trigger class="cursor-pointer opacity-90 hover:opacity-100 transition">
          <User.badge data-testid="current-user-badge" user={@user} />
        </:trigger>

        <:pane class={[
          "dropdown-end",
          "bg-base-300 p-1",
          "rounded-box",
          "text-xs",
          "font-semibold",
          "mt-4",
          "-mr-4"
        ]}>
          <% item_class = [
            "cursor-pointer",
            "bg-base-100/80 hover:bg-base-100 rounded",
            "px-4 py-2"
          ] %>
          <div class={["space-y-1"]}>
            <PushNotifications.render_button
              push_notifications={@push_notifications}
              class={[item_class]}
            />

            <div class={[item_class, "flex items-center gap-2"]}>
              <.icon name="hero-arrow-right-start-on-rectangle" />
              <.link data-testid="presences-leave" phx-click={Presences.leave_event()}>leave</.link>
            </div>
          </div>
        </:pane>
      </Dropdown.render>
    </div>
    """
  end
end
