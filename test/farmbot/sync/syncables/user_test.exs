defmodule UserTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "builds a User" do
    u =
      %{
        "id" => 654,
        "device_id" => 654,
        "name" => "name",
        "email" => "email",
        "created_at" => "created_at",
        "updated_at" => "updated_at"}

    {:ok, not_fail} =
      User.create(u)
     assert User.create!(u) == not_fail
     assert not_fail.name == "name"
     assert not_fail.device_id == 654
     assert not_fail.id == 654
     assert not_fail.email == "email"
     assert not_fail.created_at == "created_at"
     assert not_fail.updated_at == "updated_at"
  end

  test "does not build a User" do
    fail = User.create(%{"fake" => "User"})
    also_fail = User.create(:wrong_type)
    assert(fail == {User, :malformed})
    assert(also_fail == {User, :malformed})
  end

  test "raises an exception if invalid" do
    assert_raise RuntimeError, "Malformed #{User} Object", fn ->
      User.create!(%{"fake" => "User"})
    end
  end
end
