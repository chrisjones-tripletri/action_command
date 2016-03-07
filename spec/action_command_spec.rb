require 'spec_helper'
require 'open3'
require 'stringio'
require 'byebug'
require_relative './mocks/mock_active_record'
require_relative './test_actions/hello_world_command'
require_relative './test_actions/greet_group_command'
require_relative './test_actions/failing_command'
require_relative './test_actions/fail_with_result_command'
require_relative './test_actions/internal_test_command'
require_relative './test_actions/no_parameters_command'
require_relative './test_actions/parent_with_logging_command'
require_relative './test_actions/create_user_action'

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
    result = ActionCommand.execute_test(self, FailingCommand)
    expect(result).not_to be_ok
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
  
  it 'handles a command with no parameters' do
    stdout, _stderr, _stat = Open3.capture3('rake action_command:no_params')
    expect(stdout).to include('test: test')
  end

  it 'help for a command with no parameters' do
    stdout, _stderr, _stat = Open3.capture3('rake action_command:no_params[help]')
    expect(stdout).to include('NoParametersCommand:')
    expect(stdout).to include('help: Help for')
    expect(stdout).to include('test: Test value')
  end
  
  it 'handles failure with result code' do
    result = ActionCommand.execute_test(self, FailWithResultCommand)
    expect(result).not_to be_ok
    expect(result.result_code).to eq(FailWithResultCommand::CUSTOM_RESULT_CODE)
  end

  def validate_context(rspec, result, api, rails, rake, test, child)
    expect(result).to be_ok
    first = result[0]
    validate_context_result(rspec, first, api, rails, rake, test, child)
  end
  
  def validate_context_result(rspec, first, api, rails, rake, test, child)
    rspec.expect(first[:context_api]).to rspec.be api
    rspec.expect(first[:context_rails]).to rspec.be rails
    rspec.expect(first[:context_rake]).to rspec.be rake
    rspec.expect(first[:context_test]).to rspec.be test
    rspec.expect(first[:context_child]).to rspec.be child
  end
    
  it 'knows its context' do
    names = { names: %w(thing1 thing2) }
    result = ActionCommand.execute_api(GreetGroupCommand, names)
    validate_context(self, result, true, false, false, false, true)

    result = ActionCommand.execute_rails(GreetGroupCommand, names)
    validate_context(self, result, false, true, false, false, true)

    result = ActionCommand.execute_rake(GreetGroupCommand, names)
    validate_context(self, result, false, false, true, false, true)

    result = ActionCommand.execute_test(self, GreetGroupCommand, names)
    validate_context(self, result, false, false, false, true, true)

    result = ActionCommand.execute_test(self, HelloWorldCommand, name: 'Chris')
    validate_context_result(self, result, false, false, false, true, false)
  end    
  
  def validate_log_message(r, log, item, sequence, cmd, kind, msg, key = nil)
    r.expect(log.next(item)).to r.be true
    r.expect(item.sequence).to r.eq(sequence)
    r.expect(item.command?(cmd)).to r.be true
    r.expect(item.kind?(kind)).to r.be true
    r.expect(item.match_message?(msg)).to r.be true
    r.expect(item.key?(key)).to r.be true if key
  end
  
  it 'logs from within command' do
    strio  = StringIO.new
    logger = Logger.new(strio)
    result = ActionCommand.execute_test(self, ParentWithLoggingCommand, test_in: 'Hello', logger: logger)
    # puts strio.string
    
    strio.seek(0)
    msg = ActionCommand::LogMessage.new
    log = ActionCommand::LogParser.new(strio)
    seq = result.sequence

    validate_log_message(self, log, msg, seq, ParentWithLoggingCommand, ActionCommand::LOG_KIND_COMMAND_INPUT, test_in: 'Hello')
    validate_log_message(self, log, msg, seq, ParentWithLoggingCommand, ActionCommand::LOG_KIND_INFO, ParentWithLoggingCommand::TEST_INFO_STRING)
    validate_log_message(self, log, msg, seq, ParentWithLoggingCommand, ActionCommand::LOG_KIND_DEBUG, ParentWithLoggingCommand::TEST_DEBUG_STRING)
    validate_log_message(self, log, msg, seq, HelloWorldCommand, ActionCommand::LOG_KIND_COMMAND_INPUT, { name: 'Chris' }, 1)
    validate_log_message(self, log, msg, seq, HelloWorldCommand, ActionCommand::LOG_KIND_INFO, 'Hello Chris', 1)
    validate_log_message(self, log, msg, seq, HelloWorldCommand, ActionCommand::LOG_KIND_COMMAND_OUTPUT, {
                           greeting: 'Hello Chris',
                           context_api: false,
                           context_test: true,
                           context_child: true
                         }, 1)
    validate_log_message(self, log, msg, seq, ParentWithLoggingCommand, ActionCommand::LOG_KIND_COMMAND_OUTPUT, test_out: ParentWithLoggingCommand::TEST_OUTPUT)
    
    # go back to the end, and pretty print it.
    strio.seek(0)
    strpretty = StringIO.new
    result = ActionCommand.execute_test(self, ActionCommand::PrettyPrintLogAction, source: strio, dest: strpretty)
    pretty = strpretty.string
    # puts pretty
    expect(pretty).to include('ParentWithLoggingCommand')
    expect(pretty).to include('HelloWorldCommand')
    expect(pretty).to include('greeting: Hello Chris')
    expect(pretty).to include('name: Chris')
  end
  
  it 'commits a successful transaction' do
    email = 'test@test.com'
    strio  = StringIO.new
    logger = Logger.new(strio)
    result = ActionCommand.execute_test(self, CreateUserAction, name: 'Chris', email: email, age: 41, logger: logger)
    expect(result).to be_ok
    created = result[:user]
    puts strio.string
    
    user = User.find_by_email(email)
    expect(user).not_to be_nil
    expect(user.id).to eq(created.id)
    expect(user.email).to eq(email)
  end
  
  it 'rolls back a failed transaction' do
    email = 'test2@test.com'
    strio  = StringIO.new
    logger = Logger.new(strio)
    result = ActionCommand.execute_test(self, CreateUserAction, name: 'Chris', email: email, age: 150, logger: logger)
    expect(result).not_to be_ok
    
    user = User.find_by_email(email)
    expect(user).to be_nil
    
  end
end
