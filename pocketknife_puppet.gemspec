# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{pocketknife_puppet}
  s.version = "0.1.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Igal Koshevoy","Neill Turner"]
  s.date = %q{2013-09-26}
  s.description = %q{pocketknife_puppet is a devops tool for managing computers running masterless puppet.

Using pocketknife, you create a project that describes the configuration of your computers and then deploy it to bring them to their intended state.

With pocketknife, you don't need to setup or manage a specialized puppet master node or rely on an unreliable network connection to a distant hosted service whose security you don't control, deal with managing puppet's security keys, or deal with manually synchronizing data with the puppet-master datastore.

With pocketknife, all of your manifests and modules are stored in easy-to-use files that you can edit, share, backup and version control with tools you already have.

This is modified to work with EC2Dream Fogviz but can also work stand alone. 
}
  s.email = %q{neillwturner@gmail.com}
  s.executables = ["pocketknife_puppet", "pocketknife_puppet"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    ".yardopts",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "bin/pocketknife_puppet",
    "lib/pocketknife_puppet.rb",
    "lib/pocketknife_puppet/errors.rb",
    "lib/pocketknife_puppet/node.rb",
    "lib/pocketknife_puppet/node_manager.rb",
    "lib/pocketknife_puppet/version.rb",
    "tar/readme.txt", 
    "tar/tar.exe",
    "pocketknife_puppet.gemspec",
    "spec/pocketknife_execution_error_spec.rb",
    "spec/pocketknife_node_manager_spec.rb",
    "spec/pocketknife_node_spec.rb",
    "spec/pocketknife_spec.rb",
    "spec/spec_helper.rb",
    "spec/support/libraries.rb",
    "spec/support/mkproject.rb"
  ]
  s.homepage = %q{http://github.com/neillturner/pocketknife_puppet}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{pocketknife_puppet is a devops tool for managing computers running puppet.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<archive-tar-minitar>, ["~> 0.5.0"])
      s.add_runtime_dependency(%q<rye>, ["~> 0.9.0"])
      s.add_development_dependency(%q<bluecloth>, ["~> 2.1.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_development_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.0"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<archive-tar-minitar>, ["~> 0.5.0"])
      s.add_dependency(%q<rye>, ["~> 0.9.0"])
      s.add_dependency(%q<bluecloth>, ["~> 2.1.0"])
      s.add_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.0"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<archive-tar-minitar>, ["~> 0.5.0"])
    s.add_dependency(%q<rye>, ["~> 0.9.0"])
    s.add_dependency(%q<bluecloth>, ["~> 2.1.0"])
    s.add_dependency(%q<rspec>, ["~> 2.3.0"])
    s.add_dependency(%q<yard>, ["~> 0.6.0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.0"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end

