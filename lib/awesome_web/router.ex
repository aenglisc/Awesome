defmodule AwesomeWeb.Router do
  use AwesomeWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  # pipeline :api do
  #   plug :accepts, ["json"]
  # end

  scope "/", AwesomeWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)
    get("/*path", PageController, :redirect_to_index)
  end

  # Other scopes may use custom stacks.
  # scope "/api", AwesomeWeb do
  #   pipe_through :api
  # end
end
