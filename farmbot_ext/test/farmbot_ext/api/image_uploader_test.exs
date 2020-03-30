defmodule FarmbotExt.API.ImageUploaderTest do
  use ExUnit.Case, async: false
  use Mimic
  alias FarmbotExt.API.ImageUploader
  setup :verify_on_exit!
  setup :set_mimic_global

  # TODO: Get some single pixel jpg, jpeg, png, gif files.
  # TODO: Stub `API.upload_image`

  # upload_image_mock = fn _fname ->
  #   raise "HMMM...."
  # end

  test "force checkup" do
    pid =
      if Process.whereis(ImageUploader) do
        Process.whereis(ImageUploader)
      else
        {:ok, p} = ImageUploader.start_link([])
        p
      end

    # ref = Process.monitor(pid)
    Enum.map(
      ["a.jpg", "b.jpeg", "c.png", "d.gif"],
      fn fname -> File.touch!("/tmp/images/#{fname}") end
    )

    expect(FarmbotExt.API, :upload_image, 1, fn _image_filename, _meta ->
      IO.puts("-=-=--==-=-=-=-=--=-=-==--=-=-=-==-")
      {:ok, %{status: 201, body: %{}}}
    end)

    ImageUploader.force_checkup()
    GenServer.call(pid, :noop)
    send(pid, :timeout)
  end
end
