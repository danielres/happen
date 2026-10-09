const applicationServerKey = encoded => {
  const padding = "=".repeat((4 - encoded.length % 4) % 4)
  const base64 = (encoded + padding).replace(/-/g, "+").replace(/_/g, "/")
  return Uint8Array.from(atob(base64), character => character.charCodeAt(0))
}

export const PushNotifications = {
  mounted() {
    this.enable = () => this.enableNotifications()
    this.disable = () => this.disableNotifications()
    this.reportFocus = () => {
      const focused = document.visibilityState === "visible" && document.hasFocus()

      if (focused !== this.focused) {
        this.focused = focused
        this.pushEvent(this.el.dataset.focusEvent, { focused })
      }
    }

    this.el.addEventListener("happen:push-enable", this.enable)
    this.el.addEventListener("happen:push-disable", this.disable)
    window.addEventListener("focus", this.reportFocus)
    window.addEventListener("blur", this.reportFocus)
    document.addEventListener("visibilitychange", this.reportFocus)

    this.syncSubscription()
    this.reportFocus()
  },

  destroyed() {
    this.el.removeEventListener("happen:push-enable", this.enable)
    this.el.removeEventListener("happen:push-disable", this.disable)
    window.removeEventListener("focus", this.reportFocus)
    window.removeEventListener("blur", this.reportFocus)
    document.removeEventListener("visibilitychange", this.reportFocus)
  },

  supported() {
    return window.isSecureContext &&
      "serviceWorker" in navigator &&
      "PushManager" in window &&
      "Notification" in window
  },

  async registration() {
    return navigator.serviceWorker.register("/sw.js", { scope: "/" })
  },

  async syncSubscription() {
    if (!this.supported() || !this.el.dataset.publicKey) {
      this.pushEvent(this.el.dataset.syncEvent, { status: "unavailable" })
      return
    }

    if (Notification.permission === "denied") {
      this.pushEvent(this.el.dataset.syncEvent, { status: "denied" })
      return
    }

    try {
      const subscription = await (await this.registration()).pushManager.getSubscription()
      this.pushSubscription(subscription)
    } catch (_error) {
      this.pushEvent(this.el.dataset.syncEvent, { status: "unavailable" })
    }
  },

  async enableNotifications() {
    if (!this.supported()) {
      this.pushEvent(this.el.dataset.syncEvent, { status: "unavailable" })
      return
    }

    const permission = await Notification.requestPermission()

    if (permission !== "granted") {
      this.pushEvent(this.el.dataset.syncEvent, {
        status: permission === "denied" ? "denied" : "disabled"
      })
      return
    }

    try {
      const registration = await this.registration()
      const existing = await registration.pushManager.getSubscription()
      const subscription = existing || await registration.pushManager.subscribe({
        applicationServerKey: applicationServerKey(this.el.dataset.publicKey),
        userVisibleOnly: true,
      })

      this.pushSubscription(subscription)
    } catch (_error) {
      this.pushEvent(this.el.dataset.syncEvent, { status: "unavailable" })
    }
  },

  async disableNotifications() {
    try {
      const subscription = await (await this.registration()).pushManager.getSubscription()

      if (subscription) {
        const endpoint = subscription.endpoint
        await subscription.unsubscribe()
        this.pushEvent(this.el.dataset.disableEvent, { endpoint })
      } else {
        this.pushEvent(this.el.dataset.syncEvent, { status: "disabled" })
      }
    } catch (_error) {
      this.pushEvent(this.el.dataset.syncEvent, { status: "unavailable" })
    }
  },

  pushSubscription(subscription) {
    if (subscription) {
      this.pushEvent(this.el.dataset.syncEvent, {
        status: "enabled",
        subscription: subscription.toJSON(),
      })
    } else {
      this.pushEvent(this.el.dataset.syncEvent, { status: "disabled" })
    }
  },
}
