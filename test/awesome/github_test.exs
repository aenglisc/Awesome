defmodule Awesome.GithubTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Awesome.Github
  import Plug.Conn
  import Poison.Parser

  setup do
    bypass = Bypass.open
    Application.put_env(:awesome, :github_api_endpoint, "http://localhost:#{bypass.port}")
    Application.put_env(:awesome, :github_list_location, "http://localhost:#{bypass.port}")

    {:ok, bypass: bypass}
  end

  @list File.read!(Path.join(__DIR__, "__fixtures__/list.md"))

  @repo_uri URI.parse("https://github.com/dum/my1")
  @repo_json File.read!(Path.join(__DIR__, "__fixtures__/repo1.json"))
  @repo_result parse!(@repo_json)
  @rate [{"X-RateLimit-Remaining", "0"}]

  test "get list", %{bypass: bypass} do
    Bypass.expect(bypass, &send_resp(&1, 200, @list))
    assert Github.get_list == {:ok, @list}
  end

  test "get list: error", %{bypass: bypass} do
    Bypass.expect(bypass, &send_resp(&1, 404, ""))
    assert Github.get_list == {:error, :unavailable}
  end

  test "get repo data: 200", %{bypass: bypass} do
    Bypass.expect(bypass, &send_resp(&1, 200, @repo_json))
    assert Github.get_repo_data(@repo_uri) == {:ok, @repo_result}
  end

  test "get repo data: rate_limited", %{bypass: bypass} do
    Bypass.expect(bypass, &send_resp(Map.put(&1, :resp_headers, @rate), 403, @repo_json))
    assert Github.get_repo_data(@repo_uri) == {:error, :rate_limited}
  end

  test "get repo data: 404", %{bypass: bypass} do
    Bypass.expect(bypass, &send_resp(&1, 404, ""))
    assert Github.get_repo_data(@repo_uri) == {:error, :unavailable}
  end
end
