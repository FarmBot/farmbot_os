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

  def fake_jwt(), do: @fake_jwt

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

  defmacro expect_log(message) do
    quote do
      expect(FarmbotCore.LogExecutor, :execute, fn log ->
        assert log.message == unquote(message)
      end)
    end
  end

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
