# frozen_string_literal: true

require_relative 'lib/class_profiler'

Gem::Specification.new do |gem|
  gem.name = ClassProfiler::NAME
  gem.version = ClassProfiler::VERSION
  gem.authors = ['Matthew Greenfield']
  gem.email = ['mattgreenfield1@gmail.com']

  gem.summary = 'Benchmark speed and profile memory of class methods'
  gem.description = %(
    Quickly benchmark execution time and profile memory allocations for specific
    or all instance methods within a class. Include ClassProfiler to get
    `benchmark_methods` and `profile_methods` helpers and collect results via
    `benchmarked` and `profiled_memory`.
  )
  gem.homepage = 'https://github.com/omgreenfield/class-profiler'
  gem.license = 'MIT'

  gem.files = if File.exist?(File.expand_path('.git'))
                `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^spec/}) }
              else
                Dir['lib/**/*.rb'] + Dir['*.md'] + Dir['LICENSE*']
              end
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 3.1.0'

  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'pry-byebug'
  gem.add_development_dependency 'pry-stack_explorer'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rubocop'
end
