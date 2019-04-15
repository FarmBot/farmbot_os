defmodule Mix.Tasks.Farmbot.Firmware.Reload do
  use Mix.Task

  @switches [
    app: :keep,
    module: :keep
  ]

  def run(args) do
    {opts, args} = OptionParser.parse!(args, strict: @switches)
    [farmbot_node | _] = args
    farmbot_node = String.to_atom(farmbot_node)

    mods = get_mods(opts)
    {:ok, _} = Node.start(:reload)
    Node.set_cookie(:democookie)
    true = Node.connect(farmbot_node)

    for module <- mods do
      {:ok, [{^farmbot_node, :loaded, ^module}]} = IEx.Helpers.nl([farmbot_node], module)
    end
  end

  defp get_mods(opts) do
    case Keyword.get_values(opts, :module) do
      [_ | _] = mods ->
        Enum.map(mods, fn mod ->
          mod = Module.concat("Elixir", mod)
          Code.ensure_loaded?(mod)
          mod
        end)

      [] ->
        get_apps(opts)
    end
  end

  defp get_apps(opts) do
    apps =
      case Keyword.get_values(opts, :app) do
        [] -> [:farmbot_core, :farmbot_ext, :farmbot]
        [_ | _] = apps -> Enum.map(apps, &String.to_atom/1)
      end

    Enum.reduce(apps, [], fn app, mods ->
      Application.load(app)
      {:ok, more_mods} = :application.get_key(app, :modules)
      mods ++ more_mods
    end)
  end
end
