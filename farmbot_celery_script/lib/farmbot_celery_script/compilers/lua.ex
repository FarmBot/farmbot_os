defmodule FarmbotCeleryScript.Compiler.Lua do
  alias FarmbotCeleryScript.SysCalls

  def lua(%{args: %{lua: lua}}, _env) do
    quote location: :keep do
      mod = unquote(__MODULE__)
      mod.do_lua(unquote(lua), better_params)
    end
  end

  def do_lua(lua, better_params) do
    extra_variables = [[:variables], better_params]
    args = [lua, [extra_variables]]
    SysCalls.raw_lua_eval(args)
  end
end
