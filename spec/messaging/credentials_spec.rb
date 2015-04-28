require 'spec_helper'

describe Credentials do
  let(:temp_file) { Tempfile.new('farmbot') }
  let(:cred) { Credentials.new(temp_file) }

  before(:each) do
    allow_any_instance_of(Credentials).to receive(:http_post_to_meshblu).and_return(nil)
  end

  it "initializes" do
    uuid_regex = # Ouch!
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

    expect(cred.uuid).to match(uuid_regex)
    expect(cred.token.length).to eq(40)
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
