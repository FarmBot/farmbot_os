defmodule Farmbot.HTTP.Multipart do
  @moduledoc """
    Helper for build multipart requests.
  """

  @doc """
    Helper for turning a map into a multipart binary.
  """
  def format(map, boundry) when is_map(map) do
    field_parts = Enum.map(map, fn({field_name, field_content}) ->
      formatted = format_field_and_content(boundry, field_name, field_content)
      Enum.join(formatted, "\r\n")
    end)

    stuff = Enum.join(field_parts, "\r\n") <> "\r\n--#{boundry}\r\n"
    require IEx
    IEx.pry
  end

  defp format_field_and_content(boundry, :file, {file_name, content}) do
    [
      "--#{boundry}",
      "Content-Disposition: format-data; name=\"file\"; filename=\"#{file_name}\"",
      # "Content-Type: application/octet-stream",
      "",
      # content,
      "binary_data"
    ]
  end

  defp format_field_and_content(boundry, field_name, field_content) do
    field_content = String.trim(field_content)
    [
      "--#{boundry}",
      "Content-Disposition: form-data; name=\"#{field_name}\"",
      "",
      field_content,
    ]
  end

  def new_boundry do
    uuid = Nerves.Lib.UUID.generate()
    <<part_a :: binary - size(8), <<45>>,
      part_b :: binary - size(4), <<45>>,
      part_c :: binary - size(4), <<45>>,
      part_d :: binary - size(4), <<45>>,
      part_e :: binary - size(12)>> = uuid
    part_a <> part_b <> part_c <> part_d <> part_e
  end

  def multi_part_header(boundry) do
    {'Content-Type', 'multipart/form-data; boundry=#{dashes()}#{boundry}'}
  end

  defp dashes, do: "----------"
end

# format_multipart_formdata(Boundary, Fields, Files) ->
#     FieldParts = lists:map(fun({FieldName, FieldContent}) ->
#                                    [lists:concat(["--", Boundary]),
#                                     lists:concat(["Content-Disposition: form-data; name=\"",atom_to_list(FieldName),"\""]),
#                                     "",
#                                     FieldContent]
#                            end, Fields),
#
#     FieldParts2 = lists:append(FieldParts),
#     FileParts = lists:map(fun({FieldName, FileName, FileContent}) ->
#                                   [lists:concat(["--", Boundary]),
#                                    lists:concat(["Content-Disposition: format-data; name=\"",atom_to_list(FieldName),"\"; filename=\"",FileName,"\""]),
#                                    lists:concat(["Content-Type: ", "application/octet-stream"]),
#                                    "",
#                                    FileContent]
#                           end, Files),
#     FileParts2 = lists:append(FileParts),
#     EndingParts = [lists:concat(["--", Boundary, "--"]), ""],
#     Parts = lists:append([FieldParts2, FileParts2, EndingParts]),
#     string:join(Parts, "\r\n").
#
#
#
# Data = binary_to_list(file:read_file("/path/to/a/file")),
# URL = "http://localhost.com/some/place/",
# Boundary = "------------a450glvjfEoqerAc1p431paQlfDac152cadADfd",
# Body = format_multipart_formdata(Boundary, [{task_id, TaskId}, {position, Position}], [{file, "file", Data}]),
# ContentType = lists:concat(["multipart/form-data; boundary=", Boundary]),
# Headers = [{"Content-Length", integer_to_list(length(Body))}],
# http:request(post, {URL, Headers, ContentType, Body}, [], []).
