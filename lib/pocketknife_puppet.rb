# Standard libraries
require "pathname"
require "fileutils"

# Gem libraries
require "archive/tar/minitar"
require "rye"

# Related libraries
require "pocketknife_puppet/errors"
require "pocketknife_puppet/node"
require "pocketknife_puppet/node_manager"
require "pocketknife_puppet/version"

# = Pocketknife_puppet
#
# == About
#
# Pocketknife_puppet is a devops tool for managing computers running <tt>chef-solo</tt>. Using Pocketknife, you create a project that describes the configuration of your computers and then apply it to bring them to the intended state.
#
# For information on using the +pocketknife+ tool, please see the {file:README.md README.md} file. The rest of this documentation is intended for those writing code using the Pocketknife API.
#
# == Important methods
#
# * {cli} runs the command-line interpreter, whichi in turn executes the methods below.
# * {#initialize} creates a new Pocketknife instance.
# * {#create} creates a new project.
# * {#deploy} deploys configurations to nodes, which uploads and applies.
# * {#upload} uploads configurations to nodes.
# * {#apply} applies existing configurations to nodes.
# * {#node} finds a node to upload or apply configurations.
#
# == Important classes
#
# * {Pocketknife::Node} describes how to upload and apply configurations to nodes, which are remote computers.
# * {Pocketknife::NodeManager} finds, checks and manages nodes.
# * {Pocketknife::NodeError} describes errors encountered when using nodes.
class Pocketknife_puppet
  # Runs the interpreter using arguments provided by the command-line. Run <tt>pocketknife -h</tt> or review the code below to see what command-line arguments are accepted.
  #
  # Example:
  #   # Display command-line help:
  #   Pocketknife.cli('-h')
  #
  # @param [Array<String>] args A list of arguments from the command-line, which may include options (e.g. <tt>-h</tt>).
  def self.cli(args)
    pocketknife_puppet = Pocketknife_puppet.new

    OptionParser.new do |parser|
      parser.banner = <<-HERE
USAGE: pocketknife_puppet [options] [nodes]

EXAMPLES:
  # Create a new project called PROJECT
  pocketknife_puppet -c PROJECT

  # Apply configuration to a node called NODE
  pocketknife_puppet NODE

