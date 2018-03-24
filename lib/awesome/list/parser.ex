defmodule Awesome.List.Parser do
  @moduledoc """
    List parser
  """

  alias Awesome.Github
  alias Awesome.List.Storage

  @regex_line_parser ~r/^\* \[([^]]+)\]\(([^)]+)\) - (.+)/

  @regex_link ~r/\[([^]]*)\]\(([^\s^\)]*)[\s\)]/
  @link_replacement "<a href=\"\\2\">\\1</a>"

  @url "html_url"
  @stars "stargazers_count"
  @updated "pushed_at"

  def parse_list(raw_list_string) do
    raw_list_string
    |> clean_and_split_into_sections
    |> parse_sections
  end

  defp clean_and_split_into_sections(string) do
    string
    |> String.split("\n# ", trim: true)
    |> List.first
    |> String.split("## ", trim: true)
    |> Enum.slice(1..-1)
  end

  defp parse_sections(list) do
    list
    |> Task.async_stream(&(build_section_node(&1)), timeout: :infinity)
    |> Enum.filter(&(match?({:ok, _res}, &1)))
    |> Enum.map(fn {:ok, res} -> res end)
  end

  defp build_section_node(section_string) do
    [name, description | repos] = String.split(section_string, "\n", trim: true)
    {name, {get_section_description(description), parse_repos(repos, name)}}
  end

  defp get_section_description(string) do
    string
    |> String.slice(1..-2)
    |> md_links_to_html
  end

  defp parse_repos(list, section_name) do
    list
    |> Task.async_stream(&(build_repo_node(&1, section_name)), timeout: :infinity)
    |> Enum.reduce([], &(process_repo_node(&1, &2)))
    |> Enum.reverse
  end

  defp process_repo_node({:ok, {:ok, repo}}, acc), do: [repo | acc]
  defp process_repo_node(_, acc), do: acc

  defp build_repo_node(repo_string, section_name) do
    [_, repo_name, repo_url, repo_desc] = parse_repo(repo_string)

    case get_repo_data_remote(repo_url) do
      {:ok, %{@url => url, @stars => stars, @updated => updated}} ->
        {:ok, {repo_name, {md_links_to_html(repo_desc), url, stars, updated}}}
      {:error, :rate_limited} ->
        get_repo_data_local(section_name, repo_name)
      _ ->
        {:error, :unavailable}
    end
  end

  defp get_repo_data_remote(repo_url) do
    repo_url
    |> URI.parse
    |> Github.get_repo_data
  end

  defp get_repo_data_local(section_name, repo_name) do
    case Storage.get_repo_data(section_name, repo_name) do
      {:ok, data} ->
        {:ok, {repo_name, data}}
      _ ->
        {:error, :unavailable}
    end
  end

  defp parse_repo(string), do: Regex.run(@regex_line_parser, string)
  defp md_links_to_html(string), do: Regex.replace(@regex_link, string, @link_replacement)
end
