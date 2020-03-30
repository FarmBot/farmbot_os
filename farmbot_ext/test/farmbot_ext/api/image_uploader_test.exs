defmodule FarmbotExt.API.ImageUploaderTest do
  use ExUnit.Case, async: false
  use Mimic
  alias FarmbotExt.API.ImageUploader
  setup :verify_on_exit!
  setup :set_mimic_global

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

    expect(FarmbotExt.API, :upload_image, 4, fn
      "/tmp/images/d.gif", _meta -> {:ok, %{status: 401, body: %{}}}
      _image_filename, _meta -> {:ok, %{status: 201, body: %{}}}
    end)

    ImageUploader.force_checkup()
    send(pid, :timeout)
    :ok = GenServer.call(pid, :noop)
  end
end
