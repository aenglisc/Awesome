defmodule Awesome.List.FetcherTest do
  use ExUnit.Case, async: false
  alias Awesome.List.{Fetcher, Parser, Storage}
  alias Awesome.Http
  import Mock

  @link "https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md"
  @list Path.join(__DIR__, "__fixtures__/list.md") |> File.read!
  @storage_path Path.join(__DIR__, "../../../test_storage")
  @parsed_list [
    {"Hello", "Hello, good sir!",
     [
       {"https://github.com/hello/world", "hello-world", "Hello!", 1337,
        "2017-11-10T08:47:22Z"},
       {"https://github.com/hello/there", "hello-there",
        "<a href=\"https://apple.com/\">Hello there</a>!", 420,
        "2017-12-10T08:47:22Z"}
     ]
    },
    {"Howdy", "Howdy, good sir!",
     [
       {"https://github.com/howdy/world_new", "howdy-world", "Howdy!", 42,
        "2018-01-02T08:47:22Z"}
     ]
    }
  ]

  test "fetcher creates valid storage record" do
    with_mocks([
      {Http, [], [get: fn(@link) -> {:ok, @list} end]},
      {Http, [], [rate_limited?: fn() -> false end]},
      {Parser, [], [parse: fn(_) -> @parsed_list end]}
    ]) do
      assert Fetcher.update_list == {:ok, :updated}
      assert Storage.get_list == @parsed_list
      File.rm(@storage_path)
    end
  end

  test "update if outdated works" do
    with_mocks([
      {Http, [], [get: fn(@link) -> {:ok, @list} end]},
      {Http, [], [rate_limited?: fn() -> false end]},
      {Parser, [], [parse: fn(_) -> @parsed_list end]}
    ]) do
      assert Storage.up_to_date? == false
      assert Fetcher.update_if_outdated == {:ok, :updated}
      assert Storage.up_to_date? == true
      assert Storage.get_list == @parsed_list
      File.rm(@storage_path)
    end
  end

  test "no update when rate-limited" do
    with_mocks([
      {Http, [], [rate_limited?: fn() -> true end]},
      {Storage, [], [up_to_date?: fn() -> false end]}
    ]) do
      assert Fetcher.update_list == {:error, :not_updated}
      assert Fetcher.update_if_outdated == {:error, :not_updated}
      File.rm(@storage_path)
    end
  end

  test "no update when up-to-date" do
    with_mocks([
      {Http, [], [rate_limited?: fn() -> false end]},
      {Storage, [], [up_to_date?: fn() -> true end]}
    ]) do
      assert Fetcher.update_if_outdated == {:error, :not_updated}
      File.rm(@storage_path)
    end
  end
end