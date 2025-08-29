# frozen_string_literal: true

require_relative 'lib/gem_template'

Gem::Specification.new do |gem|
  gem.name = GemTemplate::NAME
  gem.version = GemTemplate::VERSION
  gem.authors = ['Matthew Greenfield']
  gem.email = ['mattgreenfield1@gmail.com']

  gem.summary = 'Template for a Ruby gem'
  gem.description = %(
    Has `rakefile.rb` for specs and gems
    Has `bin/console` for interactive testing
    Has `bin/setup` for settings up the development environment
    Has `config.yml` to define gem metadata
    Has several gems that I find useful
  )
  gem.homepage = 'https://github.com/omgreenfield/ruby-gem-template'
  gem.license = 'MIT'

  gem.files = Dir['lib/**/*.rb']
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 3.1.0'

  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'pry-byebug'
  gem.add_development_dependency 'pry-stack_explorer'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rubocop'
end
