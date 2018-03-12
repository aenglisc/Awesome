defmodule Awesome.GithubTest do
  use ExUnit.Case, async: false
  alias Awesome.Github
  import Mock

  @github_access_token Application.get_env(:awesome, :github_access_token)
  @test_link "https://api.github.com/repos/h4cc/awesome-elixir?access_token=" <> @github_access_token

  @dummy_body "Hello!"

  @dummy_200 "https://dum.my/200"
  @dummy_403 "https://dum.my/403"
  @dummy_404 "https://dum.my/404"
  @dummy_301_1 "https://dum.my/301/1"
  @dummy_301_2 "https://dum.my/301/2"

  @json_to_200 "{\n  \"url\": \"https://dum.my/200\"\n}"
  @json_to_404 "{\n  \"url\": \"https://dum.my/404\"\n}"
  @json_to_301 "{\n  \"url\": \"https://dum.my/301/2\"\n}"

  test "200" do
    with_mock HTTPoison, [get: fn(@dummy_200) -> {:ok, %{body: @dummy_body, status_code: 200}} end] do
      assert Github.get(@dummy_200) == {:ok, @dummy_body}
    end
  end

  test "403" do
    with_mock HTTPoison, [get: fn(@dummy_403) -> {:ok, status_code: 403} end] do
      assert Github.get(@dummy_403) == {:error, nil}
    end
  end

  test "404" do
    with_mock HTTPoison, [get: fn(@dummy_404) -> {:ok, status_code: 404} end] do
      assert Github.get(@dummy_404) == {:error, nil}
    end
  end

  test "301 -> 200" do
    with_mocks([{HTTPoison, [], [
      get: fn
        @dummy_301_1 -> {:ok, %{body: @json_to_200, status_code: 301}}
        @dummy_200 -> {:ok, %{body: @dummy_body, status_code: 200}}
      end
    ]}]) do
      assert Github.get(@dummy_301_1) == {:ok, @dummy_body}
    end
  end

  test "301 -> 404" do
    with_mocks([{HTTPoison, [], [
      get: fn
        @dummy_301_1 -> {:ok, %{body: @json_to_404, status_code: 301}}
        @dummy_404 -> {:ok, status_code: 404}
      end
    ]}]) do
      assert Github.get(@dummy_301_1) == {:error, nil}
    end
  end

  test "301 -> 301 -> 200" do
    with_mocks([{HTTPoison, [], [
      get: fn
        @dummy_301_1 -> {:ok, %{body: @json_to_301, status_code: 301}}
        @dummy_301_2 -> {:ok, %{body: @json_to_200, status_code: 301}}
        @dummy_200 -> {:ok, %{body: @dummy_body, status_code: 200}}
      end
    ]}]) do
      assert Github.get(@dummy_301_1) == {:ok, @dummy_body}
    end
  end

  test "not rate limited" do
    with_mock HTTPoison, [get!: fn(@test_link) -> %{headers: [{"X-RateLimit-Remaining", "4999"}], status_code: 200} end] do
      assert Github.rate_limited? == false
    end
  end

  test "rate limited" do
    with_mock HTTPoison, [get!: fn(@test_link) -> %{headers: [{"X-RateLimit-Remaining", "1200"}], status_code: 200} end] do
      assert Github.rate_limited? == true
    end
  end
end