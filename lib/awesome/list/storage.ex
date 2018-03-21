defmodule Awesome.List.Storage do
  @moduledoc """
    Storage management
  """
  @storage Application.get_env(:awesome, :storage)
  @day_in_seconds 24 * 60 * 60

  def get_list do
    {:ok, table} = :dets.open_file(@storage, [type: :set])
    list = :dets.match_object(table, {:"$1", {:"$2", :"$3"}})
    :dets.close(table)
    Enum.sort(list)
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

  def get_repo_data(section_name, repo_name) do
    {:ok, table} = :dets.open_file(@storage, [type: :set])
    section = :dets.lookup(table, section_name)
    :dets.close(table)

    find_repo(section, repo_name)
  end

  def write_list(list) do
    {:ok, table} = :dets.open_file(@storage, [type: :set])
    :dets.insert(table, {:latest_update, DateTime.utc_now})
    Enum.each(list, &(:dets.insert(table, &1)))
    :dets.close(table)
  end

  defp find_repo([{_name, {_desc, repos}}], repo_name) do
    repos
    |> Map.new
    |> Map.fetch(repo_name)
    |> find_repo
  end
  defp find_repo(_, _), do: :unavailable
  defp find_repo({:ok, data}), do: data
  defp find_repo(:error), do: :unavailable

  defp time_elapsed(date), do: DateTime.diff(DateTime.utc_now, date)
end
