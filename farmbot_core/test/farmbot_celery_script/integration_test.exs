# This is a "kitchen sink" of sorts.
defmodule FarmbotCore.Celery.IntegrationTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotCore.Celery.Compiler
  alias FarmbotCore.Celery.AST
  alias FarmbotCore.Celery.Compiler.Scope

  setup :verify_on_exit!

  @fixtures [
    "test/fixtures/execute.json",
    "fixture/inner_sequence.json",
    "fixture/every_sequence.json",
    "fixture/outer_sequence.json",
    "fixture/paramater_sequence.json",
    "fixture/point_group_sequence.json",
    "test/fixtures/mark_variable_meta.json",
    "test/fixtures/mark_variable_removed.json",
    "test/fixtures/set_mounted_tool_id.json",
    "test/fixtures/update_resource_multi.json"
    # "fixture/unbound.json",
  ]

  test "all the fixtures (should not crash!)" do
    expect(FarmbotCore.Celery.SysCalls, :get_sequence, 7, fn _id ->
      compile_celery_file("fixture/inner_sequence.json")
    end)

    expect(FarmbotCore.Celery.SysCalls, :point, 12, fn _type, _id ->
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
