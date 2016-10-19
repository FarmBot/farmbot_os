defmodule Mqtt.Client do
  use Hulaaki.Client
  def on_connect(message: message, state: state) do
    GenServer.call(state.parent, {:connect, message})
  end
  def on_connect_ack(message: message, state: state) do
    GenServer.call(state.parent, {:connect_ack, message})
  end
  def on_publish(message: message, state: state) do
    GenServer.call(state.parent, {:publish, message})
  end
  def on_subscribed_publish(message: message, state: state) do
    GenServer.call(state.parent, {:subscribed_publish, message})
  end
  def on_subscribed_publish_ack(message: message, state: state) do
    GenServer.call(state.parent, {:subscribed_publish_ack, message})
  end
  def on_publish_receive(message: message, state: state) do
    GenServer.call(state.parent, {:publish_receive, message})
  end
  def on_publish_release(message: message, state: state) do
    GenServer.call(state.parent, {:publish_release, message})
  end
  def on_publish_complete(message: message, state: state) do
    GenServer.call(state.parent, {:publish_complete, message})
  end
  def on_publish_ack(message: message, state: state) do
    GenServer.call(state.parent, {:publish_ack, message})
  end
  def on_subscribe(message: message, state: state) do
    GenServer.call(state.parent, {:subscribe, message})
  end
  def on_subscribe_ack(message: message, state: state) do
    GenServer.call(state.parent, {:subscribe_ack, message})
  end
  def on_unsubscribe(message: message, state: state) do
    GenServer.call(state.parent, {:unsubscribe, message})
  end
  def on_unsubscribe_ack(message: message, state: state) do
    GenServer.call(state.parent, {:unsubscribe_ack, message})
  end
  def on_ping(message: message, state: state) do
    GenServer.call(state.parent, {:ping, message})
  end
  def on_pong(message: message, state: state) do
    GenServer.call(state.parent, {:pong, message})
  end
  def on_disconnect(message: message, state: state) do
    GenServer.call(state.parent, {:disconnect, message})
  end
end
