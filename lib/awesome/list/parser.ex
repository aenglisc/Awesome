defmodule Awesome.List.Parser do
  alias Awesome.Github
  
  @regex_github_link ~r/https:\/\/github.com\/[\w\-]+\/[\w\-]+/
  @regex_repo_name ~r/\[(.*?)\]/
  @regex_description ~r/\)\ \-\ (.+)/
  @regex_link ~r/\[([^]]*)\]\(([^\s^\)]*)[\s\)]/
  @github_repo_api "https://api.github.com/repos"
  @github_token_query "?access_token="

  def parse(data) do
    data
    |> remove_resources
    |> remove_index_and_split_into_sections
    |> parse_sections
  end

  defp remove_resources(string) do
    string
    |> String.split("\n# ", trim: true)
    |> Enum.at(0)
  end

  defp remove_index_and_split_into_sections(string) do
    string
    |> String.split("## ", trim: true)
    |> Enum.slice(1..-1)
  end

  defp parse_sections(list) do
    list
    |> Task.async_stream(&(&1 |> String.split("\n", trim: true) |> build_section_node), timeout: :infinity)
    |> Enum.map(fn {:ok, res} -> res end)
  end

  defp build_section_node([name, description | repos]) do
    {
      name,
      description |> String.slice(1..-2) |> parse_links_in_description,
      repos |> parse_repos
    }
  end

  defp parse_repos(list) do
    list
    |> Enum.filter(&(&1 =~ @regex_github_link))
    |> Task.async_stream(&(&1 |> build_repo_node), timeout: :infinity)
    |> Enum.reduce([], fn {:ok, res}, acc -> if res, do: [res | acc], else: acc end)
    |> Enum.reverse
  end

  defp build_repo_node(string) do
    path = string
    |> get_github_url
    |> URI.parse
    |> Map.get(:path)

    result = @github_repo_api <> path <> @github_token_query <> Github.get_token
    |> Github.get

    case result do
      {:ok, json} ->
        {:ok, %{
          "html_url" => repo_url,
          "stargazers_count" => stars,
          "pushed_at" => updated_at
        }} = Poison.Parser.parse(json)
        {
          repo_url,
          string |> get_repo_name,
          string |> get_repo_description |> parse_links_in_description,
          stars,
          updated_at
        }
      _ ->
        nil
    end
  end

  defp get_github_url(string),       do: @regex_github_link |> Regex.run(string) |> Enum.at(0)
  defp get_repo_name(string),        do: @regex_repo_name   |> Regex.run(string) |> Enum.at(1)
  defp get_repo_description(string), do: @regex_description |> Regex.run(string) |> Enum.at(1)
  
  defp parse_links_in_description(string), do: Regex.replace(@regex_link, string, "<a href=\"\\2\">\\1</a>")
end
