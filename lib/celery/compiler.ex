defmodule FarmbotOS.Celery.Compiler do
  @moduledoc """
  Responsible for compiling canonical CeleryScript AST into
  Elixir AST.
  """
  require Logger

  alias FarmbotOS.Celery.{AST, Compiler}

  @doc "Returns current debug mode value"
  def debug_mode?() do
    # Set this to `true` when debugging.
    false
  end

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
  fn ->
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
  def compile(%AST{kind: :abort}, _cs_scope) do
    fn -> {:error, "aborted"} end
  end

  # Every @valid_entry_point has its own compiler, but there is some
  # common logic involved in the compilation of both, therefore,
  # we need a common entrypoint for both.
  def compile(%AST{} = ast, cs_scope) do
    if cs_scope.valid do
      ast
      |> celery_to_elixir(cs_scope)
      |> print_compiled_code()
    else
      {:error, "Exiting command because of errors."}
    end
  end

  defdelegate assertion(ast, cs_scope), to: Compiler.Assertion
  defdelegate calibrate(ast, cs_scope), to: Compiler.AxisControl
  defdelegate coordinate(ast, cs_scope), to: Compiler.DataControl
  defdelegate execute_script(ast, cs_scope), to: Compiler.Farmware
  defdelegate execute(ast, cs_scope), to: Compiler.Execute
  defdelegate find_home(ast, cs_scope), to: Compiler.AxisControl
  defdelegate home(ast, cs_scope), to: Compiler.AxisControl
  defdelegate lua(ast, cs_scope), to: Compiler.Lua
  defdelegate move_absolute(ast, cs_scope), to: Compiler.AxisControl
  defdelegate move_relative(ast, cs_scope), to: Compiler.AxisControl
  defdelegate move(ast, cs_scope), to: Compiler.Move
  defdelegate named_pin(ast, cs_scope), to: Compiler.DataControl
  defdelegate point(ast, cs_scope), to: Compiler.DataControl
  defdelegate read_pin(ast, cs_scope), to: Compiler.PinControl
  defdelegate rpc_request(ast, cs_scope), to: Compiler.RPCRequest
  defdelegate sequence(ast, cs_scope), to: Compiler.Sequence
  defdelegate set_pin_io_mode(ast, cs_scope), to: Compiler.PinControl
  defdelegate set_servo_angle(ast, cs_scope), to: Compiler.PinControl
  defdelegate set_user_env(ast, cs_scope), to: Compiler.Farmware
  defdelegate take_photo(ast, cs_scope), to: Compiler.Farmware
  defdelegate toggle_pin(ast, cs_scope), to: Compiler.PinControl
  defdelegate tool(ast, cs_scope), to: Compiler.DataControl
  defdelegate unquote(:_if)(ast, cs_scope), to: Compiler.If
  defdelegate update_resource(ast, cs_scope), to: Compiler.UpdateResource

  # defdelegate variable_declaration(ast, cs_scope), to: Compiler.VariableDeclaration
  defdelegate write_pin(ast, cs_scope), to: Compiler.PinControl
  defdelegate zero(ast, cs_scope), to: Compiler.AxisControl

  def celery_to_elixir(ast_or_literal, _cs_scope)

  def celery_to_elixir(%AST{kind: kind} = ast, cs_scope) do
    if function_exported?(__MODULE__, kind, 2),
      do: apply(__MODULE__, kind, [ast, cs_scope]),
      else: raise("no compiler for #{kind}")
  end

  def celery_to_elixir(lit, _cs_scope) when is_number(lit), do: lit
  def celery_to_elixir(lit, _cs_scope) when is_binary(lit), do: lit

  def nothing(_ast, _cs_scope) do
    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.nothing()
    end
  end

  def abort(_ast, _cs_scope) do
    quote location: :keep do
      Macro.escape({:error, "aborted"})
    end
  end

  def wait(%{args: %{milliseconds: millis}}, cs_scope) do
    quote location: :keep do
      with millis when is_integer(millis) <-
             unquote(celery_to_elixir(millis, cs_scope)) do
        FarmbotOS.Celery.SysCallGlue.log("Waiting for #{millis} milliseconds")
        FarmbotOS.Celery.SysCallGlue.wait(millis)
      else
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  def send_message(args, cs_scope) do
    %{args: %{message: msg, message_type: type}, body: channels} = args
    # body gets turned into a list of atoms.
    # Example:
    #   [{kind: "channel", args: {channel_name: "email"}}]
    # is turned into:
    #   [:email]
    channels =
      Enum.map(channels, fn %{
                              kind: :channel,
                              args: %{channel_name: channel_name}
                            } ->
        String.to_atom(channel_name)
      end)

    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.send_message(
        unquote(celery_to_elixir(type, cs_scope)),
        unquote(celery_to_elixir(msg, cs_scope)),
        unquote(channels)
      )
    end
  end

  def identifier(%{args: %{label: var_name}}, _cs_scope) do
    quote location: :keep do
      {:ok, var} =
        FarmbotOS.Celery.Compiler.Scope.fetch!(cs_scope, unquote(var_name))

      var
    end
  end

  def emergency_lock(_, _cs_scope) do
    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.emergency_lock()
    end
  end

  def emergency_unlock(_, _cs_scope) do
    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.emergency_unlock()
    end
  end

  def read_status(_, _cs_scope) do
    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.read_status()
    end
  end

  def sync(_, _cs_scope) do
    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.sync()
    end
  end

  def check_updates(_, _cs_scope) do
    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.check_update()
    end
  end

  def flash_firmware(%{args: %{package: package_name}}, cs_scope) do
    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.flash_firmware(
        unquote(celery_to_elixir(package_name, cs_scope))
      )
    end
  end

  def power_off(_, _cs_scope) do
    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.power_off()
    end
  end

  def reboot(%{args: %{package: "farmbot_os"}}, _cs_scope) do
    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.reboot()
    end
  end

  def reboot(%{args: %{package: "arduino_firmware"}}, _cs_scope) do
    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.firmware_reboot()
    end
  end

  def factory_reset(%{args: %{package: package}}, cs_scope) do
    quote location: :keep do
      FarmbotOS.Celery.SysCallGlue.factory_reset(
        unquote(celery_to_elixir(package, cs_scope))
      )
    end
  end

  def change_ownership(%{body: body}, cs_scope) do
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
      FarmbotOS.SysCalls.ChangeOwnership.change_ownership(
        unquote(celery_to_elixir(email, cs_scope)),
        unquote(celery_to_elixir(secret, cs_scope)),
        unquote(celery_to_elixir(server, cs_scope))
      )
    end
  end

  # Uncomment these lines if you
  # need to inspect CeleryScript issue
  defp print_compiled_code(compiled) do
    # IO.puts("# === START ===")
    # compiled
    # |> Macro.to_string()
    # |> Code.format_string!()
    # |> IO.puts()
    # IO.puts("# === END ===\n\n")
    compiled
  end
end
