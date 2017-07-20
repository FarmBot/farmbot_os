defmodule Farmbot.Behaviour.HTTP do
  @moduledoc """
  HTTP Behaviour
  """
  alias Farmbot.HTTP.{Response}

  @typedoc false
  @type context :: Farmbot.Behaviour.Types.context

  @typedoc "HTTP Method."
  @type method :: :get | :post | :options | :put | :patch | :delete

  @typedoc "HTTP Status code."
  @type status_code :: number

  @typedoc "HTTP Url."
  @type url :: binary

  @typedoc "HTTP Body."
  @type body :: binary | {:multipart, multipart_body}

  @typedoc "Multipart Body for HTTP body."
  @type multipart_body :: [{binary, binary}]

  @typedoc "HTTP Headers."
  @type headers :: [header]

  @typedoc "HTTP Header."
  @type header :: {binary, binary}

  @typedoc "Options to be passed to hackney."
  @type opts :: [opt]

  @typedoc ":hackney opt."
  @type opt :: Keyword.t

  @typedoc "HTTP Response."
  @type response :: Response.t

  @typedoc "HTTP Error reason."
  @type reason :: term

  @typedoc "Normal return situation."
  @type normal_return :: {:ok, response} | {:error, reason}

  @typedoc "Return value for bang functions."
  @type bang_return :: response | no_return

  @doc "Makes an http request."
  @callback request(context, method, url, body, headers, opts) :: normal_return

  @doc "Same as `request/6` but raises Farmbot.HTTP.Error if there is an error."
  @callback request!(context, method, url, body, headers, opts) :: response | no_return

  @doc "Makes a get request."
  @callback get(context, url, body, headers, opts) :: normal_return

  @doc "Same as `get/5` but raises Farmbot.HTTP.Error."
  @callback get!(context, url, body, headers, opts) :: bang_return

  @doc "Makes a post request."
  @callback post(context, url, body, headers, opts) :: normal_return

  @doc "Same as `post/5` but raises Farmbot.HTTP.Error."
  @callback post!(context, url, body, headers, opts) :: bang_return

  @doc "Makes a put request."
  @callback put(context, url, body, headers, opts) :: normal_return

  @doc "Same as `put/5` but raises Farmbot.HTTP.Error."
  @callback put!(context, url, body, headers, opts) :: bang_return

  @doc "Makes a options request."
  @callback options(context, url, body, headers, opts) :: normal_return

  @doc "Same as `options/5` but raises Farmbot.HTTP.Error."
  @callback options!(context, url, body, headers, opts) :: bang_return

  @doc "Makes a delete request."
  @callback delete(context, url, body, headers, opts) :: normal_return

  @doc "Same as `delete/5` but raises Farmbot.HTTP.Error."
  @callback delete!(context, url, body, headers, opts) :: bang_return

  @doc "Makes a patch request."
  @callback patch(context, url, body, headers, opts) :: normal_return

  @doc "Same as `patch/5` but raises Farmbot.HTTP.Error."
  @callback patch!(context, url, body, headers, opts) :: bang_return

  @doc "start_link for OTP"
  @callback start_link(context, GenServer.options) :: GenServer.on_start

  @typedoc "For Farmbot.Context."
  @type http :: GenServer.server

end
