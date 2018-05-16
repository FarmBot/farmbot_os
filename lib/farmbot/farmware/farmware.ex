defmodule Farmbot.Farmware do
  @moduledoc """
  Farmware is Farmbot's plugin system. Developing a farmware is simple.
  You will need 3 things:
    * A `manifest.json` hosted on the internet somewhere.
    * A zip package of your farmware.

  # Prerequisites
  While it is _technically_ possible to use any language to develop a Farmware,
  We currently only actively support Python (with a small set of dependencies.)

  If you want another language/framework, you have a couple options.
  * Ask the Farmbot developers to enable a package.
  * Package the language/framework yourself. (very advanced)

  ## Should *I* develop a Farmware?
  Farmware is not always the correct solution. If you plan on developing a plugin,
  you should ask yourself a few questions.
    * Does my plugin need to be running 24/7 to work?
    * Does my plugin need a realtime interface?
    * Does my plugin need keyboard input?

  If you answered Yes to any of those questions, you should consider, using an
  external plugin. See [a Python example](https://github.com/FarmBot-Labs/FarmBot-Python-Examples)

  # Farmware Manifest
  The `manifest.json` file should contain a number of required fields.
    * `package` - the name of your package. Should be CamelCase by convention.
    * `version` - The version of your package. [Semver](http://semver.org/) is required here.
    * `min_os_version_major` - A version requirement for Farmbot OS.
    * `url` - A url that points to this file.
    * `zip` - A url to the zip package to be downloaded and installed.
    * `executable` - the binary file that will be executed.
    * `args` - An array of strings that will be passed to the `executable`.
    * `config` - A set of default values to be passed to the Farmware.
    see [Configuration](#Configuration) for more details

  There are also a number of metadata fields that are not required, but are
  highly suggested.
    * `author` - The author of this package.
    * `description` - A brief description of the package.
    * `language` - The language that this plugin was developed in.

  # The zip package
  The zip package is simply a zip file that contains all your assets. This
  will usually contain a executable of some sort, and anything required
  to enable the execution of your package.

  # Repositories
  If you have more than one Farmware, and you would like to install all of them
  at one time, it might be worth it to put them in a `repository`. You will need
  to host a special `manifest.json` file that simply contains a list of objects.
  the objects should contain the following keys:
    * `manifest` - This should be a url that points to the package manifest.
    * `name` - the name of the package to install.

  # Developing a Farmware
  Farmwares should be simple script-like programs. They block other access to the
  bot for their lifetime, so they should also be short lived.

  ## Communication
  Since Farmbot can not have two way communication with a Farmware, If you Farmware
  needs to communicate with Farmbot, you will need to use one of:
    * HTTP - [Docs](Farmbot.BotState.Transport.HTTP.html)
      * Easy to work with.
      * Allows call/response type functionality.
      * Requires polling for state updates.
      * No access to logs.
    * Raw Websockets - [Docs](Farmbot.BotState.Transport.HTTP.SocketHandler.html)
      * More difficult to work with.
      * Not exactly call/response.
      * No polling for state updates.
      * Logs come in real time.

  # Configuration
  Since Farmbot and the Farmware can not talk directly, all configuration data
  is sent via Unix Environment Variables.

  *NOTE: All values denoted by a `$` mean they are a environment variable, the
  actual variable name will not contain the `$`.*

  There are two of default configuration's that can not be changed.
    * `$API_TOKEN` - An encoded binary that can be used to communicate with
      Farmbot and it's configured cloud server.
    * `$FARMWARE_URL` - The url to connect your HTTP client too to access Farmbot's REST API.
      *NOTE* This is *_NOT_* the same API as the cloud REST API.
    * `$IMAGES_DIR` - A local directory that will be scanned. Photos left in this
      directory will be uploaded and visable from the web app.

  Additional configuration can be supplied via the manifest. This is handy for
  configurating default values for a Farmware. the `config` field on the manifest
  should be an array of objects with these keys:
    * `name`  - The name of the config.
    * `label` - The label that will show up on the web app.
    * `value` - The default value.

  When your Farmware executes you will have these keys available, but they will
  be namespaced to your Farmware `package` name in snake case.
  For Example, if you have a farmware called "HelloFarmware", and it has a config:
  `{"name": "first_config", "label": "a config field", "value": 100}`, when your
  Farmware executes, it will have a key by the name of `$hello_farmware_first_config`
  that will have the value `100`.

  Config values can however be overwritten by the Farmbot App.

  # More info
  See [Here](https://developer.farm.bot/docs/farmware) for more info.
  """

  defmodule Meta do
    @moduledoc "Metadata about a Farmware."
    defstruct [:author, :language, :description]
  end

  defstruct [
    :name,
    :version,
    :min_os_version_major,
    :url,
    :zip,
    :executable,
    :args,
    :config,
    :farmware_tools_version,
    :meta,
  ]

  defdelegate execute(fw, env), to: Farmbot.Farmware.Runtime

  @doc "Lookup a farmware by it's name."
  def lookup(name) do
    dir = Farmbot.Farmware.Installer.install_root_path
    with {:ok, all_installed} <- File.ls(dir),
         true <- name in all_installed
    do
      mani_path = Path.join(Farmbot.Farmware.Installer.install_path(name), "manifest.json")
      File.read!(mani_path) |> Poison.decode! |> new()
    else
      false -> {:error, :not_installed}
      {:error, _} = err -> err
    end
  end

  @doc "Creates a new Farmware Struct"
  def new(map) do
    with {:ok, name}    <- extract_name(map),
         {:ok, version} <- extract_version(map),
         {:ok, os_req}  <- extract_os_requirement(map),
         {:ok, url}     <- extract_url(map),
         {:ok, zip}     <- extract_zip(map),
         {:ok, exe}     <- extract_exe(map),
         {:ok, args}    <- extract_args(map),
         {:ok, config}  <- extract_config(map),
         {:ok, farmware_tools_version} <- extrace_farmware_tools_version(map),
         {:ok, meta}    <- extract_meta(map)
    do
      res = struct(__MODULE__, [name: name,
                                version: version,
                                min_os_version_major: os_req,
                                url: url,
                                zip: zip,
                                executable: exe,
                                args: args,
                                config: config,
                                farmware_tools_version: farmware_tools_version,
                                meta: meta])
      {:ok, res}
    else
      err -> err
    end
  end

  defp extract_name(%{"package" => name}) when is_binary(name), do: {:ok, name}
  defp extract_name(_), do: {:error, "bad or missing farmware name"}

  defp extract_version(%{"version" => version}) do
    case Version.parse(version) do
      {:ok, _} = res -> res
      :error -> {:error, "Could not parse version."}
    end
  end

  defp extract_version(_), do: {:error, "bad or missing farmware version"}

  defp extract_os_requirement(%{"min_os_version_major" => num}) when is_number(num) do
    {:ok, num}
  end

  defp extract_os_requirement(_), do: {:error, "bad or missing os requirement"}

  defp extract_zip(%{"zip" => zip}) when is_binary(zip), do: {:ok, zip}
  defp extract_zip(_), do: {:error, "bad or missing farmware zip url"}

  defp extract_url(%{"url" => url}) when is_binary(url), do: {:ok, url}
  defp extract_url(_), do: {:error, "bad or missing farmware url"}

  defp extract_exe(%{"executable" => exe}) when is_binary(exe) do
    case System.find_executable(exe) do
      nil -> {:error, "#{exe} is not installed"}
      path -> {:ok, path}
    end
  end

  defp extract_exe(_), do: {:error, "bad or missing farmware executable"}

  defp extract_args(%{"args" => args}) when is_list(args) do
    if Enum.all?(args, &is_binary(&1)) do
      {:ok, args}
    else
      {:error, "invalid args"}
    end
  end

  defp extract_args(_), do: {:error, "bad or missing farmware args"}

  defp extract_config(map) do
    {:ok, Map.get(map, "config", [])}
  end

  defp extrace_farmware_tools_version(%{"farmware_tools_version" => version}) do
    {:ok, version}
  end

  defp extrace_farmware_tools_version(_) do
    {:ok, "v0.1.0"}
  end

  defp extract_meta(map) do
    desc = Map.get(map, "description", "no description provided.")
    lan  = Map.get(map, "language", "no language provided.")
    auth = Map.get(map, "author", "no author provided")
    {:ok, struct(Meta, [description: desc, language: lan, author: auth])}
  end

end
