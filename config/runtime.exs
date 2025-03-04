import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# Start the phoenix server if environment is set and running in a release
if System.get_env("PHX_SERVER") && System.get_env("RELEASE_NAME") do
  config :ash_hq, AshHqWeb.Endpoint, server: true
end

config :ash_hq, :github,
  api_key: System.get_env("GITHUB_API_KEY"),
  client_id: System.get_env("GITHUB_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET"),
  redirect_uri: System.get_env("GITHUB_REDIRECT_URI")

periodic_imports? = System.get_env("PERIODIC_IMPORTS") == "true"

discord_bot? = System.get_env("DISCORD_BOT") == "true"
config :ash_hq, :periodic_imports, periodic_imports?
config :ash_hq, :discord_bot, discord_bot?

host = System.get_env("PHX_HOST") || "localhost"
port = String.to_integer(System.get_env("PORT") || "4000")

if config_env() != :dev do
  config :logger, level: String.to_existing_atom(System.get_env("LOG_LEVEL") || "info")
end

nostrum_token = System.get_env("DISCORD_BOT_TOKEN")

config :nostrum,
  token: nostrum_token,
  disabled?: is_nil(nostrum_token) || !discord_bot?

# config/config.exs
config :ash_hq, Oban,
  repo: AshHq.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron, crontab: []}
  ],
  queues: [importer: [limit: 1, paused: not (periodic_imports? || config_env() == :prod)]]

if config_env() == :prod do
  app_name =
    System.get_env("FLY_APP_NAME") ||
      raise "FLY_APP_NAME not available"

  config :libcluster,
    topologies: [
      fly6pn: [
        strategy: Cluster.Strategy.DNSPoll,
        config: [
          polling_interval: 5_000,
          query: "#{app_name}.internal",
          node_basename: app_name
        ]
      ]
    ]

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  pool_size =
    if FLAME.Parent.get() do
      3
    else
      String.to_integer(System.get_env("POOL_SIZE") || "10")
    end

  config :ash_hq, AshHq.Repo,
    ssl: false,
    url: database_url,
    pool_size: pool_size,
    socket_options: [:inet6]

  config :flame, :backend, FLAME.FlyBackend
  config :flame, FLAME.FlyBackend, token: System.fetch_env!("FLY_API_TOKEN")
  config :flame, :terminator, shutdown_timeout: :timer.seconds(30)

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :ash_hq,
    token_signing_secret: secret_key_base

  config :ash_hq, AshHqWeb.Endpoint,
    server: true,
    url: [host: host, port: 80],
    check_origin: [
      "http://#{host}",
      "https://#{host}",
      "http://www.#{host}",
      "https://www.#{host}"
    ],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  #     config :ash_hq, AshHqWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :ash_hq, AshHq.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  config :ash_hq, AshHq.Mailer, api_key: System.get_env("POSTMARK_API_KEY")

  config :ash_hq, AshHq.MailingList.Mailer,
    api_key: System.get_env("POSTMARK_MAILING_LIST_API_KEY")
end
