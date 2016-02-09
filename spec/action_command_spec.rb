require 'spec_helper'
require_relative './mocks/mock_logger'
require_relative './test_actions/hello_world_command'
require_relative './test_actions/failing_command'
require_relative './test_actions/internal_test_command'

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
  
  it 'handles a failing command' do
    mock_logger = MockLogger.new
    ActionCommand.logger = mock_logger
    result = ActionCommand.execute_test(self, FailingCommand)
    expect(result).not_to be_ok
    expect(mock_logger.last_info).to eq(FailingCommand::INFO_MSG)
    expect(mock_logger.last_error).to eq(FailingCommand::ERROR_MSG)
  end
  
  it 'allows testing inside commands' do
    expect { ActionCommand.execute_test(self, InternalTestCommand) }.to raise_error(
      RSpec::Expectations::ExpectationNotMetError)
  end
  
  it 'handles rake help case' do
    expect { ActionCommand.execute_rake(HelloWorldCommand, name: 'help') }.to output(
      include(HelloWorldCommand::DESCRIPTION)).to_stdout
  end

  it 'handles rake standard case' do
    result = ActionCommand.execute_rake(HelloWorldCommand, name: 'Chris')
    expect(result).to be_ok
  end

  it 'handles rails standard case' do
    result = ActionCommand.execute_rails(HelloWorldCommand, name: 'Chris')
    expect(result).to be_ok
  end

  it 'handles reversed arguments' do
    expect { ActionCommand.execute_test(InternalTestCommand, self) }.to raise_error(ArgumentError)
    expect(1).to eq(2)
  end
    
  
  
  
end
