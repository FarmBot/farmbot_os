defmodule FarmbotCore.Celery.Compiler.Farmware do
  alias FarmbotCore.Celery.Compiler

  def take_photo(%{body: params}, cs_scope) do
    execute_script(%{args: %{label: "take-photo"}, body: params}, cs_scope)
  end

  def execute_script(%{args: %{label: package}, body: params}, cs_scope) do
    env =
      Enum.map(params, fn %{args: %{label: key, value: value}} ->
        {to_string(key), value}
      end)

    quote location: :keep do
      package = unquote(Compiler.celery_to_elixir(package, cs_scope))
      env = unquote(Macro.escape(Map.new(env)))
      FarmbotCore.Celery.SysCalls.log(unquote(format_log(package)), true)
      FarmbotCore.Celery.SysCalls.execute_script(package, env)
    end
  end

  def install_first_party_farmware(_, _) do
    quote location: :keep do
      FarmbotCore.Celery.SysCalls.log("Installing dependencies...")
      FarmbotCore.Celery.SysCalls.install_first_party_farmware()
    end
  end

  def set_user_env(%{body: pairs}, _cs_scope) do
    kvs =
      Enum.map(pairs, fn %{kind: :pair, args: %{label: key, value: value}} ->
        quote location: :keep do
          FarmbotCore.Celery.SysCalls.set_user_env(
            unquote(key),
            unquote(value)
          )
        end
      end)

    quote location: :keep do
      (unquote_splicing(kvs))
    end
  end

  def update_farmware(%{args: %{package: package}}, cs_scope) do
    quote location: :keep do
      package = unquote(Compiler.celery_to_elixir(package, cs_scope))
      FarmbotCore.Celery.SysCalls.log("Updating Farmware: #{package}", true)
      FarmbotCore.Celery.SysCalls.update_farmware(package)
    end
  end

  def format_log("camera-calibration"), do: "Calibrating camera"
  def format_log("historical-camera-calibration"), do: "Calibrating camera"
  def format_log("historical-plant-detection"), do: "Running weed detector"
  def format_log("plant-detection"), do: "Running weed detector"
  def format_log("take-photo"), do: "Taking photo"
  def format_log(package), do: "Executing #{package}"
end
