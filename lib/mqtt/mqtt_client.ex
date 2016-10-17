alias Experimental.{GenStage}
defmodule Mqtt.Client do
  use Hulaaki.Client
  def on_connect(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_connect, message}})
  end
  def on_connect_ack(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_connect_ack, message}})
  end
  def on_publish(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_publish, message}})
  end
  def on_subscribed_publish(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_subscribed_publish, message}})
  end
  def on_subscribed_publish_ack(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_subscribed_publish_ack, message}})
  end
  def on_publish_receive(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_publish_receive, message}})
  end
  def on_publish_release(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_publish_release, message}})
  end
  def on_publish_complete(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_publish_complete, message}})
  end
  def on_publish_ack(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_publish_ack, message}})
  end
  def on_subscribe(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_subscribe, message}})
  end
  def on_subscribe_ack(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_subscribe_ack, message}})
  end
  def on_unsubscribe(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_unsubscribe, message}})
  end
  def on_unsubscribe_ack(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_unsubscribe_ack, message}})
  end
  def on_ping(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_ping, message}})
  end
  def on_pong(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_pong, message}})
  end
  def on_disconnect(message: message, state: state) do
    GenStage.call(MqttMessageManager, {:notify, {:on_disconnect, message}})
  end
end
