# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

load './lib/pocketknife/version.rb'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.version = Pocketknife::Version::STRING
  gem.name = "pocketknife"
  gem.homepage = "http://github.com/neillturner/pocketknife_puppet"
  gem.license = "MIT"
  gem.summary = %Q{pocketknife_puppet is a devops tool for managing computers running masterless puppet.}
  gem.description = <<-HERE
pocketknife_puppet is a devops tool for managing computers running masterless puppet.

Using pocketknife, you create a project that describes the configuration of your computers and then deploy it to bring them to their intended state.

With pocketknife, you don't need to setup or manage a specialized puppet master node or rely on an unreliable network connection to a distant hosted service whose security you don't control, deal with managing puppet's security keys, or deal with manually synchronizing data with the puppet-master datastore.

With pocketknife, all of your manifests and modules are stored in easy-to-use files that you can edit, share, backup and version control with tools you already have.

This is modified to work with EC2Dream Fogviz but can also work stand alone. 
  HERE
  gem.email = "igal+pocketknife@pragmaticraft.com"
  gem.authors = ["Igal Koshevoy","Neill Turner"]
  gem.executables += %w[
    pocketknife
  ]
  gem.files += %w[
    Gemfile
    LICENSE.txt
    README.md
    Rakefile
    lib/*
    spec/*
  ]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
