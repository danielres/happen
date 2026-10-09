# Happen

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://phoenix.hexdocs.pm/deployment.html).

## Push notifications

Generate VAPID credentials with:

    mix web_push_ex.vapid

Set `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, and `VAPID_SUBJECT` in the runtime environment. The subject must be a `mailto:` or HTTPS URI identifying the application operator. Production startup requires all three values; development leaves push notifications unavailable when they are omitted.

Push delivery requires HTTPS, except that browsers treat `localhost` as a secure development context. Deployments must run the generated database migration before enabling notifications.

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://phoenix.hexdocs.pm/overview.html
* Docs: https://phoenix.hexdocs.pm
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
