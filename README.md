[![Build Status](https://travis-ci.org/chrisjones-tripletri/action_command.svg?branch=master)](https://travis-ci.org/chrisjones-tripletri/action_command)
[![Test Coverage](https://codeclimate.com/github/chrisjones-tripletri/action_command/badges/coverage.svg)](https://codeclimate.com/github/chrisjones-tripletri/action_command/coverage)
[![Code Climate](https://codeclimate.com/github/chrisjones-tripletri/action_command/badges/gpa.svg)](https://codeclimate.com/github/chrisjones-tripletri/action_command)
[![Inline docs](http://inch-ci.org/github/chrisjones-tripletri/action_command.svg)](http://inch-ci.org/github/chrisjones-tripletri/action_command)

# ActionCommand

This gem is currently in an experimentation phase, and should not be used by others.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'action_command'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install action_command

## Usage

`action_command` is designed to help you centralize logic which might otherwise end up in a controller or model, and easily invoke it from a controller, a test,
or a rake command.  I encountered the idea in the book [Rails 4 Test Prescriptions](http://www.amazon.com/Rails-Test-Prescriptions-Healthy-Codebase/dp/1941222196),
tried it and liked it.

### HelloWorld

You can declare an action with inputs and outputs

```ruby
class HelloWorldCommand < ActionCommand::Executable

  # You need to declare an attr_accessor for each named parameter
  attr_accessor :name

  # You can optional describe the input and output of the command,
  # the text is used to provide help if you create a rake version of the command.
  def self.describe_io
    # the text in here is only
    return ActionCommand.describe_io(self, 'Say hello to someone') do |io|
      io.input(:name, 'Name of person to say hello to')
      io.output(:greeting, 'Greeting for the person')
    end
  end
  
  protected

  # Override the execute internal method to provide logic for your action, and
  # assign results to the result.   You can also use methods like result.fail or 
  # result.info.
  def execute_internal(result)
    result[:greeting] = "Hello #{@name}"
  end
end
```

#### HelloWorld: Execute from Rails

You can execute it from rails:

```ruby
  result = ActionCommand.execute_rails(HelloWorldCommand, { name: 'Chris' })
```

#### HelloWorld: Execute from Rake

When building a system, I find it useful to be able to easily run my actions from 
the command-line as well.  In rails, you can create a lib/tasks/my_task.rake, and
configure your actions as task with one line:

```
namespace :my_namespace do

  # use [:environment] as the last parameter if you want to do things that require
  # rails startup in your command, like connecting to your database.
  ActionCommand.install_rake(self, :hello_world, HelloWorldCommand, [])
  
end
```

You can always invoke your rake task with [help] to see help on the input and output
of the action.  Then 

```
rake  my_namespace:hello_world[help]
```

will produce:

```
HelloWorldCommand: Say hello to someone
  Input: 
    name: Name of person to say hello to
    no_output: If true, intentionally produces no output (optional)
  Output: 
    greeting: Greeting for the person
```    

and 

```
rake my_namespace:hello_world[chris]
```

will produce:

```
greeting: Hello chris
```

#### HelloWorld: Execute from rspec/etc

Or, you can execute it from a testing framework.  

```ruby
  it 'says hello world' do
    result = ActionCommand.execute_test(self, HelloWorldCommand, name: 'Chris')
    expect(result).to be_ok
    expect(result[:greeting]).to eq('Hello Chris')
  end
```

If your command does a lot, you might like to do some internal verifications during the testing process to aid
debugging.   Inside a command's execute_internal method, you can use a block like this:

```ruby
  def execute_internal(result)
    # ... do some logic
    
    # t is the parameter you passed as the first argument to execute_test.  
    # so, if you are using rspec, this code block will only be executed when you are 
    # running in a testing context.
    testing do |t|
      t.expect(my_val).to t.eq(10)
    end
    
  end
```

### Child Actions

Actions can execute their own child actions.  Within an action's execute_internal method
you should call additional actions via:

```ruby
  def execute_internal
    @names.each_with_index do |name, i|
      # the i parameter will cause the result of the child command to be nested
      # in the result under that value.  For example, here I would expect
      # result[i][:greeting] to contain the greeting for each subcommand after
      # execution.
      ActionCommand.execute_child(self, HelloWorldCommand, result, i, name: name)
    end
  end
```

### Error Handling and Logging

#### Error Handling

Within a command, you can generically fail with an error message, or fail with a
particular custom error code

```ruby
  def execute_internal(result)
    # fail generically
    result.failed("Something bad happened")
  
    my_custom_error = 10
    result.failed_with_code("Something bad happened", my_custom_error)
  end
```

You can check for errors in the result:

```ruby
  result = ActionCommand.execute_rails...
  
  return unless result.ok? # generic failure
  
  switch(result.result_code)
  when ActionCommand::RESULT_CODE_OK
    ...
  when my_custom_error
    ...
  end
```

#### Logging

You can turn on logging either globally, or for specific
command executions:

```ruby
  # turn it on globally
  ActionCommand.logger = your_logger
  
  # turn it on only for this command
  params = { 
    logger: your_logger,
    # your other parameters
  }
  ActionCommand.execute_rails(YourCommand, params)
```

When logging is on, the logger will receive single-line JSON messages
at the info level for all command inputs and outputs.  All child
commands under a parent will automatically be tagged with a serial
number for correlation.  The result looks like this:

```
I, [2016-03-07T14:31:53.292843 #47956]  INFO -- : {"sequence":"ade3605e40a4d5bf724c5f3d8e43420b","cmd":"CreateUserAction","depth":0,"kind":"command_input","msg":{"name":"Chris","email":"test@test.com","age":41}}
I, [2016-03-07T14:31:53.293007 #47956]  INFO -- : {"sequence":"ade3605e40a4d5bf724c5f3d8e43420b","cmd":"CreateUserAction","depth":0,"kind":"info","msg":"start_transaction"}
I, [2016-03-07T14:31:53.308212 #47956]  INFO -- : {"sequence":"ade3605e40a4d5bf724c5f3d8e43420b","cmd":"CreateUserAction","depth":0,"kind":"info","msg":"Saved user"}
I, [2016-03-07T14:31:53.308336 #47956]  INFO -- : {"sequence":"ade3605e40a4d5bf724c5f3d8e43420b","cmd":"CreateUserAction","depth":0,"kind":"command_input","msg":{}}
I, [2016-03-07T14:31:53.308442 #47956]  INFO -- : {"sequence":"ade3605e40a4d5bf724c5f3d8e43420b","cmd":"CreateUserAction","depth":0,"kind":"info","msg":"in child transaction"}
I, [2016-03-07T14:31:53.308504 #47956]  INFO -- : {"sequence":"ade3605e40a4d5bf724c5f3d8e43420b","cmd":"CreateUserAction","depth":0,"kind":"command_output","msg":{}}
I, [2016-03-07T14:31:53.308562 #47956]  INFO -- : {"sequence":"ade3605e40a4d5bf724c5f3d8e43420b","cmd":"CreateUserAction","depth":0,"kind":"info","msg":"end_transaction"}
I, [2016-03-07T14:31:53.308837 #47956]  INFO -- : {"sequence":"ade3605e40a4d5bf724c5f3d8e43420b","cmd":"CreateUserAction","depth":0,"kind":"command_output","msg":{"user":{"email":"test@test.com","name":"Chris","age":41}}}
```

You can also optionally add your own entries to the log by calling
`result.debug`, `result.info`, or `result.failed`.   You can pass these calls
a string or a hash.

You can use the included LogParser to parse this log if you like, or you can
use the included PrettyPrintLogAction to print the log in a nested plain text
format, like:

```
  HelloWorldCommand (8d315fe58dab39cb4f23a9f4ef366c8b)
    input:
      name: Chris
    Hello Chris
  output:
    greeting: Hello Chris
```

### ActiveRecord Transactions

You can wrap your command contents in a transaction by subclassing
`ActionCommand::ExecutableTransaction`.  You must explicitly require
`action_command/executable_transaction` to avoid a default dependency
on ActiveRecord.

If you call `result.failed` within a transaction, your transaction will
automatically be rolled back.

### Utilities

It is often useful to allow a single parameter to be either an integer object id,
an instance of the object itself, or a string used to lookup the object (used
in command-line rake tasks).   You can do this using

```ruby
  def execute_internal(result)
    user = ActionCommand::Utils.find_object(User, @user_id) { |p| User.find_by_email(p) }
  end
```

This will user User.find if passed an Integer, will return a user object, or will yield
to the lookup otherwise.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/action_command. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

