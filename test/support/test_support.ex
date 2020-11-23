defmodule Helpers do
  alias FarmbotCore.Asset.{Repo, Point}

  @wait_time 180
  @fake_jwt "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZ" <>
              "G1pbkBhZG1pbi5jb20iLCJpYXQiOjE1MDIxMjcxMTcsImp0a" <>
              "SI6IjlhZjY2NzJmLTY5NmEtNDhlMy04ODVkLWJiZjEyZDlhY" <>
              "ThjMiIsImlzcyI6Ii8vbG9jYWxob3N0OjMwMDAiLCJleHAiO" <>
              "jE1MDU1ODMxMTcsIm1xdHQiOiJsb2NhbGhvc3QiLCJvc191c" <>
              "GRhdGVfc2VydmVyIjoiaHR0cHM6Ly9hcGkuZ2l0aHViLmNvb" <>
              "S9yZXBvcy9mYXJtYm90L2Zhcm1ib3Rfb3MvcmVsZWFzZXMvb" <>
              "GF0ZXN0IiwiZndfdXBkYXRlX3NlcnZlciI6Imh0dHBzOi8vY" <>
              "XBpLmdpdGh1Yi5jb20vcmVwb3MvRmFybUJvdC9mYXJtYm90L" <>
              "WFyZHVpbm8tZmlybXdhcmUvcmVsZWFzZXMvbGF0ZXN0IiwiY" <>
              "m90IjoiZGV2aWNlXzE1In0.XidSeTKp01ngtkHzKD_zklMVr" <>
              "9ZUHX-U_VDlwCSmNA8ahOHxkwCtx8a3o_McBWvOYZN8RRzQV" <>
              "LlHJugHq1Vvw2KiUktK_1ABQ4-RuwxOyOBqqc11-6H_GbkM8" <>
              "dyzqRaWDnpTqHzkHGxanoWVTTgGx2i_MZLr8FPZ8prnRdwC1" <>
              "x9zZ6xY7BtMPtHW0ddvMtXU8ZVF4CWJwKSaM0Q2pTxI9GRqr" <>
              "p5Y8UjaKufif7bBPOUbkEHLNOiaux4MQr-OWAC8TrYMyFHzt" <>
              "eXTEVkqw7rved84ogw6EKBSFCVqwRA-NKWLpPMV_q7fRwiEG" <>
              "Wj7R-KZqRweALXuvCLF765E6-ENxA"

  @pub_key "-----BEGIN PUBLIC KEY-----\n" <>
             "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqi880lw9oeNp60qx5Oow\n" <>
             "9czLrvExJSGO6Yic7G+dvoqea9gLT3Xf0x4Iy4TmUfnFT2cJ1I79o/JS6WmfMVdr\n" <>
             "5Z0TaoVWYe9T01+kv6xWY+hENZTemAyCxSyPD7n6BgQYjXVoKSrdIuAoawtozQG+\n" <>
             "5KrS+KnRI70kVO2hgz1NXiEXuHF2Za4umCBONXBdpBSXVq1G5mpF6JURqu7oaTmE\n" <>
             "QNCmXfsJXE2srVwEshg80sb5rRtuoQAF7lAGZ3khV7DzKear5You9BWYNsl6etJZ\n" <>
             "lOSiNeGsDyUEocSIJ9Mn+y8jphJICbBADoKXO3ZkznnJRtLSE5cuh9KVL99LUWAk\n" <>
             "+wIDAQAB\n" <>
             "-----END PUBLIC KEY-----\n" <>
             ""

  @priv_key "-----BEGIN RSA PRIVATE KEY-----\n" <>
              "MIIEpAIBAAKCAQEAqi880lw9oeNp60qx5Oow9czLrvExJSGO6Yic7G+dvoqea9gL\n" <>
              "T3Xf0x4Iy4TmUfnFT2cJ1I79o/JS6WmfMVdr5Z0TaoVWYe9T01+kv6xWY+hENZTe\n" <>
              "mAyCxSyPD7n6BgQYjXVoKSrdIuAoawtozQG+5KrS+KnRI70kVO2hgz1NXiEXuHF2\n" <>
              "Za4umCBONXBdpBSXVq1G5mpF6JURqu7oaTmEQNCmXfsJXE2srVwEshg80sb5rRtu\n" <>
              "oQAF7lAGZ3khV7DzKear5You9BWYNsl6etJZlOSiNeGsDyUEocSIJ9Mn+y8jphJI\n" <>
              "CbBADoKXO3ZkznnJRtLSE5cuh9KVL99LUWAk+wIDAQABAoIBAFczFQsEUGAe0irJ\n" <>
              "fxU4GhYX9VWSKAhKhZuLcDyFhGIZTMsdS85PK3xVK1R8qDbgsATbWuIa0kOq6mjG\n" <>
              "wdbaYGKqdURjRbuwkVcA7r13ZFyUqj56JQPrhSXaiwMX29AxURNKUTCm0eAI0yzm\n" <>
              "D7DbcCBilu7qtEqHo5IQoG1Kf9X2cFYr7ikY8cx0E90RUTZ+P2RCuWskGEKxbUWJ\n" <>
              "epB2BwvxBAJrCSvt3DoXYWNkuxXo32SepqACyqyFPgWImvlz+5CACwrP8fXAhaut\n" <>
              "QbULN+4ltLnl7JQgKKMrGaKOGxvSwLFge9HyNg8ggdIkIjatxOJXLNNLyNgt6fNL\n" <>
              "FuICNSECgYEA4VRl4P3kFcAAIxdlDm0zm5bzegFTidr9QY9r1akzGIKGmT4uOAKX\n" <>
              "vWxQuR2R7LhYXeDW67BIkeYDZd+PW+eH6oVzb2W4MAggu6FeQgCa+uwnp6En13LE\n" <>
              "AX7NdH37h4SmbK4ssQQbb6S5oCuOzBKCVQCPlIRbEnk7MjluZBJfYnUCgYEAwVlP\n" <>
              "KBNL466T+8gKh5mQCXuV1bGKtYlbT/pnmNlz7gfXVPkj+UaBslOmDthEVbGvL4gY\n" <>
              "4T0vhP4VmIz8VqLw+jcCSezv0DjQVXYzZ8l+mNzHkacnnytM4VLQEYQnPB827Mo1\n" <>
              "FF2SjrfciQSyxxg+HOhHVUPovKvExsLtm8tzm68CgYEAl8o25x2hLFWuwfTcip9d\n" <>
              "iI5jbei+0brHqAZpagEU/onPCiQtFmYIuf3hUxJsXr7AKF1x6ktSV5ZO661x8UNC\n" <>
              "9+T2IjCvpwuSoVLPID8wJ6A2BmI1aJlTGH7HAJZtfpkJU2Txjj1qDgc1VISDKU2+\n" <>
              "pmw+TJnsj8FC805k4tzNjJECgYEAsDI+A2xKTStLqjgq+FWFwE6CReHsYPDSaLjt\n" <>
              "7YnErtcwcTw1fzW0fZjjDEYjR+CLoAoreh8zDcQqVAGu9xi3951nlYy5IgyUNj1o\n" <>
              "LR2fI5iWuXIVlmR0RCYefMfspUpg2DqRUoTPSQXekHLapLq/58H5N4eSMVVrFiKP\n" <>
              "O9mU+fsCgYALD10wthhtfYIMvcTaZ0rAF+X0chBvQzj1YaPbEf0YSocLysotcBjT\n" <>
              "M1m91bRjjR9vBhrg5RDOz3RCIlJ3ipkaE+cfxyUs0+AXwIXIPs2hVJNFRT8d7Z4e\n" <>
              "boWHfxAwHFqoEYzskZCdPArDzshm2bFetCh6Cpw7HsWdtS18X8M8+g==\n" <>
              "-----END RSA PRIVATE KEY-----\n" <>
              ""

  def priv_key(), do: @priv_key
  def pub_key(), do: @pub_key
  def fake_jwt(), do: @fake_jwt

  defmacro fake_jwt_object() do
    quote do
      FarmbotExt.JWT.decode!(unquote(@fake_jwt))
    end
  end

  defmacro use_fake_jwt() do
    quote do
      cb = fn :string, "authorization", "token" ->
        Helpers.fake_jwt()
      end

      expect(FarmbotCore.Config, :get_config_value, 1, cb)
    end
  end

  defmacro expect_log(msg) do
    quote do
      message = unquote(msg)
      IO.puts("=== UNSTUB ME " <> message)
      # expect(FarmbotCore.LogExecutor, :execute, fn
      #   %{ message: ^message } -> IO.puts("=== THIS FUNCTION NEEDS TO BE UNSTUBBED PRIOR TO DEPLOY")
      #   _ -> nil
      # end)
    end
  end

  # Base case: We have a pid
  def wait_for(pid) when is_pid(pid), do: check_on_mbox(pid)
  # Failure case: We failed to find a pid for a module.
  def wait_for(nil), do: raise("Attempted to wait on bad module/pid")
  # Edge case: We have a module and need to try finding its pid.
  def wait_for(mod), do: wait_for(Process.whereis(mod))

  # Enter recursive loop
  defp check_on_mbox(pid) do
    Process.sleep(@wait_time)
    wait(pid, Process.info(pid, :message_queue_len))
  end

  # Exit recursive loop (mbox is clear)
  defp wait(_, {:message_queue_len, 0}), do: Process.sleep(@wait_time * 3)
  # Exit recursive loop (pid is dead)
  defp wait(_, nil), do: Process.sleep(@wait_time * 3)

  # Continue recursive loop
  defp wait(pid, {:message_queue_len, _n}), do: check_on_mbox(pid)

  def delete_all_points(), do: Repo.delete_all(Point)

  def create_point(%{id: id} = params) do
    %Point{
      id: id,
      name: "point #{id}",
      meta: %{},
      plant_stage: "planted",
      created_at: ~U[2222-12-10 02:22:22.222222Z],
      pointer_type: "Plant",
      pullout_direction: 2,
      radius: 10.0,
      tool_id: nil,
      discarded_at: nil,
      gantry_mounted: false,
      x: 0.0,
      y: 0.0,
      z: 0.0
    }
    |> Map.merge(params)
    |> Point.changeset()
    |> Repo.insert!()
  end
end
