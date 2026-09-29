defmodule HappenWeb.Components.Tabs do
  use HappenWeb, :html

  slot :inner_block, required: true

  def render(assigns) do
    ~H"""
    <div class={["tabs tabs-xl"]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :active?, :boolean, default: false
  attr :name, :string, required: true
  attr :rest, :global

  slot :indicator
  slot :label, required: true
  slot :inner_block, required: true

  def tab(assigns) do
    ~H"""
    <label class={[
      "tab rounded-lg mr-3",
      "bg-base-200 has-[input:checked]:bg-base-300",
      "relative"
    ]}>
      <input checked={@active?} name={@name} type="radio" {@rest} />
      <div class="pb-1">{render_slot(@label)}</div>
      <div class="text-xs absolute bottom-0.5 right-1.5 ldstyle-nums">
        {render_slot(@indicator)}
      </div>
    </label>

    <div class={["tab-content pt-6"]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :count, :integer, required: true
  attr :rest, :global

  def count(assigns) do
    ~H"""
    <span
      class={[
        @count > 0 && "opacity-50",
        @count == 0 && "opacity-0"
      ]}
      {@rest}
    >
      {@count}
    </span>
    """
  end
end
