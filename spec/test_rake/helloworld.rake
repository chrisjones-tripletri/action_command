
require 'action_command'
require_relative '../test_actions/hello_world_command'

namespace :action_command do
  

  #----------------------------------------------------------------------------
  ActionCommand.install_rake(self, :hello_world, HelloWorldCommand, [])
  
  
end
