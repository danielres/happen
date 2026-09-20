defmodule Happen.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HappenWeb.Telemetry,
      Happen.Repo,
      {DNSCluster, query: Application.get_env(:happen, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Happen.PubSub},
      # Start a worker by calling: Happen.Worker.start_link(arg)
      # {Happen.Worker, arg},
      # Start to serve requests, typically the last entry
      HappenWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :happen]},
      {Group, name: :happen}
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Happen.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HappenWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
