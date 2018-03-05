defmodule AwesomeWeb.PageController do
  use AwesomeWeb, :controller
  alias Awesome.List.Storage

  def redirect_to_index(conn, _params) do
    conn
    |> redirect(to: page_path(conn, :index))
  end

  def index(%{query_params: %{"min_stars" => stars_filter} } = conn, _params) do
    list = Storage.get_list
    case Integer.parse(stars_filter) do
      :error -> 
        render conn, "index.html", list: list
      {filter, _} ->
        filtered_list = list
        |> Enum.map(&(&1 |> filter_repos(filter)))
        |> Enum.filter(fn {_, _, repos} -> Enum.count(repos) > 0 end)
        render conn, "index.html", list: filtered_list
    end
  end

  def index(conn, _params) do
    list = Storage.get_list
    render conn, "index.html", list: list
  end

  defp filter_repos({name, description, repos}, filter) do
    filtered = repos
    |> Enum.filter(fn {_, _, _, stars, _} -> stars >= filter end)
    {name, description, filtered}
  end
end
