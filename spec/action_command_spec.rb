require 'spec_helper'
require 'open3'
require_relative './mocks/mock_logger'
require_relative './mocks/mock_active_record'
require_relative './test_actions/hello_world_command'
require_relative './test_actions/greet_group_command'
require_relative './test_actions/failing_command'
require_relative './test_actions/internal_test_command'

describe ActionCommand do
  
  
  it 'has a version number' do
    expect(ActionCommand::VERSION).not_to be nil
  end
  
  it 'can convert object' do
    mock_ar = MockActiveRecord.new(10)
    # if given an object, it should just return it.    
    expect(ActionCommand::Utils.find_object(MockActiveRecord, mock_ar)).to eq(mock_ar)
    
    # if given an integer id, should use the cls.find method.
    expect(ActionCommand::Utils.find_object(MockActiveRecord, 1).id).to eq(1)
    test_val = 'none'
    
    # if given anything else, should defer to the code block and be passed the value.
    test_search = 'chris@test.com'
    result = ActionCommand::Utils.find_object(MockActiveRecord, test_search) do |p| 
      test_val = p
      MockActiveRecord.new(15)
    end
    expect(test_val).to eq(test_search)
    expect(result.id).to eq(15)
  end

  it 'says hello world' do
    result = ActionCommand.execute_test(self, HelloWorldCommand, name: 'Chris')
    expect(result).to be_ok
    expect(result[:greeting]).to eq('Hello Chris')
  end
  
  it 'flags missing parameters' do
    expect { ActionCommand.execute_test(self, HelloWorldCommand) }.to raise_error(ArgumentError)
  end
  
  it 'flags missing output' do
    expect do 
      ActionCommand.execute_test(self, 
                                 HelloWorldCommand, no_output: true) 
    end.to raise_error(ArgumentError)
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
  end
    
  it 'handles child commands' do
    names = %w(Avon Stringer)
    result = ActionCommand.execute_test(self, GreetGroupCommand, names: names)
    expect(result[0][:greeting]).to eq('Hello Avon')
    expect(result[1][:greeting]).to eq('Hello Stringer')
  end
  
  it 'handles rake task installation' do 
    stdout, _stderr, _stat = Open3.capture3('rake action_command:hello_world[chris]')
    expect(stdout).to match(/greeting:\s+Hello\s+chris/)
  end
      
  it 'handles rake task help' do 
    stdout, _stderr, _stat = Open3.capture3('rake action_command:hello_world[help]')
    expect(stdout).to include('HelloWorldCommand')
    expect(stdout).to include('Say hello to someone')
    expect(stdout).to include('name: Name of')
    expect(stdout).to include('greeting: Greeting for')
    
  end
  
end
