defmodule Awesome.Github do
  @moduledoc """
    Github interaction
  """

  import Poison.Parser
  @list_location "https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md"

  @github_repo_api "https://api.github.com/repos"
  @github_token_query "?access_token="

  @rate "X-RateLimit-Remaining"

  def get_list, do: @list_location |> HTTPoison.get |> handle_response

  def get_repo_data(path) do
    @github_repo_api <> path <> @github_token_query <> get_token()
    |> HTTPoison.get
    |> handle_response
    |> parse_response
  end

  defp get_token, do: Application.get_env(:awesome, :github_access_token)

  defp handle_response({:ok, %{body: body, status_code: 200}}), do: {:ok, body}
  defp handle_response({:ok, %{body: json, status_code: 301}}), do: redirect(parse(json))
  defp handle_response({:ok, %{headers: headers, status_code: 403}}) do
    case headers |> Map.new |> Map.fetch(@rate) do
      {:ok, "0"} ->
        {:error, :rate_limited}
      _ ->
        {:error, :unavailable}
    end
  end
  defp handle_response(_), do: {:error, :unavailable}

  defp redirect({:ok, %{"url" => redirect_url}}) do
    redirect_url
    |> HTTPoison.get
    |> handle_response
  end
  defp redirect(_), do: {:error, :unavailable}

  defp parse_response({:ok, body}), do: parse(body)
  defp parse_response(error),       do: error
end
