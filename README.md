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
the command-line as well.  In rails, you can create a lib/tasks/my_rake.task, and
configure your actions as task with one line:

```
namespace :my_namespace do

  # use [:initialize] as the last parameter if you want to do things that require
  # rails startup in your command, like connecting to your database.
  ActionCommand.install_rake(self, :hello_world, HelloWorldCommand, [])
  
end
```

You can always invoke your rake task with [help] to see help on the input and output
of the action.  Then `rake  my_namespace:hello_world[help]`

will produce:

```
HelloWorldCommand: Say hello to someone
  Input: 
    name: Name of person to say hello to
    no_output: If true, intentionally produces no output (optional)
  Output: 
    greeting: Greeting for the person
```    

and `rake my_namespace:hello_world[chris]`

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/action_command. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

