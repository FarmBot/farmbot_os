defmodule ExCoveralls.SubApps do
  @moduledoc """
  Handles information of sub apps of umbrella projects.
  """

  def find(sub_apps, compile_path) do
    Enum.find(sub_apps, {nil, nil}, fn({_sub_app, path}) ->
      String.starts_with?(compile_path, path)
    end)
  end

  def parse(deps) do
    deps
    |> Enum.map(&({&1.app, &1.opts[:build]}))
    |> Enum.sort(fn ({_app1, build_path1}, {_app2, build_path2}) ->
      # sort the longest paths first to avoid matching a path that contains another
      # example "./apps/myapp_server" would contain path "./apps/myapp"
      String.length(build_path1) > String.length(build_path2)
    end)
  end
end
