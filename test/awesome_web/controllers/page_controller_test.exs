defmodule AwesomeWeb.PageControllerTest do
  @moduledoc false
  use AwesomeWeb.ConnCase
  alias Awesome.List.Storage

  @storage_path Path.join(__DIR__, "../../../test_storage")
  @list [
    {"Hello", {"Hello, good sir!",
     [
       {"hello-there", {"<a href=\"https://apple.com/\">Hello there</a>!",
       "https://github.com/hello/there", 420, "2017-12-10T08:47:22Z"}},
       {"hello-world", {"Hello!",
       "https://github.com/hello/world", 1337, "2017-11-10T08:47:22Z"}}
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
    Storage.write_list(@list)
    conn = get conn, "/"
    assert html_response(conn, 200)
    assert conn.assigns.list == @list
    File.rm!(@storage_path)
  end

  test "GET /?min_stars=50", %{conn: conn} do
    Storage.write_list(@list)
    conn = get conn, "/?min_stars=50"
    assert html_response(conn, 200)
    assert conn.assigns.list == [List.first(@list)]
    File.rm!(@storage_path)
  end

  test "GET /?min_stars=invalid", %{conn: conn} do
    Storage.write_list(@list)
    conn = get conn, "/?min_stars=invalid"
    assert html_response(conn, 200)
    assert conn.assigns.list == @list
    File.rm!(@storage_path)
  end

  test "GET /invalid", %{conn: conn} do
    conn = get conn, "/invalid"
    assert html_response(conn, 302)
  end
end
