defmodule FarmbotOS.HTTP do
  @moduledoc """
  A very thin wrapper around :httpc and :hackney to facilitate
  mocking and set system-wide default configuration.
  """
  def request(method, params, opts1, opts2) do
    opts_with_default = Keyword.merge(ssl_opts(), opts1)
    :httpc.request(method, params, opts_with_default, opts2)
  end

  def hackney(), do: :hackney

  def ssl_opts,
    do: [
      ssl: [
        verify: :verify_peer,
        cacertfile: :certifi.cacertfile(),
        depth: 10,
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    ]
end
