require 'action_command/executable_transaction'
require_relative './child_tx_action'

class CreateUserAction < ActionCommand::ExecutableTransaction
  
  attr_accessor :name, :age, :email
  
  def self.describe_io
    return ActionCommand.describe_io(self, 'Creates a user') do |io|
      io.input(:name, 'Name of user')
      io.input(:age, 'Age of user')
      io.input(:email, 'Email of user')
      io.output(:user, 'User that was created')
    end
  end
  
  protected

  # Say hello to the specified person.
  def execute_internal(result)
    user = User.new
    user.name = @name
    user.age = @age
    user.email = @email
    user.save!
    result.info("Saved user")
    # test here is that the user should not be present in the database, due to the
    # transaction rollback, in this scenario.
    if(age > 120)
      result.failed("Invalid age #{age}")
      return
    end
    
    # execute a child transaction to make sure we don't nest transactions.
    ActionCommand.execute_child(self, ChildTxAction, result, nil)

    result[:user] = user
  end
  
  
end