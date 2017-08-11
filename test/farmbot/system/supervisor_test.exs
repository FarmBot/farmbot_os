defmodule Farmbot.System.SupervisorTest do
  @moduledoc "Tests Init System"
  use ExUnit.Case

  test "initializes all the things" do
    Application.put_env(:farmbot, :init, [
      Farmbot.Test.TestInit
    ])

    {:ok, pid} = Farmbot.System.Supervisor.start_link([], [])
    assert is_pid(pid)
    assert Process.alive?(pid)

    mod_proc = Process.whereis(Farmbot.Test.TestInit)
    assert is_pid(mod_proc)
    assert Process.alive?(mod_proc)

    fun = fn() -> 
      assert true == true
    end

    Farmbot.Test.TestInit.Worker.test_fun(fun)
    Farmbot.Test.TestInit.Worker.exec()
    
  end
end
