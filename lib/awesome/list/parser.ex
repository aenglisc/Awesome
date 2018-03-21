defmodule Awesome.List.Parser do
  @moduledoc """
    List parser
  """

  alias Awesome.Github
  alias Awesome.List.Storage

  @regex_github_link ~r/https:\/\/github.com\/[\w\-]+\/[\w\-]+/
  @regex_repo_name ~r/\[(.*?)\]/
  @regex_repo_description ~r/\)\ \-\ (.+)/

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
    {name, {parse_section_description(description), parse_repos(repos, name)}}
  end

  defp parse_section_description(string) do
    string
    |> String.slice(1..-2)
    |> parse_links_in_description
  end

  defp parse_repos(list, section_name) do
    list
    |> Enum.filter(&(&1 =~ @regex_github_link))
    |> Task.async_stream(&(build_repo_node(&1, section_name)), timeout: :infinity)
    |> Enum.filter(&(match?({:ok, _res}, &1)))
    |> Enum.map(fn {:ok, res} -> res end)
    |> Enum.reject(&(match?({_name, :unavailable}, &1)))
  end

  defp build_repo_node(repo_string, section_name) do
    repo_name = get_repo_name(repo_string)
    case get_repo_data(repo_string) do
      {:ok, %{@url => url, @stars => stars, @updated => updated}} ->
        {repo_name, {get_repo_description(repo_string), url, stars, updated}}
      {:error, :rate_limited} ->
        {repo_name, get_repo_data_local(section_name, repo_name)}
      _ ->
        {repo_name, :unavailable}
    end
  end

  defp get_repo_data(string) do
    string
    |> get_github_url
    |> URI.parse
    |> Map.get(:path)
    |> Github.get_repo_data
  end

  defp get_repo_data_local(section_name, repo_name) do
    case Storage.get_repo_data(section_name, repo_name) do
      {:ok, data} ->
        data
      _ ->
        :unavailable
    end
  end

  defp get_github_url(string), do: @regex_github_link |> Regex.run(string) |> Enum.at(0)
  defp get_repo_name(string),  do: @regex_repo_name   |> Regex.run(string) |> Enum.at(1)
  defp get_repo_description(string) do
    @regex_repo_description
    |> Regex.run(string)
    |> Enum.at(1)
    |> parse_links_in_description
  end

  defp parse_links_in_description(string), do: Regex.replace(@regex_link, string, @link_replacement)
end
