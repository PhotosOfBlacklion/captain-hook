require 'rake'
require 'rake/testtask'

task :default => [:test]

Rake::TestTask.new(:test) do |test|
  test.warning = false
  test.libs << "test"
  test.pattern = 'test/**/*_test.rb'
end

desc 'Generates a coverage report'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['test'].execute
end
