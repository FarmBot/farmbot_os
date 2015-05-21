require 'spec_helper'

class FakeResonse
  attr_reader :body
  def initialize
    @body = %Q({"uuid":"#{(rand*999).to_s}","token":"#{(rand*999).to_s}"})
  end
end

describe Credentials do
  let(:temp_file) { Tempfile.new('farmbot') }
  let(:cred) { Credentials.new(temp_file) }

  before(:each) do
    allow(Net::HTTP)
      .to(receive(:post_form).and_return(FakeResonse.new, FakeResonse.new))
  end

  it "initializes" do
    expect(cred.uuid).to be_kind_of(String)
    expect(cred.token).to be_kind_of(String)
    expect(Credentials::CREDENTIALS_FILE).to eq('credentials.yml')
    expect(cred.credentials_file).to eq(temp_file)
  end

  it 'creates credentials' do
    old_uuid  = cred.uuid
    old_token = cred.token
    results   = cred.create_credentials
    expectation = {uuid: cred.uuid, token: cred.token}

    expect(old_uuid).not_to eq(cred.uuid)
    expect(old_token).not_to eq(cred.token)
    expect(results).to eq(expectation)
  end

  it 'loads credentials' do
    new_values = {uuid: "ABC", token: "123"}
    tmp = Tempfile.new('farmbot')
    File.open(tmp, 'w+') {|file| file.write(new_values.to_yaml) }
    cred = Credentials.new(tmp)
    result = cred.load_credentials

    expect(result).to eq(new_values)
    expect(cred.uuid).to eq("ABC")
    expect(cred.token).to eq("123")
  end
end
