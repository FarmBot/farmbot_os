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

  def rest_client
    @rest_client ||= FakeRestClient.new
  end

  def log(message, priority = 'low')
    # TODO: Why aren't we testing the second parameter? We should be.
    super(message)
  end

private

  def init_empty_store
    # Creates a PStore file and clears out anything that might have been there.
    path = "spec/fake_bot.pstore"
    File.delete(path) if File.exist?(path)
    FBPi::StatusStorage.new(path)
  end
end
