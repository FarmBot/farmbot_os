# Contributing

**NOTE:** These instructions are for **software developers only.** If you just want to run FarmBot OS on a FarmBot kit you have purchased, please [see these instructions instead](https://software.farm.bot/docs/farmbot-os).

1. Install the [ASDF Package Manager](https://asdf-vm.com/)
2. Install Elixir and Erlang via ASDF. The correct version can be found in the [.tool-versions file](https://github.com/FarmBot/farmbot_os/blob/staging/.tool-versions).
3. [Install Nerves](https://hexdocs.pm/nerves/installation.html#content)
4. Clone this repo and run `./run_all.sh`. If the script runs to completion, you have successfully installed FBOS onto your target
5. Run the application via `iex -S mix`.
