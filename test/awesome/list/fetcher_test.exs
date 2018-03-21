defmodule Awesome.List.FetcherTest do
  @moduledoc false
  use ExUnit.Case, async: false
  alias Awesome.List.{Fetcher, Parser, Storage}
  alias Awesome.Github
  import Mock

  @list File.read!(Path.join(__DIR__, "../__fixtures__/list.md"))
  @storage_path Path.join(__DIR__, "../../../test_storage")
  @parsed_list [
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

  test "list unavailable" do
    with_mocks([
      {Github, [], [get_list: fn -> {:error, :unavailable} end]}
    ]) do
      assert Fetcher.update_list(:reboot) == {:error, :unavailable}
      assert Fetcher.update_list(:daily) == {:error, :unavailable}
      File.rm(@storage_path)
    end
  end

  test "run daily" do
    with_mocks([
      {Github, [], [get_list: fn -> {:ok, @list} end]},
      {Parser, [], [parse_list: fn(_) -> @parsed_list end]}
    ]) do
      assert Fetcher.update_list(:daily) == :ok
      assert Storage.get_list == @parsed_list
      File.rm(@storage_path)
    end
  end

  test "run on reboot" do
    with_mocks([
      {Github, [], [get_list: fn -> {:ok, @list} end]},
      {Parser, [], [parse_list: fn(_) -> @parsed_list end]}
    ]) do
      assert Fetcher.update_list(:reboot) == :ok
      assert Storage.get_list == @parsed_list
      assert Storage.up_to_date?
      assert Fetcher.update_list(:reboot) == nil
      File.rm(@storage_path)
    end
  end
end
