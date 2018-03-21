defmodule Awesome.GithubTest do
  @moduledoc false
  use ExUnit.Case, async: false
  alias Awesome.Github
  import Mock

  @github_access_token Application.get_env(:awesome, :github_access_token)
  @github_repo_api "https://api.github.com/repos"
  @github_token_query "?access_token=" <> @github_access_token

  @list_location "https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md"
  @list File.read!(Path.join(__DIR__, "__fixtures__/list.md"))

  @repo1 "/dum/my1"
  @repo1_json File.read!(Path.join(__DIR__, "__fixtures__/repo1.json"))
  @repo1_link @github_repo_api <> @repo1 <> @github_token_query
  @repo1_result %{
    "html_url" => "https://github.com/dum/my1",
    "pushed_at" => "2017-11-10T08:47:22Z",
    "stargazers_count" => 1337
  }

  @repo2 "/dum/my2"
  @repo2_json File.read!(Path.join(__DIR__, "__fixtures__/repo2.json"))
  @repo2_link @github_repo_api <> @repo2 <> @github_token_query
  @repo2_result %{
    "html_url" => "https://github.com/dum/my2",
    "pushed_at" => "2017-12-10T08:47:22Z",
    "stargazers_count" => 420
  }

  @repo3 "/dum/my3"
  @repo3_json File.read!(Path.join(__DIR__, "__fixtures__/repo3.json"))
  @repo3_link @github_repo_api <> @repo3 <> @github_token_query
  @repo3_result %{
    "html_url" => "https://github.com/dum/my3",
    "pushed_at" => "2017-12-10T08:47:22Z",
    "stargazers_count" => 42
  }

  @repo1_to_repo2_redirect_json "{\n  \"url\": \"#{@repo2_link}\"\n}"
  @repo2_to_repo3_redirect_json "{\n  \"url\": \"#{@repo3_link}\"\n}"

  test "get list" do
    with_mock HTTPoison, [get: fn(@list_location) ->
      {:ok, %{body: @list, status_code: 200}}
    end] do
      assert Github.get_list == {:ok, @list}
    end
  end

  test "get list: error" do
    with_mock HTTPoison, [get: fn(@list_location) ->
      {:ok, %{status_code: 404}}
    end] do
      assert Github.get_list == {:error, :unavailable}
    end
  end

  test "get repo data: 200" do
    with_mock HTTPoison, [get: fn(@repo1_link) ->
      {:ok, %{body: @repo1_json, status_code: 200}}
    end] do
      assert Github.get_repo_data(@repo1) == {:ok, @repo1_result}
    end
  end

  test "get repo data: rate_limited" do
    with_mock HTTPoison, [get: fn(@repo1_link) ->
      {:ok, %{headers: [{"X-RateLimit-Remaining", "0"}], status_code: 403}}
    end] do
      assert Github.get_repo_data(@repo1) == {:error, :rate_limited}
    end
  end

  test "get repo data: 404" do
    with_mock HTTPoison, [get: fn(@repo1_link) ->
      {:ok, %{status_code: 404}}
    end] do
      assert Github.get_repo_data(@repo1) == {:error, :unavailable}
    end
  end

  test "get repo data: 301 -> 200" do
    with_mocks([{HTTPoison, [], [
      get: fn
        @repo1_link ->
          {:ok, %{body: @repo1_to_repo2_redirect_json, status_code: 301}}
        @repo2_link ->
          {:ok, %{body: @repo2_json, status_code: 200}}
      end
    ]}]) do
      assert Github.get_repo_data(@repo1) == {:ok, @repo2_result}
    end
  end

  test "get repo data: 301 -> 404" do
    with_mocks([{HTTPoison, [], [
      get: fn
        @repo1_link ->
          {:ok, %{body: @repo1_to_repo2_redirect_json, status_code: 301}}
        @repo2_link ->
          {:ok, %{status_code: 404}}
      end
    ]}]) do
      assert Github.get_repo_data(@repo1) == {:error, :unavailable}
    end
  end

  test "get repo data: 301 -> 301 -> 200" do
    with_mocks([{HTTPoison, [], [
      get: fn
        @repo1_link ->
          {:ok, %{body: @repo1_to_repo2_redirect_json, status_code: 301}}
        @repo2_link ->
          {:ok, %{body: @repo2_to_repo3_redirect_json, status_code: 301}}
        @repo3_link ->
          {:ok, %{body: @repo3_json, status_code: 200}}
      end
    ]}]) do
      assert Github.get_repo_data(@repo1) == {:ok, @repo3_result}
    end
  end
end
