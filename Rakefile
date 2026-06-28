require "bundler/gem_helper"
require "rake/testtask"

gem_helper = Bundler::GemHelper.new
class << gem_helper
  def version_tag
    "ruby-sdk-v#{version}"
  end
end
gem_helper.install

Rake::TestTask.new(:test) do |task|
  task.libs << "lib"
  task.libs << "test"
  task.pattern = "test/**/*_test.rb"
end

task default: :test
