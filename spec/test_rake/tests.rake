
require 'action_command'
require_relative '../test_actions/hello_world_command'
require_relative '../test_actions/no_parameters_command'

namespace :action_command do
  

  #----------------------------------------------------------------------------
  ActionCommand.install_rake(self, :hello_world, HelloWorldCommand, [])
  ActionCommand.install_rake(self, :no_params, NoParametersCommand, [])
  
end
