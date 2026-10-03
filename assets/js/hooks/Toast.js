import ToastHook from "../../../deps/toast/assets/js/toast.js"

export const Toast = {
  ...ToastHook,

  removeToastFromServer(toastId) {
    this.removingToastIds ||= new Set()

    if (this.removingToastIds.has(toastId)) return

    const toastEntry = Array.from(this.toasts.entries()).find(
      ([, toastInfo]) => toastInfo.toastId === toastId,
    )

    if (!toastEntry) {
      this.pushEventTo(this.el, "clear", { id: toastId })
      return
    }

    const [domId, toastInfo] = toastEntry
    const exitOffset = this.position.includes("top") ? "-100%" : "100%"

    this.removingToastIds.add(toastId)
    this.removeToast(domId)
    toastInfo.element.style.transform = `translateY(${exitOffset})`
    toastInfo.element.style.pointerEvents = "none"

    setTimeout(() => {
      this.removingToastIds.delete(toastId)
      this.pushEventTo(this.el, "clear", { id: toastId })
    }, this.animationDuration)
  },
}
