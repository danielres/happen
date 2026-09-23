defmodule HappenWeb.Sections.Messages.List do
  use HappenWeb, :html

  attr :messages, :list, required: true

  def render(assigns) do
    ~H"""
    <ul
      id="messages"
      class="min-h-0 flex-1 space-y-1 overflow-y-auto mb-4 px-4"
      phx-hook=".AutoScroll"
    >
      <li :for={message <- @messages} class="bg-base-200 py-3 px-4">
        <div class="text-xs opacity-50">{message.member.name}</div>
        <div class="text-sm">{message.body}</div>
      </li>
    </ul>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".AutoScroll">
      export default {
        mounted() {
          this.followingLatest = true
          this.updateFollowingLatest = () => {
            this.followingLatest =
              this.el.scrollHeight - this.el.scrollTop - this.el.clientHeight < 64
          }
          this.scheduleScrollToBottom = () => {
            if (!this.followingLatest) return

            cancelAnimationFrame(this.scrollFrame)
            this.scrollFrame = requestAnimationFrame(() => this.scrollToBottom())
          }

          this.el.addEventListener("scroll", this.updateFollowingLatest, {passive: true})
          this.resizeObserver = new ResizeObserver(this.scheduleScrollToBottom)
          this.resizeObserver.observe(this.el)
          this.scrollToBottom()
        },

        updated() {
          this.scheduleScrollToBottom()
        },

        destroyed() {
          cancelAnimationFrame(this.scrollFrame)
          this.resizeObserver.disconnect()
          this.el.removeEventListener("scroll", this.updateFollowingLatest)
        },

        scrollToBottom() {
          this.el.scrollTop = this.el.scrollHeight
          this.followingLatest = true
        }
      }
    </script>
    """
  end
end
