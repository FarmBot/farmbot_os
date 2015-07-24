require_relative "fake_logger"
require_relative "fake_serial_port"
require 'farmbot-serial'

class FakeBot < FB::Arduino
  attr_reader :logs, :last_log, :rest_client

  def initialize(serial_port: FakeSerialPort.new, logger: FakeLogger.new)
    @logs = []
    @rest_client = FakeRestClient.new
    super
  end

  def template_variables
    {'anything'  => 'at all',
     'test_mode' => 'this is is used to test templating.',
     'time'      => Time.now}
  end

  def mesh
    @mesh ||= FakeMesh.new
  end

  def status_storage
    @status_storage ||= init_empty_store
  end

  def emit_changes
    {}
  end

private

  def init_empty_store
    # Creates a PStore file and clears out anything that might have been there.
    store = FBPi::StatusStorage.new("spec/fake_bot.pstore")
    store.transaction do |pstore|
        pstore.roots.each { |key| pstore.delete(key) }
      end
    store
  end
end
