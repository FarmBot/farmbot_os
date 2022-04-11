# This is a "kitchen sink" of sorts.
defmodule FarmbotOS.Celery.IntegrationTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.Celery.Compiler
  alias FarmbotOS.Celery.AST
  alias FarmbotOS.Celery.Compiler.Scope

  setup :verify_on_exit!

  @fixtures [
    "test/fixtures/execute.json",
    "fixtures/inner_sequence.json",
    "fixtures/every_sequence.json",
    "fixtures/outer_sequence.json",
    "fixtures/parameter_sequence.json",
    "fixtures/point_group_sequence.json",
    "test/fixtures/mark_variable_meta.json",
    "test/fixtures/mark_variable_removed.json",
    "test/fixtures/set_mounted_tool_id.json",
    "test/fixtures/update_resource_multi.json"
    # "fixtures/unbound.json",
  ]

  test "all the fixtures (should not crash!)" do
    expect(FarmbotOS.Celery.SysCallGlue, :get_sequence, 7, fn _id ->
      compile_celery_file("fixtures/inner_sequence.json")
    end)

    expect(FarmbotOS.Celery.SysCallGlue, :point, 12, fn _type, _id ->
      %{x: 99, y: 88, z: 77}
    end)

    Enum.map(@fixtures, &compile_celery_file/1)
  end

  def compile_celery_file(json_path) do
    json_path
    |> File.read!()
    |> Jason.decode!()
    |> AST.decode()
    |> Compiler.compile(Scope.new())
  end
end
