defmodule Farmbot.CeleryScript.AST.Arg.OffsetTest do
  use FarmbotTestSupport.AST.ArgTestCase
  alias Farmbot.CeleryScript.AST
  alias AST.Arg.Offset
  
  arg_is_ast(Offset)
end
