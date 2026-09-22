defmodule HappenWeb.Components.Header do
  use HappenWeb, :html

  attr :member, :map, required: true
  attr :room, :map, required: true

  def render(assigns) do
    ~H"""
    <header class="bg-base-300 flex shrink-0 items-end justify-between gap-4 p-4">
      <h1>
        <div class="uppercase text-xs opacity-50">Room</div>
        <div class="font-semibold opacity-60">{@room.name}</div>
      </h1>

      <button
        phx-click="toggle"
        type="button"
        class="flex items-baseline gap-2 cursor-pointer text-xs"
      >
        <span :if={@member.available?} class="text-success">Available now</span>
        <span :if={!@member.available?} class="text-warning">Not available now</span>

        <HappenWeb.Components.Badge.render member={@member} />
      </button>
    </header>
    """
  end
end
