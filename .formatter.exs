# Used by "mix format"
known_formatted_files = File.read!("formatted_files")
  |> String.split("\n")
  |> Enum.map(&String.trim())


[
  inputs: ["mix.exs", ".formatter.exs"] ++ known_formatted_files,
  line_length: 80
]
