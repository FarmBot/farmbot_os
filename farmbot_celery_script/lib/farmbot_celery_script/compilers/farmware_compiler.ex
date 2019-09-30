defmodule FarmbotCeleryScript.Compiler.Farmware do
  alias FarmbotCeleryScript.Compiler

  def execute_script(%{args: %{label: package}, body: params}, _env) do
    env =
      Enum.map(params, fn %{args: %{label: key, value: value}} ->
        {to_string(key), value}
      end)

    quote location: :keep do
      package = unquote(Compiler.compile_ast(package, env))
      env = unquote(Macro.escape(Map.new(env)))
      FarmbotCeleryScript.SysCalls.log("Executing Farmware: #{package}", true)
      FarmbotCeleryScript.SysCalls.execute_script(package, env)
    end
  end

  def install_first_party_farmware(_, _env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.log("Installing first party Farmware")
      FarmbotCeleryScript.SysCalls.install_first_party_farmware()
    end
  end

  def set_user_env(%{body: pairs}, _env) do
    kvs =
      Enum.map(pairs, fn %{kind: :pair, args: %{label: key, value: value}} ->
        quote location: :keep do
          FarmbotCeleryScript.SysCalls.set_user_env(unquote(key), unquote(value))
        end
      end)

    quote location: :keep do
      (unquote_splicing(kvs))
    end
  end

  def take_photo(_, _env) do
    # {:execute_script, [], ["take_photo", {:%{}, [], []}]}
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.execute_script("take-photo", %{})
    end
  end

  def update_farmware(%{args: %{package: package}}, env) do
    quote location: :keep do
      package = unquote(Compiler.compile_ast(package, env))
      FarmbotCeleryScript.SysCalls.log("Updating Farmware: #{package}", true)
      FarmbotCeleryScript.SysCalls.update_farmware(package)
    end
  end
end
