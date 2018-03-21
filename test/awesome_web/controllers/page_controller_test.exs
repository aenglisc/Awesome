defmodule AwesomeWeb.PageControllerTest do
  @moduledoc false
  use AwesomeWeb.ConnCase
  import Mock
  alias Awesome.List.{Storage}

  @list [
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
     ]
    }}
  ]

  test "GET /", %{conn: conn} do
    with_mocks([
      {Storage, [], [get_list: fn() -> @list end]}
    ]) do
      conn = get conn, "/"
      assert html_response(conn, 200)
    end
  end

  test "GET /?min_stars=50", %{conn: conn} do
    with_mocks([
      {Storage, [], [get_list: fn() -> @list end]}
    ]) do
      conn = get conn, "/?min_stars=50"
      assert html_response(conn, 200)
      assert length(conn.assigns.list) == 1
    end
  end

  test "GET /?min_stars=invalid", %{conn: conn} do
    with_mocks([
      {Storage, [], [get_list: fn() -> @list end]}
    ]) do
      conn = get conn, "/?min_stars=invalid"
      assert html_response(conn, 200)
    end
  end

  test "GET /invalid", %{conn: conn} do
    with_mocks([
      {Storage, [], [get_list: fn() -> @list end]}
    ]) do
      conn = get conn, "/invalid"
      assert html_response(conn, 302)
    end
  end
end
