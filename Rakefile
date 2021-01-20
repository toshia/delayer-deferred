require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
  t.warning = true
  t.verbose = true
end

task :benchmark do
  FileList['test/*_benchmark.rb'].each { |f| load f }
end

task :profile do
  FileList['test/*_profiler.rb'].each { |f| load f }
end
