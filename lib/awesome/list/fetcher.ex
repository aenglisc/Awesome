defmodule Awesome.List.Fetcher do
  @moduledoc """
    List fetcher
  """

  alias Awesome.List.{Parser, Storage}
  alias Awesome.Github

  def update_list(:daily), do: Github.get_list |> parse_and_write
  def update_list(:reboot), do: unless Storage.up_to_date?, do: Github.get_list |> parse_and_write

  defp parse_and_write({:ok, body}) do
    body
    |> Parser.parse_list
    |> Storage.write_list
  end
  defp parse_and_write(error), do: error
end
