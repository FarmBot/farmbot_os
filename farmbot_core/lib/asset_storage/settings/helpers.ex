defmodule Farmbot.Asset.Settings.Helpers do
  import Farmbot.Config, only: [update_config_value: 4]
  defmacro bool(kind) do
    quote do
      def apply_kv(unquote(kind), nil = new, old) do
        log(unquote(kind), old, new)
        update_config_value(:bool, "settings", unquote(kind), nil)
      end

      def apply_kv(unquote(kind), new, old) when is_boolean(new) do
        log(unquote(kind), old, new)
        update_config_value(:bool, "settings", unquote(kind), new)
      end
    end
  end

  defmacro string(kind) do
    quote do
      def apply_kv(unquote(kind), nil = new, old) do
        log(unquote(kind), old, new)
        update_config_value(:string, "settings", unquote(kind), nil)
      end

      def apply_kv(unquote(kind), new, old) when is_binary(new) do
        log(unquote(kind), old, new)
        update_config_value(:string, "settings", unquote(kind), new)
      end
    end
  end

  defmacro float(kind) do
    quote do
      def apply_kv(unquote(kind), nil = new, old) do
        log(unquote(kind), old, new)
        update_config_value(:float, "settings", unquote(kind), nil)
      end

      def apply_kv(unquote(kind), new, old) when is_number(new) do
        log(unquote(kind), old, new)
        update_config_value(:float, "settings", unquote(kind), new / 1)
      end
    end
  end

  defmacro fw_float(kind) do
    quote do
      def apply_kv(unquote(kind), nil = new, old) do
        log(unquote(kind), old, new)
        update_config_value(:float, "hardware_params", unquote(kind), nil)
      end

      def apply_kv(unquote(kind), new, old) when is_number(new) do
        log(unquote(kind), old, new)
        update_config_value(:float, "hardware_params", unquote(kind), new / 1)
      end
    end
  end
end
