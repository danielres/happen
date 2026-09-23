defmodule HappenWeb.Components.Dropdown do
  use HappenWeb, :html

  attr :class, :any, default: nil
  attr :id, :string, required: true

  slot :trigger, required: true do
    attr :class, :any, required: true
  end

  slot :pane, required: true do
    attr :class, :any, required: true
  end

  def render(assigns) do
    ~H"""
    <button
      :for={trigger <- @trigger}
      id={"#{@id}-trigger"}
      class={trigger.class}
      popovertarget={"popover-#{@id}"}
      style={"anchor-name:--anchor-#{@id}"}
      type="button"
    >
      {render_slot(trigger)}
    </button>

    <div
      :for={pane <- @pane}
      class={[
        "dropdown mt-1",
        "[position-anchor:--anchor-#{@id}]",
        pane.class
      ]}
      id={"popover-#{@id}"}
      popover
    >
      {render_slot(pane)}
    </div>
    """
  end
end
