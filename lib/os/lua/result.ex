defmodule FarmbotOS.Lua.Result do
  require FarmbotOS.Logger

  def new({:ok, value}), do: {:ok, value}
  def new({:error, error, info}), do: parse_error(error, info)

  def new(other) do
    show(other)
    {:error, "Lua error"}
  end

  def parse_error({:badmatch, :the_device_is_estopped}, _) do
    {:error, "Canceled sequence due to emergency lock."}
  end

  def parse_error({:lua_error, {:undefined_function, nil}, lua}, _) do
    {estop, _} = :luerl.get_table(["estop"], lua)

    # If the user tries to move the bot while EStopped,
    # The Lua VM "hides" unsafe functions from the user.
    # This branch condition will make a note of that.
    if estop do
      {:error, "Exiting Lua because device is estopped."}
    else
      {:error, "Tried to call a function/variable that doesn't exist."}
    end
  end

  def parse_error({:lua_error, {:badarg, op, _}, _}, _) when is_atom(op) do
    msg = "Bad argument for '#{op}': Ensure all values are the correct type."
    {:error, msg}
  end

  def parse_error({:badmatch, {:error, list, _}}, _) when is_list(list) do
    {:error, "Lua code is possibly invalid: #{inspect(list)}"}
  end

  def parse_error(:function_clause, _) do
    msg = "Function clause error. Check number of arguments and their types."
    {:error, msg}
  end

  def parse_error({:badmatch, {:error, msg}}, _) when is_binary(msg) do
    {:error, msg}
  end

  def parse_error(error, _) do
    show(error)
    {:error, "Lua failure"}
  end

  def show(error) do
    FarmbotOS.Logger.error(1, String.slice(inspect(error), 0..160))
  end
end
