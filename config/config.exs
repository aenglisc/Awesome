# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :awesome, AwesomeWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "0Ds4AyJk+0CmvA0n31NAP6Ex9S6EFkAgOU/HUCMEHZQiyHEJn8o1ZWltPQSiPYL9",
  render_errors: [view: AwesomeWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Awesome.PubSub, adapter: Phoenix.PubSub.PG2],
  github_access_token: System.get_env("GITHUB_ACCESS_TOKEN")

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"