defmodule Awesome.Github do
  import Poison.Parser
  @test_link "https://api.github.com/repos/h4cc/awesome-elixir?access_token="

  def get(url) do
    url
    |> HTTPoison.get
    |> handle_response
  end

  def rate_limited? do
    1500 > get_rate()
  end

  def get_token, do: Application.get_env(:awesome, :github_access_token)

  defp handle_response({:ok, %{body: body, status_code: 200}}), do: {:ok, body}
  defp handle_response({:ok, %{body: redirect_json, status_code: 301}}) do
    {:ok, %{"url" => redirect_url}} = parse(redirect_json)
    handle_response(HTTPoison.get(redirect_url))
  end
  defp handle_response(_), do: {:error, nil}

  defp get_rate() do
    @test_link <> get_token()
    |> HTTPoison.get!
    |> Map.fetch!(:headers)
    |> Enum.filter(&(&1 |> elem(0) == "X-RateLimit-Remaining"))
    |> List.first
    |> elem(1)
    |> Integer.parse
    |> elem(0)
  end
end