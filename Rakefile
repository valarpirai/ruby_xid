require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.test_files = FileList['test/**/test_*.rb']
  t.verbose = true
end

desc "Run tests"
task :default => :test

desc "Run simple benchmark"
task :benchmark do
  ruby 'simple_benchmark.rb'
end

desc "Run comparative benchmark (requires bson gem)"
task :benchmark_full do
  ruby '-I', 'lib', 'benchmark.rb'
end

desc "Build and publish gem to RubyGems"
task :publish do
  spec = Gem::Specification.load('ruby_xid.gemspec')
  gem_file = "ruby_xid-#{spec.version}.gem"

  # Clean up old gem files
  sh "rm -f *.gem"

  # Build the gem
  sh "gem build ruby_xid.gemspec"

  # Push to RubyGems
  sh "gem push #{gem_file}"
end
