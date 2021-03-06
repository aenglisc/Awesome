defmodule Awesome.List.Github do
  @moduledoc """
    Github interaction
  """
  @github_token_query "?access_token="

  defp get_list_url, do: Application.get_env(:awesome, :github_list_location)
  defp get_endpoint, do: Application.get_env(:awesome, :github_api_endpoint)
  defp get_token, do: Application.get_env(:awesome, :github_access_token)

  def get_list do
    get_list_url()
    |> HTTPoison.get([], follow_redirect: true)
    |> handle_response
  end

  def get_repo_data(%{host: "github.com", path: path}) do
    (get_endpoint() <> path <> @github_token_query <> get_token())
    |> HTTPoison.get([], follow_redirect: true)
    |> handle_response
    |> parse_response
  end

  def get_repo_data(_), do: {:error, :unavailable}

  defp handle_response({:ok, %{body: body, status_code: 200}}), do: {:ok, body}
  defp handle_response(_), do: {:error, :unavailable}

  defp parse_response({:ok, body}), do: Jason.decode(body)
  defp parse_response(error), do: error
end
