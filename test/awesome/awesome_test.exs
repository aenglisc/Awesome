defmodule Awesome.AwesomeTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Awesome.List.{Fetcher, Storage}
  import Plug.Conn

  @list File.read!(Path.join(__DIR__, "__fixtures__/list.md"))

  @repo1_path "/hello/world"
  @repo2_path "/hello/there"
  @repo3_path "/howdy/world"
  @repo4_path "/howdy/there"

  @repo1_json File.read!(Path.join(__DIR__, "__fixtures__/repo1.json"))
  @repo2_json File.read!(Path.join(__DIR__, "__fixtures__/repo2.json"))
  @repo3_json File.read!(Path.join(__DIR__, "__fixtures__/repo3.json"))

  @rate_limit [{"X-RateLimit-Remaining", "0"}]

  @storage_path Path.join(__DIR__, "../../test_storage")
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
       "https://github.com/howdy/world", 42, "2018-01-02T08:47:22Z"}}
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
       "https://github.com/howdy/world", 42, "2018-01-02T08:47:22Z"}}
     ]}
    }
  ]

  setup do
    bypass = Bypass.open
    Application.put_env(:awesome, :github_api_endpoint, "http://localhost:#{bypass.port}")
    Application.put_env(:awesome, :github_list_location, "http://localhost:#{bypass.port}")

    {:ok, bypass: bypass}
  end

  test "list unavailable", %{bypass: bypass} do
    Bypass.expect(bypass,
      &send_resp(&1, 404, ""))

    assert Fetcher.update_list(:reboot) == {:error, :unavailable}
    assert Fetcher.update_list(:daily) == {:error, :unavailable}

    File.rm(@storage_path)
  end

  test "run fetcher", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/",
      &send_resp(&1, 200, @list))

    Bypass.expect(bypass, "GET", @repo1_path,
      &send_resp(&1, 200, @repo1_json))

    Bypass.expect(bypass, "GET", @repo2_path,
      &send_resp(&1, 200, @repo2_json))

    Bypass.expect(bypass, "GET", @repo3_path,
      &send_resp(&1, 200, @repo3_json))

    Bypass.expect(bypass, "GET", @repo4_path,
      &send_resp(&1, 404, ""))

    assert Storage.up_to_date? == false

    assert Fetcher.update_list(:daily) == :ok
    assert Storage.get_list == @parsed_list

    assert Storage.up_to_date?
    assert Fetcher.update_list(:reboot) == nil

    File.rm(@storage_path)

    assert Fetcher.update_list(:reboot) == :ok
    assert Storage.get_list == @parsed_list

    File.rm(@storage_path)
  end

  test "rate limited", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/",
      &send_resp(&1, 200, @list))

    Bypass.expect(bypass, "GET", @repo1_path,
      &send_resp(&1, 200, @repo1_json))

    Bypass.expect(bypass, "GET", @repo2_path,
      &send_resp(Map.put(&1, :resp_headers, @rate_limit), 403, ""))

    Bypass.expect(bypass, "GET", @repo3_path,
      &send_resp(&1, 200, @repo3_json))

    Bypass.expect(bypass, "GET", @repo4_path,
      &send_resp(&1, 404, ""))

    assert Fetcher.update_list(:daily) == :ok
    assert Storage.get_list == @parsed_list_rate_limited

    File.rm(@storage_path)

    Storage.write_list(@parsed_list)

    assert Fetcher.update_list(:daily) == :ok
    assert Storage.get_list == @parsed_list

    File.rm(@storage_path)
  end
end
