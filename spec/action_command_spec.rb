require 'spec_helper'
require_relative './test_actions/hello_world_command'

describe ActionCommand do
  
  it 'has a version number' do
    expect(ActionCommand::VERSION).not_to be nil
  end

  it 'says hello world' do
    result = ActionCommand.execute_test(self, HelloWorldCommand, name: 'Chris')
    expect(result).to be_ok
    expect(result[:greeting]).to eq('Hello Chris')
  end
  
  it 'flags missing parameters' do
    expect { ActionCommand.execute_test(self, HelloWorldCommand) }.to raise_error(ArgumentError)
  end
  
end
