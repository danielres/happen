self.addEventListener("push", event => {
  if (!event.data) return

  const notification = event.data.json()

  event.waitUntil(self.registration.showNotification(notification.title, {
    body: notification.body,
    data: { url: notification.url },
    tag: notification.tag,
  }))
})

self.addEventListener("notificationclick", event => {
  event.notification.close()

  event.waitUntil((async () => {
    const url = new URL(event.notification.data.url, self.location.origin).href
    const windows = await self.clients.matchAll({ type: "window", includeUncontrolled: true })
    const existing = windows.find(client => client.url === url)

    if (existing) return existing.focus()
    return self.clients.openWindow(url)
  })())
})
