# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :awesome, AwesomeWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: AwesomeWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Awesome.PubSub, adapter: Phoenix.PubSub.PG2]

config :awesome, github_access_token: System.get_env("GITHUB_ACCESS_TOKEN")
config :awesome, github_api_endpoint: "https://api.github.com/repos"
config :awesome, github_list_location: "https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
