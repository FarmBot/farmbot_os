defmodule FarmbotOS.Celery.Compiler.Farmware do
  alias FarmbotOS.Celery.Compiler

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
      FarmbotOS.Celery.SysCallGlue.log(unquote(format_log(package)), true)
      FarmbotOS.Celery.SysCallGlue.execute_script(package, env)
    end
  end

  def set_user_env(%{body: pairs}, _cs_scope) do
    kvs =
      Enum.map(pairs, fn %{kind: :pair, args: %{label: key, value: value}} ->
        quote location: :keep do
          FarmbotOS.Celery.SysCallGlue.set_user_env(
            unquote(key),
            unquote(value)
          )
        end
      end)

    quote location: :keep do
      (unquote_splicing(kvs))
    end
  end

  def format_log("camera-calibration"), do: "Calibrating camera"
  def format_log("historical-camera-calibration"), do: "Calibrating camera"
  def format_log("historical-plant-detection"), do: "Running weed detector"
  def format_log("plant-detection"), do: "Running weed detector"
  def format_log("take-photo"), do: "Taking photo"
  def format_log(package), do: "Executing #{package}"
end
