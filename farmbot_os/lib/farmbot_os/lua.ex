defmodule FarmbotOS.Lua do
  @type t() :: tuple()
  @type table() :: [{any, any}]
  alias FarmbotOS.Lua.CeleryScript

  @doc """
  Evaluates some Lua code. The code should
  return a boolean value.
  """
  def eval_assertion(str) when is_binary(str) do
    init()
    |> set_table([:get_position], &CeleryScript.get_position/2)
    |> set_table([:get_pins], &CeleryScript.get_pins/2)
    |> set_table([:send_message], &CeleryScript.send_message/2)
    |> set_table([:help], &CeleryScript.help/2)
    |> set_table([:version], &CeleryScript.version/2)
    |> eval(str)
    |> case do
      {:ok, [true | _]} ->
        true

      {:ok, [false | _]} ->
        false

      {:ok, [_, reason]} when is_binary(reason) ->
        {:error, reason}

      {:ok, _data} ->
        {:error, "bad return value from expression evaluation"}

      {:error, {:lua_error, _error, _lua}} ->
        {:error, "lua runtime error evaluating expression"}

      {:error, {:badmatch, {:error, [{line, :luerl_parse, parse_error}], _}}} ->
        {:error, "failed to parse expression (line:#{line}): #{IO.iodata_to_binary(parse_error)}"}

      error ->
        error
    end
  end

  @spec init() :: t()
  def init do
    :luerl.init()
  end

  @spec set_table(t(), Path.t(), any()) :: t()
  def set_table(lua, path, value) do
    :luerl.set_table(path, value, lua)
  end

  @spec eval(t(), String.t()) :: {:ok, any()} | {:error, any()}
  def eval(lua, hook) when is_binary(hook) do
    :luerl.eval(hook, lua)
  end
end
