[
  import_deps: [:ecto],
  inputs: [
    "*.{ex,exs}",
    "{config,priv,test}/**/*.{ex,exs}",
    "lib/**/*.{ex,exs}",
    "platform/**/*.{ex,exs}"
  ],
  subdirectories: ["priv/*/migrations"]
]
