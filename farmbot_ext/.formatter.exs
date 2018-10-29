[
  import_deps: [:ecto],
  inputs: ["*.{ex,exs}", "{config,priv,lib,test}/**/*.{ex,exs}"],
  subdirectories: ["priv/*/migrations"]
]
