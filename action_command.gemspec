# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'action_command/version'

Gem::Specification.new do |spec|
  spec.name          = 'action_command'
  spec.version       = ActionCommand::VERSION
  spec.authors       = ['Chris Jones']
  spec.email         = ['chris@tripletriangle.com']

  spec.summary = '{Reuse code easily in controllers, rake tasks, tests, or outside rails.'
  spec.description = 'Simple implementation of command pattern focused on reuse in'\
     ' multiple contexts'
  spec.homepage      = 'https://github.com/chrisjones-tripletri/action_command'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.37.0'
  spec.add_development_dependency 'simplecov', '~> 0.11'
  spec.add_development_dependency 'codeclimate-test-reporter'
  spec.add_development_dependency 'yard', '~> 0.8'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'terminal-notifier'
  spec.add_development_dependency 'terminal-notifier-guard'
  spec.add_development_dependency 'rake_command_filter'
  spec.add_development_dependency 'activerecord', '~> 4.0.0'
  spec.add_development_dependency 'sqlite3'
end
