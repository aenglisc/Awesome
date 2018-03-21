defmodule AwesomeWeb.PageController do
  use AwesomeWeb, :controller
  alias Awesome.List.Storage

  def redirect_to_index(conn, _params) do
    conn
    |> redirect(to: page_path(conn, :index))
  end

  def index(%{query_params: %{"min_stars" => stars_filter}} = conn, _params) do
    case Integer.parse(stars_filter) do
      :error ->
        render conn, "index.html", list: Storage.get_list
      {stars, _} ->
        render conn, "index.html", list: Storage.get_list(stars)
    end
  end

  def index(conn, _params) do
    render conn, "index.html", list: Storage.get_list
  end
end
