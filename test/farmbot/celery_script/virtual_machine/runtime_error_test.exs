defmodule Farmbot.CeleryScript.VirtualMachine.RuntimeErrorTest do
  @moduledoc "Tests runtime errors."
  
  use ExUnit.Case

  alias Farmbot.CeleryScript.VirtualMachine
  alias VirtualMachine.RuntimeError, as: VmError

  test "raises a runtime error" do
    assert_raise VmError, "runtime error", fn() -> 
     raise VmError, machine: %VirtualMachine{},
                    exception: %RuntimeError{}
    end

    assert_raise VmError, "cool text", fn() -> 
      raise VmError, machine: %VirtualMachine{},
                     exception: %RuntimeError{message: "cool text"}
    end
  end

  test "raises when there is no message or machine supplied" do
    assert_raise ArgumentError, "Machine state was not supplied to #{VmError}.", fn() -> 
      raise VmError, exception: %RuntimeError{}
    end

    assert_raise ArgumentError, "Exception was not supplied to #{VmError}.", fn() -> 
      raise VmError, machine: %VirtualMachine{}
    end
  end
end
