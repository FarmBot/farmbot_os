[
  import_deps: [:ecto],
  inputs: [
    "*.{ex,exs}",
    "{config,priv,test}/**/*.{ex,exs}",
    "lib/bot_state/**/*.{ex,exs}",
    "lib/bot_state_ng/**/*.{ex,exs}",
    "lib/asset/**/*.{ex,exs}",
    "lib/asset_workers/**/*.{ex,exs}",
    "lib/farmware_runtime/**/*.{ex,exs}",
    "lib/celery_script/**/*.{ex,exs}",
    "lib/farmware_runtime.ex",
    "lib/asset*.ex",
    "lib/log_storage/**/*.{ex,exs}"
  ],
  subdirectories: ["priv/*/migrations"]
]
