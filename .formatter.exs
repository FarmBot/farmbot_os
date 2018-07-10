# Used by "mix format"
known_formatted_files =
  File.read!("formatted_files")
  |> String.split("\n")
  |> Enum.map(&String.trim(&1))
  |> List.delete("")

[inputs: ["mix.exs", ".formatter.exs"] ++ known_formatted_files]
