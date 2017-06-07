defmodule Farmbot.HTTP.Multipart do
  @moduledoc """
    Helper for build multipart requests.
  """

  @doc """
    Helper for turning a map into a multipart binary.
  """
  def format(map, boundry) when is_map(map) do
    {file_parts, field_parts} = Enum.partition(map, fn({_key, value}) ->
      match?({_filename, _binary}, value)
    end)

    dbound = "#{dashes()}#{boundry}"
    [
      Enum.map(field_parts, fn({field_name, field_content}) ->
        [
          dbound,
          "Content-Disposition: form-data; name=\"#{field_name}\"",
          "",
          field_content,
        ]
      end),

      Enum.map(file_parts, fn({field_name, {filename, binary}}) ->
        [
          dbound,
          "Content-Disposition: form-data; name=\"#{field_name}\"; filename=\"#{filename}\"",
          "Content-Type: #{content_type(filename)}",
          "",
          binary,
          "",
        ]
      end),
      "#{dbound}--",
      ""
    ] |> List.flatten |> Enum.join("\r\n")
  end

  def new_boundry do
    uuid = Nerves.Lib.UUID.generate()
    <<part_a :: binary - size(8), <<45>>,
      part_b :: binary - size(4), <<45>>,
      part_c :: binary - size(4), <<45>>,
      part_d :: binary - size(4), <<45>>,
      part_e :: binary - size(12)>> = uuid
    [part_a, part_b, part_c, part_d, part_e] |> Enum.shuffle() |> Enum.join()
  end

  def multi_part_header(boundry) do
    {'content-type', 'multipart/form-data; boundary=----------#{boundry}'}
  end

  defp dashes, do: "------------"

  defp content_type(filename) do
    case Path.extname(filename) do
      ".jpg"  -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      _       -> "application/octet-stream"
    end
  end
end
