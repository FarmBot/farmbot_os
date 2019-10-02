defmodule FarmbotCeleryScript.Compiler do
  @moduledoc """
  Responsible for compiling canonical CeleryScript AST into
  Elixir AST.
  """
  require Logger

  alias FarmbotCeleryScript.{
    AST,
    Compiler,
    Compiler.IdentifierSanitizer
  }

  @doc "Sets debug mode for the compiler"
  def debug_mode(bool \\ true) do
    old = Application.get_env(:farmbot_celery_script, __MODULE__)
    new = Keyword.put(old, :debug, bool)
    Application.put_env(:farmbot_celery_script, __MODULE__, new)
    bool
  end

  @doc "Returns current debug mode value"
  def debug_mode?() do
    Application.get_env(:farmbot_celery_script, __MODULE__)[:debug_mode] || false
  end

  @valid_entry_points [:sequence, :rpc_request]

  @typedoc """
  Compiled CeleryScript node should compile to an anon function.
  Entrypoint nodes such as
  * `rpc_request`
  * `sequence`
  will compile to a function that takes a Keyword list of variables. This function
  needs to be executed before scheduling/executing.

  Non entrypoint nodes compile to a function that symbolizes one individual step.

  ## Examples

  `rpc_request` will be compiled to something like:
  ```
  fn params ->
    [
      # Body of the `rpc_request` compiled in here.
    ]
  end
  ```

  as compared to a "simple" node like `wait` will compile to something like:
  ```
  fn() -> wait(200) end
  ```
  """
  @type compiled :: (Keyword.t() -> [(() -> any())]) | (() -> any())

  @doc """
  Recursive function that will emit Elixir AST from CeleryScript AST.
  """
  @spec compile(AST.t(), Keyword.t()) :: [compiled()]
  def compile(ast, env \\ [])

  def compile(%AST{kind: :abort}, _env) do
    fn -> {:error, "aborted"} end
  end

  def compile(%AST{kind: kind} = ast, env) when kind in @valid_entry_points do
    compile_entry_point(compile_ast(ast, env), env, [])
  end

  def compile_entry_point([{_, new_env, _} = compiled | rest], env, acc) do
    env = Keyword.merge(env, new_env)
    debug_mode?() && print_compiled_code(compiled)
    # entry points must be evaluated once more with the calling `env`
    # to return a list of compiled `steps`

    # TODO: investigate why i have to turn this to a string
    # before eval ing it?
    # case Code.eval_quoted(compiled, [], __ENV__) do
    case Macro.to_string(compiled) |> Code.eval_string(new_env, __ENV__) do
      {fun, new_env} when is_function(fun, 1) ->
        env = Keyword.merge(env, new_env)
        compile_entry_point(rest, env, acc ++ apply(fun, [env]))

      {{:error, error}, _} ->
        {:error, error}
    end
  end

  def compile_entry_point([], _, acc) do
    acc
  end

  defdelegate assertion(ast, env), to: Compiler.Assertion
  defdelegate coordinate(ast, env), to: Compiler.DataControl
  defdelegate execute(ast, env), to: Compiler.Execute
  defdelegate execute_script(ast, env), to: Compiler.Farmware
  defdelegate find_home(ast, env), to: Compiler.AxisControl
  defdelegate unquote(:_if)(ast, env), to: Compiler.If
  defdelegate install_first_party_farmware(ast, env), to: Compiler.Farmware
  defdelegate move_absolute(ast, env), to: Compiler.AxisControl
  defdelegate move_relative(ast, env), to: Compiler.AxisControl
  defdelegate named_pin(ast, env), to: Compiler.DataControl
  defdelegate point(ast, env), to: Compiler.DataControl
  defdelegate read_pin(ast, env), to: Compiler.PinControl
  defdelegate resource_update(ast, env), to: Compiler.DataControl
  defdelegate rpc_request(ast, env), to: Compiler.RPCRequest
  defdelegate sequence(ast, env), to: Compiler.Sequence
  defdelegate set_pin_io_mode(ast, env), to: Compiler.PinControl
  defdelegate set_servo_angle(ast, env), to: Compiler.PinControl
  defdelegate set_user_env(ast, env), to: Compiler.Farmware
  defdelegate take_photo(ast, env), to: Compiler.Farmware
  defdelegate tool(ast, env), to: Compiler.DataControl
  defdelegate toggle_pin(ast, env), to: Compiler.PinControl
  defdelegate update_farmware(ast, env), to: Compiler.Farmware
  defdelegate variable_declaration(ast, env), to: Compiler.VariableDeclaration
  defdelegate write_pin(ast, env), to: Compiler.PinControl
  defdelegate zero(ast, env), to: Compiler.AxisControl

  def compile_ast(ast_or_literal, env)

  def compile_ast(%AST{kind: kind} = ast, env) do
    if function_exported?(__MODULE__, kind, 2),
      do: apply(__MODULE__, kind, [ast, env]),
      else: raise("no compiler for #{kind}")
  end

  def compile_ast(lit, _env) when is_number(lit), do: lit

  def compile_ast(lit, _env) when is_binary(lit), do: lit

  def nothing(_ast, _env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.nothing()
    end
  end

  def abort(_ast, _env) do
    quote location: :keep do
      Macro.escape({:error, "aborted"})
    end
  end

  def wait(%{args: %{milliseconds: millis}}, env) do
    quote location: :keep do
      with millis when is_integer(millis) <- unquote(compile_ast(millis, env)) do
        FarmbotCeleryScript.SysCalls.log("Waiting for #{millis} milliseconds")
        FarmbotCeleryScript.SysCalls.wait(millis)
      else
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  def send_message(%{args: %{message: msg, message_type: type}, body: channels}, env) do
    # body gets turned into a list of atoms.
    # Example:
    #   [{kind: "channel", args: {channel_name: "email"}}]
    # is turned into:
    #   [:email]
    channels =
      Enum.map(channels, fn %{kind: :channel, args: %{channel_name: channel_name}} ->
        String.to_atom(channel_name)
      end)

    quote location: :keep do
      FarmbotCeleryScript.SysCalls.send_message(
        unquote(compile_ast(type, env)),
        unquote(compile_ast(msg, env)),
        unquote(channels)
      )
    end
  end

  # compiles identifier into a variable.
  # We have to use Elixir ast syntax here because
  # var! doesn't work quite the way we want.
  def identifier(%{args: %{label: var_name}}, env) do
    var_name = IdentifierSanitizer.to_variable(var_name)

    quote location: :keep do
      unquote({var_name, env, nil})
    end
  end

  def emergency_lock(_, _env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.emergency_lock()
    end
  end

  def emergency_unlock(_, _env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.emergency_unlock()
    end
  end

  def read_status(_, _env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.read_status()
    end
  end

  def sync(_, _env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.sync()
    end
  end

  def check_updates(_, _env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.check_update()
    end
  end

  def flash_firmware(%{args: %{package: package_name}}, env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.flash_firmware(unquote(compile_ast(package_name, env)))
    end
  end

  def power_off(_, _env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.power_off()
    end
  end

  def reboot(%{args: %{package: "farmbot_os"}}, _env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.reboot()
    end
  end

  def reboot(%{args: %{package: "arduino_firmware"}}, _env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.firmware_reboot()
    end
  end

  def factory_reset(%{args: %{package: package}}, env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.factory_reset(unquote(compile_ast(package, env)))
    end
  end

  def change_ownership(%{body: body}, env) do
    pairs =
      Map.new(body, fn %{args: %{label: label, value: value}} ->
        {label, value}
      end)

    email = Map.fetch!(pairs, "email")

    secret =
      Map.fetch!(pairs, "secret")
      |> Base.decode64!(padding: false, ignore: :whitespace)

    server = Map.get(pairs, "server")

    quote location: :keep do
      FarmbotCeleryScript.SysCalls.change_ownership(
        unquote(compile_ast(email, env)),
        unquote(compile_ast(secret, env)),
        unquote(compile_ast(server, env))
      )
    end
  end

  def dump_info(_, _env) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.dump_info()
    end
  end

  defp print_compiled_code(compiled) do
    IO.puts("========")

    compiled
    |> Macro.to_string()
    |> Code.format_string!()
    |> IO.puts()

    IO.puts("========\n\n")
  end
end
