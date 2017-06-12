defmodule Farmbot.Test.Helpers do
  alias Farmbot.Database, as: DB

  def login(%Farmbot.Context{} = context) do
    {:ok, auth}   = Farmbot.Auth.start_link(context, [])
    next_context  = %{context | auth: auth}
    final_context = Farmbot.Test.Helpers.Context.replace_http(next_context)
    Farmbot.Auth.interim(auth, "admin@admin.com", "password123", "http://localhost:3000")
    Farmbot.Auth.try_log_in!(context.auth)
    final_context
  end

  def random_file(dir \\ "fixture/api_fixture"),
    do: File.ls!(dir) |> Enum.random

  def read_json(:random) do
     random_file() |> read_json
  end

  def read_json("/" <> file), do: read_json(file)

  def read_json(file) do
    "fixture/api_fixture/#{file}"
    |> File.read!()
    |> Poison.decode!
  end

  def seed_db(context, module, json) do
    tagged = Enum.map(json, fn(item) ->
      tag_item(item, module)
    end)
    :ok = DB.commit_records(tagged, context, module)
  end

  def tag_item(map, tag) do
    updated_map =
      map
      |> Enum.map(fn({key, val}) ->  {String.to_atom(key), val} end)
      |> Map.new()
    struct(tag, updated_map)
  end
end
