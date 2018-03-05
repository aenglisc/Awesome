defmodule Awesome.List.Test do
  use ExUnit.Case, async: false
  alias Awesome.List.Parser
  alias Awesome.Http
  import Mock

  @env Application.get_env(:awesome, AwesomeWeb.Endpoint)

  @sample_list Path.join(__DIR__, "__fixtures__/list.md")

  @token "?access_token=" <> @env[:github_access_token]
  @hello1_link "https://api.github.com/repos/hello/world" <> @token
  @hello2_link "https://api.github.com/repos/hello/there" <> @token
  @howdy1_link "https://api.github.com/repos/howdy/world" <> @token
  @howdy2_link "https://api.github.com/repos/howdy/there" <> @token

  @hello1_json Path.join(__DIR__, "__fixtures__/hello1.json")
  @hello2_json Path.join(__DIR__, "__fixtures__/hello2.json")
  @howdy1_json Path.join(__DIR__, "__fixtures__/howdy1_updated.json")

  @expected_list [
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

  test "parser creates a valid list" do
    with_mocks([{Http, [], [
      get: fn
        @hello1_link -> {:ok, File.read!(@hello1_json)}
        @hello2_link -> {:ok, File.read!(@hello2_json)}
        @howdy1_link -> {:ok, File.read!(@howdy1_json)}
        @howdy2_link -> {:error, nil}
      end
    ]}]) do

      parsed_list = File.read!(@sample_list)
      |> Parser.parse

      assert parsed_list == @expected_list
    end
  end
end
