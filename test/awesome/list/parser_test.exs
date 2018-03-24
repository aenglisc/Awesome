defmodule Awesome.List.ParserTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias Awesome.List.{Parser, Storage}
  alias Awesome.Github
  import Mock

  @list File.read!(Path.join(__DIR__, "../__fixtures__/list.md"))
  @storage_path Path.join(__DIR__, "../../../test_storage")

  @repo1_uri URI.parse("https://github.com/hello/world")
  @repo2_uri URI.parse("https://github.com/hello/there")
  @repo3_uri URI.parse("https://github.com/howdy/world")
  @repo4_uri URI.parse("https://github.com/howdy/there")

  @repo1_json %{
    "html_url" => "https://github.com/hello/world",
    "stargazers_count" => 1337,
    "pushed_at" => "2017-11-10T08:47:22Z"}
  @repo2_json %{
    "html_url" => "https://github.com/hello/there",
    "stargazers_count" => 420,
    "pushed_at" => "2017-12-10T08:47:22Z"}
  @repo3_json %{
    "html_url" => "https://github.com/howdy/world_new",
    "stargazers_count" => 42,
    "pushed_at" => "2018-01-02T08:47:22Z"}

  @parsed_list [
    {"Hello", {"Hello, good sir!",
     [
       {"hello-world", {"Hello!",
       "https://github.com/hello/world", 1337, "2017-11-10T08:47:22Z"}},
       {"hello-there", {"<a href=\"https://apple.com/\">Hello there</a>!",
       "https://github.com/hello/there", 420, "2017-12-10T08:47:22Z"}}
     ]}
    },
    {"Howdy", {"Howdy, good sir!",
     [
       {"howdy-world", {"Howdy!",
       "https://github.com/howdy/world_new", 42, "2018-01-02T08:47:22Z"}}
     ]}
    }
  ]

  @parsed_list_rate_limited [
    {"Hello", {"Hello, good sir!",
     [
       {"hello-world", {"Hello!",
       "https://github.com/hello/world", 1337, "2017-11-10T08:47:22Z"}}
     ]}
    },
    {"Howdy", {"Howdy, good sir!",
     [
       {"howdy-world", {"Howdy!",
       "https://github.com/howdy/world_new", 42, "2018-01-02T08:47:22Z"}}
     ]}
    }
  ]

  test "parser creates a valid list" do
    with_mocks([
      {Github, [], [get_repo_data: fn
        @repo1_uri -> {:ok, @repo1_json}
        @repo2_uri -> {:ok, @repo2_json}
        @repo3_uri -> {:ok, @repo3_json}
        @repo4_uri -> {:error, :unavailable}
      end]}]) do
      assert Parser.parse_list(@list) == @parsed_list
    end
  end

  test "rate limited: parser fetches old repo data" do
    with_mocks([
      {Github, [], [get_repo_data: fn
        @repo1_uri -> {:ok, @repo1_json}
        @repo2_uri -> {:error, :rate_limited}
        @repo3_uri -> {:ok, @repo3_json}
        @repo4_uri -> {:error, :unavailable}
      end]}]) do
      Storage.write_list(@parsed_list)
      assert Parser.parse_list(@list) == @parsed_list
      File.rm!(@storage_path)
    end
  end

  test "rate limited: no old data" do
    with_mocks([
      {Github, [], [get_repo_data: fn
        @repo1_uri -> {:ok, @repo1_json}
        @repo2_uri -> {:error, :rate_limited}
        @repo3_uri -> {:ok, @repo3_json}
        @repo4_uri -> {:error, :unavailable}
      end]}]) do
      assert Parser.parse_list(@list) == @parsed_list_rate_limited
      File.rm!(@storage_path)
    end
  end
end
