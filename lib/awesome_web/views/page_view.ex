defmodule AwesomeWeb.PageView do
  use AwesomeWeb, :view

  def render_table_of_contents(list) do
    rendered_contents = list
    |> Task.async_stream(&render_contents_item/1)
    |> Enum.map(fn {:ok, res} -> res end)
    |> Enum.join("\n")

    """
    <div class="container text-center col-xl-4 mb-5">
      <button class="dropdown-toggle btn btn-block btn-link" type="button" data-toggle="collapse" data-target="#collapseExample" aria-expanded="false" aria-controls="collapseExample">
        Table of contents (#{count_all_repos(list)} libraries across #{length(list)} categories)
      </button>
      <div class="collapse" id="collapseExample">
        <div class="card card-body">
          #{rendered_contents}
        </div>
      </div>
    </div>
    """
  end

  def render_list(list) do
    list
    |> Task.async_stream(&render_section/1)
    |> Enum.map(fn {:ok, res} -> res end)
    |> Enum.join("\n")
  end

  defp name_to_id(name) do
    name
    |> String.downcase
    |> String.split(" ", trim: true)
    |> Enum.join("-")
  end

  defp count_all_repos(list) do
    Enum.reduce(list, 0, &(&2 + (&1 |> elem(1) |> elem(1) |> length)))
  end

  defp render_contents_item({name, {_, repos}}) do
    """
    <a class="dropdown-item" href="##{name_to_id(name)}" class="list-group-item list-group-item-action flex-column align-items-start">
      #{name} (#{length(repos)})
    </a>
    """
  end

  defp render_section({name, {desc, repos}}) do
    rendered_repos = repos
    |> Task.async_stream(&render_repo/1)
    |> Enum.map(fn {:ok, res} -> res end)
    |> Enum.join("\n")

    """
    <div class="container text-center mt-3">
      <h4 class="display-4" id="#{name_to_id(name)}">#{name}</h4>
      <div class="lead">#{desc}</div>
      <div class="row justify-content-center">
        #{rendered_repos}
      </div>
      <hr class="row my-4">
    </div>
    """
  end

  defp render_repo({name, {desc, url, stars, date}}) do
    """
    <div class="col-12 col-xl-4 col-lg-6 mb-4">
      <div class="card border-primary h-100">
        <a class="btn btn-link card-header py-0" href="#{url}">
          <h4 class="card-title pt-2">#{name}</h4>
        </a>
        <div class="card-body card-text text-left py-3">
          #{desc}
        </div>
        <div class="card-footer py-2 align-middle">
          <div class="row mx-1 justify-content-between">
            #{date |> days_since_update |> render_days}
            <small>#{stars} ★</small>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_days(0), do: "<small>updated today</small>"
  defp render_days(1), do: "<small>updated yesterday</small>"
  defp render_days(days) when days >= 365, do: "<small class=\"text-danger\">updated #{days} days ago</small>"
  defp render_days(days), do: "<small>updated #{days} days ago</small>"

  defp days_since_update(date) do
    {_, updated_at, _} = DateTime.from_iso8601(date)
    round(DateTime.diff(DateTime.utc_now, updated_at) / 24 / 60 / 60)
  end
end
