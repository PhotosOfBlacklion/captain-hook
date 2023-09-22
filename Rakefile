# frozen_string_literal: true

require "rake"
require "rake/testtask"

task default: [:test]

Rake::TestTask.new(:test) do |test|
  test.warning = false
  test.libs << "test"
  test.pattern = "test/**/*_test.rb"
end
