require 'spec_helper'

describe FBPi::SyncBot do
  let(:bot) { FakeBot.new }
  let(:result) { FBPi::SyncBot.run!(bot: bot) }

  it "Syncs the bot" do
    expect(result[:sequences]).to eq(Sequence.count)
    expect(result[:schedules]).to eq(Schedule.count)
    expect(result[:steps]).to eq(Step.count)
  end

  it "Handles a server outage" do
    allow(bot.rest_client).to receive(:sequences) do
      raise FbResource::FetchError, "Right on schedule, Mr. Carlino."
    end
    sync = FBPi::SyncBot.run(bot: bot)
    expect(sync.errors).to be
    error = sync.errors["web_server"]
    expect(error).to be
    expect(error.message).to include("Right on schedule")
  end
end
