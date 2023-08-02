defmodule FarmbotOS.API.ImageUploaderTest do
  require Helpers
  use ExUnit.Case
  use Mimic
  alias FarmbotOS.API.ImageUploader
  setup :verify_on_exit!
  setup :set_mimic_global

  # TODO(Rick) This test blinks. 21 OCT 2020
  test "force checkup" do
    pid =
      if Process.whereis(ImageUploader) do
        Process.whereis(ImageUploader)
      else
        {:ok, p} = ImageUploader.start_link([])
        p
      end

    ["a.jpg", "b.jpeg", "c.png", "d.gif"]
    |> Enum.map(fn fname ->
      f = "/tmp/images/#{fname}"
      File.touch!(f)
      File.write(f, "X")
    end)

    expect(FarmbotOS.APIFetcher, :upload_image, 4, fn
      "/tmp/images/d.gif", _meta -> {:error, %{status: 401, body: %{}}}
      _image_filename, _meta -> {:ok, %{status: 201, body: %{}}}
    end)

    err_msg =
      "Upload Error (/tmp/images/d.gif): " <>
        "{:error, %{status: 401, body: %{}}}"

    Helpers.expect_log("Uploaded image: /tmp/images/a.jpg")
    Helpers.expect_log("Uploaded image: /tmp/images/b.jpeg")
    Helpers.expect_log("Uploaded image: /tmp/images/c.png")
    Helpers.expect_log(err_msg)

    ImageUploader.force_checkup()
    send(pid, :timeout)
    Helpers.wait_for(pid)
  end
end
