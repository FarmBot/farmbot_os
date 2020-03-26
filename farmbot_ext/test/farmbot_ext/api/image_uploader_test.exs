defmodule FarmbotExt.API.ImageUploaderTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotExt.API.ImageUploader
  setup :verify_on_exit!

  test "force checkup" do
    Helpers.NamedProcess.start_link({ImageUploader, "force_checkup_test"})
    # TODO: Get some single pixel jpg, jpeg, png, gif files.
    # TODO: Stub `API.upload_image`

    # upload_image_mock = fn _fname ->
    #   raise "HMMM...."
    # end

    mapper = fn fname ->
      File.touch!("/tmp/images/#{fname}")
    end

    # expect(FarmbotExt.API, :upload_image, 3, upload_image_mock)
    ["a.jpg", "b.jpeg", "c.png", "d.gif"] |> Enum.map(mapper)
    ImageUploader.force_checkup()
    Process.sleep(100)
    assert_receive :lol
  end
end
