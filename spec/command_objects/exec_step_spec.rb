require 'spec_helper'

describe FBPi::ExecStep do
  let(:bot) { FakeBot.new }

  it "executes send_message" do
    step = Step.new(value: "Hello, world!", message_type: "send_message")
    allow(FBPi::SendMessage)
      .to receive(:run!).with(message: step.value, bot: bot)
    result = FBPi::ExecStep.run!(step: step, bot: bot)
    expect(FBPi::SendMessage).to have_received(:run!)
  end

  it "executes if_statement" do
    seq  = Sequence.create(id_on_web_app: '123')
    step = Step.new(variable:             '1',
                    value:                '2',
                    operator:             '<',
                    sub_sequence_id:      '123',
                    message_type:         'if_statement')
    allow(FBPi::IfStatement).to receive(:run!)
      .with(lhs:      bot.template_variables[step.variable],
            rhs:      step.value,
            operator: step.operator,
            bot:      bot,
            sequence: seq)
    result = FBPi::ExecStep.run!(step: step, bot: bot)
    seq.destroy
    expect(FBPi::IfStatement).to have_received(:run!)
  end

  it "executes read_pin" do
    step = Step.new(pin: '3', message_type: "read_pin")
    allow(FBPi::ReadPin).to receive(:run!).with(pin: step.pin, bot: bot)
    result = FBPi::ExecStep.run!(step: step, bot: bot)
    expect(FBPi::ReadPin).to have_received(:run!)
  end


  it "executes wait()" do
    step   = Step.new(value: 100, message_type: "wait")
    now    = Time.now
    result = FBPi::ExecStep.run!(step: step, bot: bot)
    later  = Time.now
    diff   = later - now
    # 100 ms == .1 seconds
    expect(diff).to be_greater_than(0.1)
  end
end
