pocketknife_puppet
===================

`pocketknife` is a devops tool for managing computers running masterless puppet.

Using `pocketknife`, you create a project that describes the configuration of your computers and then deploy it to bring them to their intended state.

With `pocketknife`, you don't need to setup or manage a specialized `puppet master` node or rely on an unreliable network connection to a distant hosted service whose security you don't control, deal with managing `puppet`'s security keys, or deal with manually synchronizing data with the `puppet master` datastore.

With `pocketknife`, all of your manifests and modules are stored in easy-to-use files that you can edit, share, backup and version control with tools you already have.

pocketknife_puppet is a modification of orginal pocketknife for puppet. 

Usage
-----

Install the software on the machine you'll be running `pocketknife` on, this is a computer that will deploy configurations to other computers:

* Install Ruby: http://www.ruby-lang.org/
* Install Rubygems: http://rubygems.org/
* Install `pocketknife_puppet`: `gem install pocketknife_puppet`

* Update the Repositories to use Puppet version 3 
  For ubuntu version 12 
     wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb
     sudo dpkg -i puppetlabs-release-precise.deb
  For 64 bit Centos or Redhat
    rpm -ivh http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-7.noarch.rpm


Create a new *project*, a special directory that will contain your configuration files. For example, create the `swa` project directory by running:

    pocketknife_puppet --create swa

Go into your new *project* directory:

    cd swa

Create manifests in the `manifests` directory that describe how your computers should be configured.`.

Create modules in the 'modules' directory.`.


Finally, deploy your configuration to the remote machine and see the results. For example, lets deploy the above configuration to the `henrietta.swa.gov.it` host, which can be abbreviated as `henrietta` when calling `pocketknife`:

    pocketknife_puppet henrietta

When deploying a configuration to a node, `pocketknife` will check whether Puppet and its dependencies are installed. It something is missing, it will prompt you for whether you'd like to have it install them automatically.

To always install Puppet and its dependencies when they're needed, without prompts, use the `-i` option, e.g. `pocketknife -i henrietta`. Or to never install Puppet and its dependencies, use the `-I` option, which will cause the program to quit with an error rather than prompting if Puppet or its dependencies aren't installed.

If something goes wrong while deploying the configuration, you can display verbose logging from `pocketknife` and Puppet by using the `-v` option. For example, deploy the configuration to `henrietta` with verbose logging:

    pocketknife_puppet -v henrietta

you can also specify the ssh key following the -k option, a sudo user -s and the manifest to run -m (defaults to init.pp):

   pocketknife_puppet -ivk /repository/keys/my_ssh_key.pem -s  ubuntu -m test.pp 184.63.215.113

Contributing
------------

This software is published as open source at https://github.com/neillturner/pocketknife_puppet

You can view and file issues for this software at https://github.com/neillturner/pocketknife_puppet/issues

If you'd like to contribute code or documentation:

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
* Submit a pull request using github, this makes it easy for me to incorporate your code.

Copyright
---------

Copyright (c) 2011 Igal Koshevoy. See `LICENSE.txt` for further details.
Modifications by Neill Turner (2013). 
