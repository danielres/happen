defmodule HappenWeb.Sections.Messages.List do
  use HappenWeb, :html

  attr :messages, :list, required: true

  def render(assigns) do
    ~H"""
    <ul
      id="messages"
      class="min-h-0 flex-1 space-y-1 overflow-y-auto"
      phx-hook=".AutoScroll"
    >
      <li :for={message <- @messages} class="bg-base-200 py-2 px-4">
        <div class="text-sm opacity-50">{message.member.name}</div>
        <div>{message.body}</div>
      </li>
    </ul>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".AutoScroll">
      export default {
        mounted() {
          this.scrollToBottom()
        },

        beforeUpdate() {
          this.followingLatest =
            this.el.scrollHeight - this.el.scrollTop - this.el.clientHeight < 64
        },

        updated() {
          if (this.followingLatest) this.scrollToBottom()
        },

        scrollToBottom() {
          this.el.scrollTop = this.el.scrollHeight
        }
      }
    </script>
    """
  end
end
