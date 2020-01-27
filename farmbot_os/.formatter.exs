[
  import_deps: [:ecto],
  line_length: 80,
  inputs: [
    "*.{ex,exs}",
    "{config,priv,test}/**/*.{ex,exs}",
    "lib/**/*.{ex,exs}",
    "platform/**/*.{ex,exs}"
  ],
  subdirectories: ["priv/*/migrations"]
]
