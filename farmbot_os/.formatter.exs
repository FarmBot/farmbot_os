[
  import_deps: [:ecto],
  inputs: ["*.{ex,exs}", "{config,priv,test}/**/*.{ex,exs}"],
  subdirectories: ["priv/*/migrations"]
]
