defmodule Farmbot.HTTP.Types do
  @moduledoc """
    Common types for HTTP.
  """

  alias Farmbot.HTTP.Response

  @typedoc "Response object."
  @type response    :: Response.t

  @typedoc "HTTP status code."
  @type status_code :: pos_integer

  @typedoc """
    Key/value represetnation of an HTTP Header
  """
  @type header      :: {char_list, char_list}

  @typedoc """
    HTTP Headers
  """
  @type headers     :: [header]

  @typedoc """
    URL of an HTTP request
  """
  @type url         :: binary | char_list

  @typedoc """
    Verb for http.
  """
  @type http_method :: :get | :post | :put | :patch | :delete

  @typedoc """
    Body of an HTTP Request.
  """
  @type body        :: binary

  @typedoc """
    Tuple representation of a HTTP Request.
  """
  @type request     :: {http_method, url, body, headers}

end
