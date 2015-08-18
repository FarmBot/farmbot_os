require 'spec_helper'

describe FBPi::BotDecorator do
  let(:status_storage) { FBPi::StatusStorage.new(Tempfile.new('foo').path) }
  let(:mesh) { FakeMesh.new }
  let(:rest) { FakeRestClient.new }
  let(:bot)  { FakeBot.new }
  let(:serial_port) { FakeSerialPort.new }
  let(:decorator) { FBPi::BotDecorator.new(bot) }
  let(:obj) do
    FBPi::BotDecorator.build(status_storage, mesh, rest, FakeBot, serial_port)
  end

  it 'associates the appropriate attributes on instantiation' do
    expect(decorator.__getobj__).to eq(bot)
  end

  it 'builds an object via .build()' do
    expect(obj.__getobj__).to be_kind_of(FakeBot)
    expect(obj.status_storage).to eq(status_storage)
    expect(obj.mesh).to eq(mesh)
    expect(obj.rest_client).to eq(rest)
  end

  it 'bootstraps' do
    allow(FBPi::ColdStart).to receive(:run!)
    obj.bootstrap
    expect(FBPi::ColdStart).to have_received(:run!).exactly(1).times
  end

  it 'reports readiness' do
    obj.ready
    expect(obj.mesh.last.params[:data]).to include("Online at #{Date.today}")
  end

  it 'emits changes' do
    obj.emit_changes
    last_msg = obj.mesh.last.params
    expect(last_msg[:method]).to eq("read_status")
    expect(last_msg[:id]).to be_nil
    expect(last_msg[:params]).to be_kind_of(Hash)
  end

  it 'has templating vars to use in conjunction w/ liquid markup' do
    tmpl = obj.template_variables
    %w( x y z s busy).each do |key|
      expect(tmpl[key]).to be_kind_of(Fixnum)
    end
    expect(tmpl["time"]).to be_kind_of(Time)
    expect(tmpl["pins"]).to be_kind_of(Hash)
  end
end
