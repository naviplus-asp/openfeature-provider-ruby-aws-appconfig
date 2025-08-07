# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test*.rb"]
  t.warning = false
end

# Unit tests (with mocking)
Rake::TestTask.new(:test_unit) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/openfeature/provider/ruby/aws/test_provider.rb"]
  t.warning = false
end

# Integration tests (with AppConfig Agent)
Rake::TestTask.new(:test_integration) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/openfeature/provider/ruby/aws/integration_test_provider.rb"]
  t.warning = false
end

# All tests
Rake::TestTask.new(:test_all) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test*.rb"]
  t.warning = false
end

task default: :test
