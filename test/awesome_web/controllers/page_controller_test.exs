defmodule AwesomeWeb.PageControllerTest do
  use AwesomeWeb.ConnCase
  import Mock
  alias Awesome.List.{Storage}

  @storage_path Path.join(__DIR__, "../../../test_storage")
  @list [
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

  test "GET /", %{conn: conn} do
    with_mocks([
      {Storage, [], [get_list: fn() -> @list end]}
    ]) do
      conn = get conn, "/"
      assert html_response(conn, 200)
      File.rm(@storage_path)
    end
  end

  test "GET /?min_stars=50", %{conn: conn} do
    with_mocks([
      {Storage, [], [get_list: fn() -> @list end]}
    ]) do
      conn = get conn, "/?min_stars=50"
      assert html_response(conn, 200)
      File.rm(@storage_path)
    end
  end

  test "GET /?min_stars=invalid", %{conn: conn} do
    with_mocks([
      {Storage, [], [get_list: fn() -> @list end]}
    ]) do
      conn = get conn, "/?min_stars=invalid"
      assert html_response(conn, 200)
      File.rm(@storage_path)
    end
  end

  test "GET /invalid", %{conn: conn} do
    conn = get conn, "/invalid"
    assert html_response(conn, 302)
  end
end