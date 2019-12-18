## FarmBot Source Project structure

The FarmBot OS application is broken into several sub OTP applications. 

* [farmbot_celery_script](/docs/project/farmbot_celery_script.md)
* [farmbot_core](/docs/project/farmbot_core.md)
* [farmbot_ext](/docs/project/farmbot_ext.md)
* [farmbot_firmware](/docs/project/farmbot_firmware.md)
* [farmbot_os](/docs/project/farmbot_os.md)
* [farmbot_telemetry](/docs/project/farmbot_telemetry.md)

## Commonality

All of these folders share a common structure.

<OTP APP ROOT>
├── lib/
│   ├── application.ex
│   └── some_file.ex
|
├── test/
|   └── test_helper.exs
|
├── config/
|   └── config.exs
|
├─── mix.exs
└─── mix.lock

* The `lib` folder contains Elixir source code
* the `test` folder contains Elixir scripts responsible for testing the `lib` code
* the `config` folder contains Elixir scripts responsible for configuring the **current** OTP app
* `mix.exs` and `mix.lock` files are responsible describing the OTP app, and managing external dependencies