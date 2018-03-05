defmodule Awesome.List.Fetcher do
  alias Awesome.List.{Parser, Storage}
  alias Awesome.Http

  @link "https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md"

  def update_list do
    unless Http.rate_limited? do
      download_and_write(@link |> Http.get)
      {:ok, :updated}
    else
      {:error, :not_updated}
    end
  end

  def update_if_outdated do
    unless Storage.up_to_date? or Http.rate_limited? do
      download_and_write(@link |> Http.get)
      {:ok, :updated}
    else
      {:error, :not_updated}
    end
  end

  defp download_and_write({:ok, body}) do
    body
    |> Parser.parse
    |> Storage.write_list
  end
end