# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[spec rubocop]

desc 'Run all available examples'
task :examples do
  examples_dir = File.expand_path('examples', __dir__)
  scripts = Dir[File.join(examples_dir, '*.rb')].sort
  if scripts.empty?
    puts 'No scripts found in examples/'
    next
  end

  scripts.each do |script|
    puts "\n\n=== Running: #{File.basename(script)} ==="
    system({ 'BUNDLE_GEMFILE' => File.expand_path('Gemfile', __dir__) }, RbConfig.ruby, script)
  end
end
