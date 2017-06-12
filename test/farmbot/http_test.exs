defmodule Farmbot.HTTPTest do
  alias Farmbot.{HTTP, Context}
  use ExUnit.Case, async: false

  test "wont upload if an image doesnt exist" do
    img_path = "#{:code.priv_dir(:farmbot)}/static/fake_farmbot_logo.png"
    assert_raise(HTTP.Error, "#{img_path} not found",
    fn -> HTTP.upload_file!(Context.new(), img_path) end)
  end

end
