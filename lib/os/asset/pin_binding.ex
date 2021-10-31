defmodule FarmbotOS.Asset.PinBinding do
  @moduledoc """
  When a pin binding is triggered a sequence fires.
  """
  use FarmbotOS.Asset.Schema, path: "/api/pin_bindings"

  schema "pin_bindings" do
    field(:id, :id)

    has_one(:local_meta, FarmbotOS.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:pin_num, :integer)
    field(:sequence_id, :integer)
    field(:special_action, :string)
    field(:monitor, :boolean, default: true)
    timestamps()
  end

  view pin_binding do
    %{
      id: pin_binding.id,
      pin_num: pin_binding.pin_num,
      sequence_id: pin_binding.sequence_id,
      special_action: pin_binding.special_action
    }
  end

  def changeset(pin_binding, params \\ %{}) do
    pin_binding
    |> cast(params, [
      :id,
      :pin_num,
      :sequence_id,
      :special_action,
      :monitor,
      :created_at,
      :updated_at
    ])
    |> validate_required([])
    |> validate_pin_num()
    |> unique_constraint(:pin_num)
  end

  def validate_pin_num(changeset) do
    if get_field(changeset, :pin_num, -1) in [
         17,
         23,
         27,
         06,
         21,
         24,
         25,
         12,
         13
       ] do
      add_error(changeset, :pin_num, "in use")
    else
      changeset
    end
  end
end

defimpl String.Chars, for: FarmbotOS.Asset.PinBinding do
  def to_string(%FarmbotOS.Asset.PinBinding{
        special_action: action,
        pin_num: 16
      }) do
    special_action(1, action, 16)
  end

  def to_string(%FarmbotOS.Asset.PinBinding{pin_num: 16}) do
    "Button 1: (Pi 16)"
  end

  def to_string(%FarmbotOS.Asset.PinBinding{
        special_action: action,
        pin_num: 22
      }) do
    special_action(2, action, 22)
  end

  def to_string(%FarmbotOS.Asset.PinBinding{pin_num: 22}) do
    "Button 2: (Pi 22)"
  end

  def to_string(%FarmbotOS.Asset.PinBinding{
        special_action: action,
        pin_num: 26
      }) do
    special_action(3, action, 26)
  end

  def to_string(%FarmbotOS.Asset.PinBinding{pin_num: 26}) do
    "Button 3: (Pi 26)"
  end

  def to_string(%FarmbotOS.Asset.PinBinding{
        special_action: action,
        pin_num: 5
      }) do
    special_action(4, action, 5)
  end

  def to_string(%FarmbotOS.Asset.PinBinding{pin_num: 5}) do
    "Button 4: (Pi 5)"
  end

  def to_string(%FarmbotOS.Asset.PinBinding{
        special_action: action,
        pin_num: 20
      }) do
    special_action(5, action, 20)
  end

  def to_string(%FarmbotOS.Asset.PinBinding{pin_num: 20}) do
    "Button 5: (Pi 20)"
  end

  def to_string(%FarmbotOS.Asset.PinBinding{pin_num: num}) do
    "Pi GPIO #{num}"
  end

  defp special_action(button_number, action, pin_num) do
    "Button #{button_number}: #{format_action(action)} (Pi #{pin_num})"
  end

  defp format_action("emergency_lock"), do: "E-Stop"
  defp format_action("emergency_unlock"), do: "E-Unlock"
  defp format_action("power_off"), do: "Power Off"
  defp format_action("read_status"), do: "Read Status"
  defp format_action("reboot"), do: "Reboot"
  defp format_action("sync"), do: "Sync"
  defp format_action("take_photo"), do: "Take Photo"
  defp format_action(_), do: nil
end
