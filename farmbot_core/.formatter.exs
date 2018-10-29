[
  import_deps: [:ecto],
  inputs: [
    "*.{ex,exs}",
    "{config,priv,test}/**/*.{ex,exs}",
    "lib/asset/**/*.{ex,exs}",
    "lib/asset_workers/**/*.{ex,exs}",
    "lib/asset*.ex"
  ],
  subdirectories: ["priv/*/migrations"]
]
