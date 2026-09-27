defmodule HappenWeb.ExperimentsLive.Components.Header do
  use HappenWeb, :html

  def render(assigns) do
    ~H"""
    <div class="flex justify-between gap-4 items-baseline">
      {@room.name}

      <HappenWeb.Components.Dropdown.render id="user-dropdown">
        <:trigger class="cursor-pointer">
          <HappenWeb.ExperimentsLive.User.badge data-testid="current-user-badge" user={@user} />
        </:trigger>

        <:pane class="bg-base-200 dropdown-end rounded-box">
          <ul class="menu w-40">
            <li class="bg-base-100">
              <.link phx-click="presence:leave">leave</.link>
            </li>
          </ul>
        </:pane>
      </HappenWeb.Components.Dropdown.render>
    </div>
    """
  end
end
