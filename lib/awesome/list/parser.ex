defmodule Awesome.List.Parser do
  @moduledoc """
    List parser
  """
  alias Awesome.List.Github

  @regex_line_parser ~r{^\* \[([^]]+)\]\(([^)]+)\) - (.+)}

  @url "html_url"
  @stars "stargazers_count"
  @updated "pushed_at"

  @timeout timeout: :infinity

  def parse_list(raw_list_string) do
    raw_list_string
    |> clean_and_split_into_sections
    |> parse_sections
  end

  defp clean_and_split_into_sections(string) do
    string
    |> String.split("\n# ", trim: true)
    |> List.first()
    |> String.split("## ", trim: true)
    |> Enum.slice(1..-1)
  end

  defp parse_sections(list) do
    list
    |> Task.async_stream(&build_section_node(&1), @timeout)
    |> Enum.filter(&match?({:ok, _res}, &1))
    |> Enum.map(fn {:ok, res} -> res end)
  end

  defp build_section_node(section_string) do
    [name, description | repos] = String.split(section_string, "\n", trim: true)
    {name, {get_section_description(description), parse_repos(repos)}}
  end

  defp get_section_description(string) do
    string
    |> String.slice(1..-2)
    |> Earmark.as_html!()
  end

  defp parse_repos(list) do
    list
    |> Task.async_stream(&build_repo_node(parse_repo(&1)), @timeout)
    |> Enum.reduce([], &process_repo_node(&1, &2))
    |> Enum.reverse()
  end

  defp process_repo_node({:ok, {:ok, repo}}, acc), do: [repo | acc]
  defp process_repo_node(_, acc), do: acc

  defp build_repo_node([_, repo_name, repo_url, repo_desc]) do
    case get_repo_data(repo_url) do
      {:ok, %{@url => url, @stars => stars, @updated => updated}} ->
        {:ok, {repo_name, {Earmark.as_html!(repo_desc), url, stars, updated}}}

      _ ->
        {:error, :unavailable}
    end
  end

  defp build_repo_node(_repo), do: {:error, :unavailable}

  defp get_repo_data(repo_url) do
    repo_url
    |> URI.parse()
    |> Github.get_repo_data()
  end

  defp parse_repo(string), do: Regex.run(@regex_line_parser, string)
end
