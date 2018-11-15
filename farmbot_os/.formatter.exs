[
  import_deps: [:ecto],
  inputs: [
    "*.{ex,exs}",
    "{config,priv,test}/**/*.{ex,exs}",
    "lib/celery_script/**/*.{ex,exs}",
    "platform/**/*.{ex,exs}"
  ],
  subdirectories: ["priv/*/migrations"]
]
