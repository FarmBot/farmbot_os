defmodule Farmbot.CeleryScript.AST.Arg.ElseTest do
  use FarmbotTestSupport.AST.ArgTestCase
  alias Farmbot.CeleryScript.AST
  alias AST.Arg.Else
  
  arg_is_ast(Else)
end