OPTIONS:
      HERE

      options = {}

      parser.on("-c", "--create PROJECT", "Create project") do |name|
        pocketknife_puppet.create(name)
        return
      end

      parser.on("-V", "--version", "Display version number") do |name|
        puts "Pocketknife_puppet #{Pocketknife_puppet::Version::STRING}"
        return
      end

      parser.on("-v", "--verbose", "Display detailed status information") do |name|
        pocketknife_puppet.verbosity = true
      end

      parser.on("-q", "--quiet", "Display minimal status information") do |v|
        pocketknife_puppet.verbosity = false
      end
      
      parser.on("-s", "--sudo USER", "Run under non-root users with sudo") do |name|
        options[:sudo] = true
        pocketknife_puppet.user = name
      end
	  
	  parser.on("-t", "--sudopassword PASSWORD", "password of sudo user") do |name|
        options[:sudo_password] = true
        pocketknife_puppet.sudo_password = name
      end
	  
	  parser.on("-p", "--password PASSWORD", "password of user if not using ssh keys") do |name|
        options[:password] = true
        pocketknife_puppet.password = name
      end
      
      parser.on("-k", "--sshkey SSHKEY", "Use an ssh key") do |name|
        options[:ssh_key] = name
        pocketknife_puppet.ssh_key = name
      end

	  parser.on("-n", "--nodeleterepo", "don't delete the puppet repository after the run") do |v|
        options[:nodeleterepo] = true
		pocketknife_puppet.nodeleterepo = true
      end
	  
	  parser.on("-z", "--noupdatepackages", "don't update the packages before running puppet") do |v|
        options[:noupdatepackages] = true
		pocketknife_puppet.noupdatepackages = true
      end	  
	  
      parser.on("-u", "--upload", "Upload configuration, but don't apply it") do |v|
        options[:upload] = true
      end

      parser.on("-a", "--apply", "Runs puppet to apply already-uploaded configuration") do |v|
        options[:apply] = true
      end

      parser.on("-i", "--install", "Install Puppet automatically") do |v|
        pocketknife_puppet.can_install = true
      end

      parser.on("-I", "--noinstall", "Don't install Puppet automatically") do |v|
        pocketknife_puppet.can_install = false
      end
      
      parser.on("-m", "--manifest MANIFEST", "Puppet manifest defaults to init.pp") do |name|
        options[:manifest] = name
        pocketknife_puppet.manifest = name
      end
	  
	  parser.on("-x", "--xoptions OPTIONS", "Extra options for puppet apply like --noop") do |name|
        options[:xoptions] = name
        pocketknife_puppet.xoptions = name
      end
      
	  parser.on("-e", "--hiera_config MANIFEST", "hiera config file in hieradata directory") do |name|
        options[:hiera_config] = name
        pocketknife_puppet.hiera_config = name
      end
	  
      #parser.on("-j", "--chefversion CHEF_VERSION", "install a paticular chef version") do |name|
      #        options[:chef_version] = name
      #        pocketknife.chef_version = name
      #end
      parser.on("-f", "--facts fact1=aaa,fact2=bbb", "set the puppet facts before running puppet apply") do |name|
              options[:facts] = name
              pocketknife_puppet.facts = name
      end  
      
      parser.on("-l", "--localport LOCAL_PORT", "use a local port to access an ssh tunnel") do |name|
              options[:local_port] = name
              pocketknife_puppet.local_port = name
      end            

      begin
        arguments = parser.parse!
      rescue OptionParser::MissingArgument => e
        puts parser
        puts
        puts "ERROR: #{e}"
        exit -1
      end

      nodes = arguments

      if nodes.empty?
        puts parser
        puts
        puts "ERROR: No nodes specified."
        exit -1
      end

      begin
        if options[:upload]
          pocketknife_puppet.upload(nodes)
        end

        if options[:apply]
          pocketknife_puppet.apply(nodes)
        end

        if not options[:upload] and not options[:apply]
          pocketknife_puppet.deploy(nodes)
        end
      rescue NodeError => e
        puts "! #{e.node}: #{e}"
        exit -1
      end
    end
  end

  # Returns the software's version.
  #
  # @return [String] A version string.
  def self.version
    return "0.1.11"
  end

  # Amount of detail to display? true means verbose, nil means normal, false means quiet.
  attr_accessor :verbosity
  
  # key for ssh access.
  attr_accessor :ssh_key
  
  # key for ssh access.
  attr_accessor :chef_version
  
  # key for  local port.
  attr_accessor :local_port
  
  # key for  facts.
  attr_accessor :facts
  
  # user when doing sudo access
  attr_accessor :user
  
  # password of user if not using ssh keys
  attr_accessor :password
  
  # password of sudo user
  attr_accessor :sudo_password
  
  # xtra options for the puppet apply commands 
  attr_accessor :xoptions

  # don't delete puppet repo after running puppet
  attr_accessor :nodeleterepo
  
   # don't update packages before running puppet
  attr_accessor :noupdatepackages 
  
  # user when doing sudo access
  attr_accessor :hiera_config
      
  # puppet manifest name
  attr_accessor :manifest

  # Can chef and its dependencies be installed automatically if not found? true means perform installation without prompting, false means quit if chef isn't available, and nil means prompt the user for input.
  attr_accessor :can_install

  # {Pocketknife::NodeManager} instance.
  attr_accessor :node_manager

  # Instantiate a new Pocketknife.
  #
  # @option [Boolean] verbosity Amount of detail to display. +true+ means verbose, +nil+ means normal, +false+ means quiet.
  # @option [Boolean] install Install Chef and its dependencies if needed? +true+ means do so automatically, +false+ means don't, and +nil+ means display a prompt to ask the user what to do.
  def initialize(opts={})
    self.verbosity   = opts[:verbosity]
    self.can_install = opts[:install]
	self.manifest = "init.pp"
    self.node_manager = NodeManager.new(self)
  end

  # Display a message, but only if it's important enough
  #
  # @param [String] message The message to display.
  # @param [Boolean] importance How important is this? +true+ means important, +nil+ means normal, +false+ means unimportant.
  def say(message, importance=nil)
    display = \
      case self.verbosity
      when true
        true
      when nil
        importance != false
      else
        importance == true
      end

    if display
      puts message
    end
  end

  # Creates a new project directory.
  #
  # @param [String] project The name of the project directory to create.
  # @yield [path] Yields status information to the optionally supplied block.
  # @yieldparam [String] path The path of the file or directory created.
  def create(project)
    self.say("* Creating project in directory: #{project}")

    dir = Pathname.new(project)

    %w[
      manifests
      modules
    ].each do |subdir|
      target = (dir + subdir)
      unless target.exist?
        FileUtils.mkdir_p(target)
        self.say("- #{target}/")
      end
    end

    return true
  end

  # Returns a Node instance.
  #
  # @param[String] name The name of the node.
  def node(name)
    return node_manager.find(name)
  end

  # Deploys configuration to the nodes, calls {#upload} and {#apply}.
  #
  # @params[Array<String>] nodes A list of node names.
  def deploy(nodes)
    node_manager.assert_known(nodes)

    Node.prepare_upload do
      for node in nodes
        node_manager.find(node).deploy
      end
    end
  end

  # Uploads configuration information to remote nodes.
  #
  # @param [Array<String>] nodes A list of node names.
  def upload(nodes)
    node_manager.assert_known(nodes)

    Node.prepare_upload do
      for node in nodes
        node_manager.find(node).upload
      end
    end
  end

  # Applies configurations to remote nodes.
  #
  # @param [Array<String>] nodes A list of node names.
  def apply(nodes)
    node_manager.assert_known(nodes)

    for node in nodes
      node_manager.find(node).apply
    end
  end
end
