defmodule Farmbot.CeleryScript.Command do
  @moduledoc """
    Actionable CeleryScript Commands.
    There should be very little side affects here. just serial commands and
    ways to execute those serial commands.
    this means minimal logging, minimal bot state changeing (if its not the
    result of a gcode) etc.
  """
  require Logger
  alias Farmbot.CeleryScript.Ast

  @doc """
    Executes an ast node.
  """
  @spec do_command(Ast.t) :: :no_instruction | any
  def do_command(%Ast{} = ast) do
    # i wish there was a better way to do this?
    fun_name = String.to_atom(ast.kind)
    if function_exported?(__MODULE__, fun_name, 2) do
      Kernel.apply(__MODULE__, fun_name, [ast.args, ast.body])
    else
      Logger.error ">> has no instruction for #{ast.kind}"
      :no_instruction
    end
  end
end
