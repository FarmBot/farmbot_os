defmodule Mimic do
  @moduledoc """
  Mimic is a library that simplifies the usage of mocks in Elixir.

  Mimic is mostly API compatible with [mox](https://hex.pm/packages/mox) but
  doesn't require explicit contract checking with behaviours.  It's also faster.
  You're welcome.

  Mimic works by copying your module out of the way and replacing it with one of
  it's own which can delegate calls back to the original or to a mock function
  as required.

  In order to prepare a module for mocking you must call `copy/1` with the
  module as an argument.  We suggest that you do this in your
  `test/test_helper.exs`:

  ```elixir
  Mimic.copy(Calculator)
  ExUnit.start()
  ```

  Importantly calling `copy/1` will not change the behaviour of the module. When
  writing tests you can then use `stub/3` or `expect/3` to add mocks and
  assertions.

  ## Multi-process collaboration

  Mimic supports multi-process collaboration via two mechanisms:

    1. Explicit allows.
    2. Global mode.

  Using explicit allows is generally preferred as these stubs can be run
  concurrently, whereas global mode tests must be run exclusively.

  ## Explicit allows

  Using `allow/3` you can give other processes permission to use stubs and
  expectations from where they were not defined.

  ```elixir
  test "invokes add from a process" do
    Caculator
    |> expect(:add, fn x, y -> x + y end)

    parent_pid = self()

    spawn_link(fn ->
      Calculator |> allow(parent_pid, self())
      assert Calculator.add(2, 3) == 5

      send parent_pid, :ok
    end)

    assert_receive :ok
  end
  ```

  If you are using `Task` the expectations and stubs are automatically allowed

  ## Global mode

  When set in global mode any process is able to call the stubs and expectations
  defined in your tests.

  **Warning: If using global mode you should remove `async: true` from your tests**

  Enable global mode using `set_mimic_global/1`.

  ```elixir
  setup :set_mimic_global
  setup :verify_on_exit!

  test "invokes add from a task" do
    Calculator
    |> expect(:add, fn x, y -> x + y end)

    Task.async(fn ->
      assert Calculator.add(2, 3) == 5
    end)
    |> Task.await
  end
  ```
  """
  alias ExUnit.Callbacks
  alias Mimic.{Server, VerificationError}

  @doc false
  defmacro __using__(_opts \\ []) do
    quote do
      import Mimic
      setup :verify_on_exit!
    end
  end

  @doc """
  Define a stub function for a copied module.

  ## Arguments:

    * `module` - the name of the module in which we're adding the stub.
    * `function_name` - the name of the function we're stubbing.
    * `function` - the function to use as a replacement.

  ## Raises:

    * If `module` is not copied.
    * If `function_name` is not publicly exported from `module` with the same arity.

  ## Example

      iex> Calculator.add(2, 4)
      6

      iex> Mimic.stub(Calculator, :add, fn x, y -> x * y end)
      ...> Calculator.add(2, 4)
      8

  """
  @spec stub(module(), atom(), function()) :: module
  def stub(module, function_name, function) do
    arity = :erlang.fun_info(function)[:arity]
    raise_if_not_copied!(module)
    raise_if_not_exported_function!(module, function_name, arity)

    module
    |> Server.stub(function_name, arity, function)
    |> validate_server_response(
      "Stub cannot be called by the current process. Only the global owner is allowed."
    )
  end

  @doc """
  Replace all public functions in `module` with stubs.

  The stubbed functions will raise if they are called.

  ## Arguments:

    * `module` - The name of the module to stub.

  ## Raises:

    * If `module` is not copied.
    * If `function` is not called by the stubbing process.

  ## Example

      iex> Mimic.stub(Calculator)
      ...> Calculator.add(2, 4)
      ** (ArgumentError) Module Calculator has not been copied.  See docs for Mimic.copy/1

  """
  @spec stub(module()) :: module()
  def stub(module) do
    raise_if_not_copied!(module)

    module
    |> Server.stub()
    |> validate_server_response(
      "Stub cannot be called by the current process. Only the global owner is allowed."
    )
  end

  @doc """
  Define a stub which must be called within an example.

  This function is almost identical to `stub/3` except that the replacement
  function must be called within the lifetime of the calling `pid` (i.e. the
  test example).

  ## Arguments:

    * `module` - the name of the module in which we're adding the stub.
    * `function_name` - the name of the function we're stubbing.
    * `function` - the function to use as a replacement.

  ## Raises:

    * If `module` is not copied.
    * If `function_name` is not publicly exported from `module` with the same
      arity.
    * If `function` is not called by the stubbing process.

  ## Example

      iex> Calculator.add(2, 4)
      6

      iex> Mimic.expect(Calculator, :add, fn x, y -> x * y end)
      ...> Calculator.add(2, 4)
      8
  """
  @spec expect(atom, atom, non_neg_integer, function) :: module
  def expect(module, fn_name, num_calls \\ 1, func)

  def expect(_module, _fn_name, 0, _func) do
    raise ArgumentError, "Expecting 0 calls should be done through Mimic.reject/1"
  end

  def expect(module, fn_name, num_calls, func)
      when is_atom(module) and is_atom(fn_name) and is_integer(num_calls) and num_calls >= 1 and
             is_function(func) do
    arity = :erlang.fun_info(func)[:arity]
    raise_if_not_copied!(module)
    raise_if_not_exported_function!(module, fn_name, arity)

    module
    |> Server.expect(fn_name, arity, num_calls, func)
    |> validate_server_response(
      "Expect cannot be called by the current process. Only the global owner is allowed."
    )
  end

  @doc """
  Define a stub which must not be called.

  This function allows you do define a stub which must not be called during the
  course of this test.  If it is called then the verification step will raise.

  ## Arguments:

    * `function` - A capture of the function which must not be called.

  ## Raises:

    * If `function` is not called by the stubbing process while calling `verify!/1`.

  ## Example:

      iex> Mimic.reject(&Calculator.add/2)
      Calculator

  """
  @spec reject(function) :: module
  def reject(function) when is_function(function) do
    fun_info = :erlang.fun_info(function)
    arity = fun_info[:arity]
    module = fun_info[:module]
    fn_name = fun_info[:name]
    raise_if_not_copied!(module)
    raise_if_not_exported_function!(module, fn_name, arity)

    module
    |> Server.expect(fn_name, arity, 0, function)
    |> validate_server_response(
      "Reject cannot be called by the current process. Only the global owner is allowed."
    )
  end

  @doc """
  Define a stub which must not be called.

  This function allows you do define a stub which must not be called during the
  course of this test.  If it is called then the verification step will raise.

  ## Arguments:

    * `module` - the name of the module in which we're adding the stub.
    * `function_name` - the name of the function we're stubbing.
    * `arity` - the arity of the function we're stubbing.

  ## Raises:

    * If `function` is not called by the stubbing process while calling `verify!/1`.

  ## Example:

      iex> Mimic.reject(Calculator, :add, 2)
      Calculator

  """
  @spec reject(module, atom, non_neg_integer) :: module
  def reject(module, function_name, arity) do
    raise_if_not_copied!(module)
    raise_if_not_exported_function!(module, function_name, arity)
    func = :erlang.make_fun(module, function_name, arity)

    module
    |> Server.expect(function_name, arity, 0, func)
    |> validate_server_response(
      "Reject cannot be called by the current process. Only the global owner is allowed."
    )
  end

  @doc """
  Allow other processes to share expectations and stubs defined by another
  process.

  ## Arguments:

    * `module` - the copied module.
    * `owner_pid` - the process ID of the process which created the stub.
    * `allowed_pid` - the process ID of the process which should also be allowed
      to use this stub.

  ## Raises:

    * If Mimic is running in global mode.

  Allows other processes to share expectations and stubs defined by another
  process.

  ## Example

  ```elixir
  test "invokes add from a task" do
    Caculator
    |> expect(:add, fn x, y -> x + y end)

    parent_pid = self()

    Task.async(fn ->
      Calculator |> allow(parent_pid, self())
      assert Calculator.add(2, 3) == 5
    end)
    |> Task.await
  end
  ```
  """
  @spec allow(module(), pid(), pid()) :: module() | {:error, atom()}
  def allow(module, owner_pid, allowed_pid) do
    module
    |> Server.allow(owner_pid, allowed_pid)
    |> validate_server_response("Allow must not be called when mode is global.")
  end

  @doc """
  Prepare `module` for mocking.

  ## Arguments:

    * `module` - the name of the module to copy.

  """
  @spec copy(module()) :: :ok
  def copy(module) do
    if not Code.ensure_compiled?(module) do
      raise ArgumentError,
            "Module #{inspect(module)} is not available"
    end

    Mimic.Module.replace!(module)
    ExUnit.after_suite(fn _ -> Server.reset(module) end)

    :ok
  end

  @doc """
  Verifies the current process after it exits.

  If you want to verify expectations for all tests, you can use
  `verify_on_exit!/1` as a setup callback:

  ```elixir
  setup :verify_on_exit!
  ```
  """
  @spec verify_on_exit!(map()) :: :ok | no_return()
  def verify_on_exit!(_context \\ %{}) do
    pid = self()

    Server.verify_on_exit(pid)

    Callbacks.on_exit(Mimic, fn ->
      verify!(pid)
      Server.exit(pid)
    end)
  end

  @doc """
  Sets the mode to private. Mocks can be set and used by the process

  ```elixir
  setup :set_mimic_private
  ```
  """
  @spec set_mimic_private(map()) :: :ok
  def set_mimic_private(_context \\ %{}), do: Server.set_private_mode()

  @doc """
  Sets the mode to global. Mocks can be set and used by all processes

  ```elixir
  setup :set_mimic_global
  ```
  """
  @spec set_mimic_global(map()) :: :ok
  def set_mimic_global(_context \\ %{}), do: Server.set_global_mode(self())

  @doc """
  Chooses the mode based on ExUnit context. If `async` is `true` then
  the mode is private, otherwise global.

  ```elixir
  setup :set_mimic_from_context
  ```
  """
  @spec set_mimic_from_context(map()) :: :ok
  def set_mimic_from_context(%{async: true}), do: set_mimic_private()
  def set_mimic_from_context(_context), do: set_mimic_global()

  @doc """
  Verify if expectations were fulfilled for a process `pid`
  """
  @spec verify!(pid()) :: :ok
  def verify!(pid \\ self()) do
    pending = Server.verify(pid)

    messages =
      for {{module, name, arity}, num_calls, num_applied_calls} <- pending do
        mfa = Exception.format_mfa(module, name, arity)

        "  * expected #{mfa} to be invoked #{num_calls} time(s) " <>
          "but it has been called #{num_applied_calls} time(s)"
      end

    if messages != [] do
      raise VerificationError,
            "error while verifying mocks for #{inspect(pid)}:\n\n" <> Enum.join(messages, "\n")
    end

    :ok
  end

  @doc "Returns the current mode (`:global` or `:private`)"
  @spec mode() :: :private | :global
  def mode do
    Server.get_mode()
    |> validate_server_response("Couldn't get the current mode.")
  end

  defp raise_if_not_copied!(module) do
    unless function_exported?(module, :__mimic_info__, 0) do
      raise ArgumentError,
            "Module #{inspect(module)} has not been copied.  See docs for Mimic.copy/1"
    end
  end

  defp raise_if_not_exported_function!(module, fn_name, arity) do
    unless function_exported?(module, fn_name, arity) do
      raise ArgumentError, "Function #{fn_name}/#{arity} not defined for #{inspect(module)}"
    end
  end

  defp validate_server_response({:ok, module}, _), do: module

  defp validate_server_response({:error, _}, error_message),
    do: raise(ArgumentError, error_message)
end
