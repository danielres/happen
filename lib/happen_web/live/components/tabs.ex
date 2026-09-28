defmodule HappenWeb.Components.Tabs do
  use HappenWeb, :html

  slot :inner_block, required: true

  def render(assigns) do
    ~H"""
    <div class={["tabs tabs-xl bg-transparent "]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :active?, :boolean, default: false
  attr :name, :string, required: true
  attr :rest, :global

  slot :label, required: true
  slot :inner_block, required: true

  def tab(assigns) do
    ~H"""
    <label class={[
      "tab rounded-lg mr-2",
      "bg-base-200 has-[input:checked]:bg-base-300"
    ]}>
      <input checked={@active?} name={@name} type="radio" {@rest} />
      {render_slot(@label)}
    </label>

    <div class={["tab-content pt-4"]}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
