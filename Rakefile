# frozen_string_literal: true

require "rake/testtask"
require "fileutils"

Rake::TestTask.new do |task|
  task.libs << "lib"
  task.libs << "test"
  task.pattern = "test/**/*_test.rb"
  task.warning = true
end

task default: :test

namespace :typecheck do
  task :rbs do
    sh "bundle exec rbs -I sig validate"
  end

  task :sorbet do
    FileUtils.mkdir_p("tmp")
    sh "bundle exec srb tc --no-config --track-untyped " \
       "--print=file-table-json:tmp/sorbet-file-table.json " \
       "--suppress-error-code 5002 " \
       "rbi/boring_avatars.rbi test/type_contracts/sorbet_contract.rb"
  end

  task :steep do
    sh "bundle exec steep check"
  end
end

task type_coverage: "typecheck:sorbet" do
  ruby "script/check_type_coverage.rb"
end

task typecheck: ["typecheck:rbs", "typecheck:sorbet", "typecheck:steep", :type_coverage]
