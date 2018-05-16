defmodule Farmbot.SystemTest do
  @moduledoc "Tests system functionaity."
  use ExUnit.Case, async: false

  test "does factory reset" do
    Farmbot.System.factory_reset({:error, "hey something bad happened!"})
    last = Farmbot.Test.SystemTasks.fetch_last()
    assert match?({:factory_reset, _}, last)
    {_, msg} = last
    assert msg =~ "hey something bad happened!"
  end

  test "does reboot" do
    Farmbot.System.reboot({:error, "goodbye cruel world!"})
    last = Farmbot.Test.SystemTasks.fetch_last()
    assert match?({:reboot, _}, last)
    {_, msg} = last
    assert msg =~ "goodbye cruel world!"
  end

  test "does shutdown" do
    Farmbot.System.shutdown({:error, "see you soon!"})
    last = Farmbot.Test.SystemTasks.fetch_last()
    assert match?({:shutdown, _}, last)
    {_, msg} = last
    assert msg =~ "see you soon!"
  end

  test "tries to find tokens" do
    token = Farmbot.System.ConfigStorage.get_config_value(:string, "authorization", "token")
    stacktrace = fake_stacktrace(token, self())
    output = Farmbot.System.do_format_reason(stacktrace)
    <<header :: binary-size(36), _rest ::binary>> = token
    assert String.contains?(inspect(stacktrace), header)
    refute String.contains?(inspect(output), header)
  end

  defp fake_stacktrace(token, pid) do
    {{:function_clause,
    [
      {:amqp_gen_connection, :terminate,
       [
         {:function_clause,
          [
            {:inet_dns, :encode_labels,
             [
               token,
               {4,
                {["brisk-bear", "rmq", "cloudamqp", "com", "", "home"], 12, nil,
                 {["rmq", "cloudamqp", "com", "", "home"], 23,
                  {["cloudamqp", "com", "", "home"], 27, nil,
                   {["com", "", "home"], 37, nil, nil}}, nil}}},
               41,
               ["", "home"]
             ], [file: 'inet_dns.erl', line: 694]},
            {:inet_dns, :encode_name, 4, [file: 'inet_dns.erl', line: 675]},
            {:inet_dns, :encode_query_section, 3, [file: 'inet_dns.erl', line: 269]},
            {:inet_dns, :encode, 1, [file: 'inet_dns.erl', line: 240]},
            {:inet_res, :make_query, 5, [file: 'inet_res.erl', line: 670]},
            {:inet_res, :make_query, 4, [file: 'inet_res.erl', line: 638]},
            {:inet_res, :res_query, 6, [file: 'inet_res.erl', line: 622]},
            {:inet_res, :res_getby_query, 4, [file: 'inet_res.erl', line: 589]}
          ]},
         {pid,
          {:amqp_params_network, "device_863", token, "vbzcxsqr",
           'brisk-bear.rmq.cloudamqp.com', 5672, 0, 0, 0, :infinity, :none,
           [&:amqp_auth_mechanisms.plain/3, &:amqp_auth_mechanisms.amqplain/3], [], []}}
       ], [file: 'src/amqp_gen_connection.erl', line: 239]},
      {:gen_server, :try_terminate, 3, [file: 'gen_server.erl', line: 648]},
      {:gen_server, :terminate, 10, [file: 'gen_server.erl', line: 833]},
      {:proc_lib, :init_p_do_apply, 3, [file: 'proc_lib.erl', line: 247]}
    ]}, {:gen_server, :call, [pid, :connect, :infinity]}}
  end
end
