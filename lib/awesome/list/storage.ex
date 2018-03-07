defmodule Awesome.List.Storage do
  @storage Application.get_env(:awesome, :storage)
  @day_in_seconds 24 * 60 * 60

  def get_list do
    {:ok, table} = :dets.open_file(@storage, [type: :set])
    list = :dets.match_object(table, {:"$1", :"$2", :"$3"})
    |> Enum.sort
    :dets.close(table)
    list
  end

  def write_list(list) do
    {:ok, table} = :dets.open_file(@storage, [type: :set])
    :dets.insert(table, {:latest_update, DateTime.utc_now})
    list |> Enum.each(&(:dets.insert(table, &1)))
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