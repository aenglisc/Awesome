defmodule AwesomeWeb.PageView do
  use AwesomeWeb, :view

  def name_to_id(name) do
    name
    |> String.downcase
    |> String.split(" ", trim: true)
    |> Enum.join("-")
  end

  def days_since_update(date) do
    {_, updated_at, _} = DateTime.from_iso8601(date)
    round(DateTime.diff(DateTime.utc_now, updated_at) / 24 / 60 / 60)
  end
end
