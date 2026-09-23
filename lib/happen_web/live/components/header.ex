defmodule HappenWeb.Components.Header do
  use HappenWeb, :html

  attr :member, :map, required: true
  attr :room, :map, required: true

  def render(assigns) do
    ~H"""
    <header class="bg-base-300 flex shrink-0 items-end justify-between gap-4 px-4 py-2">
      <h1 class="leading-none">
        <div class="uppercase text-xs opacity-50">Room</div>
        <div class="font-semibold opacity-60">{@room.name}</div>
      </h1>

      <HappenWeb.Components.Dropdown.render id="user-dropdown">
        <:trigger class="cursor-pointer">
          <HappenWeb.Components.Badge.render member={@member} />
        </:trigger>

        <:pane class="bg-base-200 p-4 dropdown-end w-40 flex justify-end">
          <button
            phx-click="toggle"
            type="button"
            class="cursor-pointer text-xs text-right"
          >
            <input
              type="checkbox"
              class="toggle toggle-success"
              checked={@member.available? && "checked"}
              class="toggle"
            />

            <div>
              <span :if={@member.available?} class="text-success">Available now</span>
              <span :if={!@member.available?} class="text-base-content/50">Not available now</span>
            </div>
          </button>
        </:pane>
      </HappenWeb.Components.Dropdown.render>
    </header>
    """
  end
end
