defmodule Awesome.List.Storage do
  @moduledoc """
    Storage management
  """
  @storage Application.get_env(:awesome, :storage)
  @day_in_seconds 24 * 60 * 60

  def get_list(stars \\ 0) do
    {:ok, table} = :dets.open_file(@storage, [type: :set])
    list = :dets.match_object(table, {:"$1", {:"$2", :"$3"}})
    :dets.close(table)
    list
    |> Enum.map(&filter_repos(&1, stars))
    |> Enum.filter(&filter_sections(&1))
    |> Enum.sort
  end

  defp filter_repos({name, {description, repos}}, filter) do
    filtered = repos
    |> Enum.filter(fn {_, {_, _, stars, _}} -> stars >= filter end)
    {name, {description, filtered}}
  end

  defp filter_sections({_name, {_desc, repos}}), do: length(repos) > 0

  def write_list(list) do
    {:ok, table} = :dets.open_file(@storage, [type: :set])
    :dets.insert(table, {:latest_update, DateTime.utc_now})
    Enum.each(list, &:dets.insert(table, &1))
    :dets.close(table)
  end

  def up_to_date? do
    {:ok, table} = :dets.open_file(@storage, [type: :set])
    result = :dets.match_object(table, {:latest_update, :"$1"})
    :dets.close(table)

    case result[:latest_update] do
      nil ->
        false
      date ->
        time_elapsed(date) < @day_in_seconds
    end
  end

  defp time_elapsed(date), do: DateTime.diff(DateTime.utc_now, date)
end
