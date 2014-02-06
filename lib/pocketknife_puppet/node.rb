class Pocketknife_puppet
  # == Node
  #
  # A node represents a remote computer that will be managed with Pocketknife and <tt>masterless puppet</tt>. It can connect to a node, execute commands on it, install the stack, and upload and apply configurations to it.
  class Node
    # String name of the node.
    attr_accessor :name

    # Instance of a {Pocketknife}.
    attr_accessor :pocketknife

    # Instance of Rye::Box connection, cached by {#connection}.
    attr_accessor :connection_cache

    # Hash with information about platform, cached by {#platform}.
    attr_accessor :platform_cache
    
    @sudo = ""
	@sudo_facts = ""
	@deleterepo = false
	@noupdatepackages = false
	@hiera = ""
	@xoptions = ""
	#@modules_list = ""
	@modules_path = ""

    # Initialize a new node.
    #
    # @param [String] name A node name.
    # @param [Pocketknife] pocketknife
    def initialize(name, pocketknife)
      self.name = name
      self.pocketknife = pocketknife
      if pocketknife.user != nil and pocketknife.user != "" and pocketknife.user != "root"
	     if pocketknife.sudo_password != nil and pocketknife.sudo_password != ""
		    case self.platform[:distributor].downcase
              when /ubuntu/, /debian/, /gnu\/linux/
		        @sudo = "echo #{pocketknife.sudo_password} | sudo -S "
			  else
			    @sudo = "echo #{pocketknife.sudo_password} | sudo -S "
				@sudo_facts = "echo #{pocketknife.sudo_password} | sudo -S "
			end  
		 else
           @sudo = "sudo "
	        case self.platform[:distributor].downcase
              when /ubuntu/, /debian/, /gnu\/linux/
		        @sudo_facts = ""
			  else
			    @sudo_facts = "sudo "
			end 	   
		   
		 end
      end
	  if pocketknife.deleterepo != nil and pocketknife.deleterepo == true	  
         @deleterepo =true
      end
	  if pocketknife.noupdatepackages != nil and pocketknife.noupdatepackages == true	  
         @noupdatepackages =true
      end	  
	  if pocketknife.xoptions != nil and pocketknife.xoptions != ""	  
         @xoptions = pocketknife.xoptions
      end	  
      if pocketknife.hiera_config != nil and pocketknife.hiera_config != ""	  
         @hiera = "--hiera_config  #{VAR_POCKETKNIFE}/#{pocketknife.hiera_config}"
      end 
	  if pocketknife.module_path != nil and pocketknife.module_path != ""
 		 mod_array = pocketknife.module_path.split(':')
		 mod_array.each_index do |i|
		   mod_array[i] = VAR_POCKETKNIFE + mod_array[i]
		 end 
		 @modules_path = ":"+mod_array.join(":") 
		 puts "*** module path #{@modules_path}"
	  else 
         @modules_list = VAR_POCKETKNIFE_MODULES.basename.to_s 	  
      end
	  self.connection_cache = nil
    end

    # Returns a Rye::Box connection.
    #
    # Caches result to {#connection_cache}.
    def connection
      return self.connection_cache ||= begin
          #rye = Rye::Box.new(self.name, :user => "root")
          user = "root"
		  password = ""
          if self.pocketknife.user != nil and self.pocketknife.user != ""
             user = self.pocketknife.user
          end
		  if self.pocketknife.local_port != nil and self.pocketknife.local_port != ""
             if self.pocketknife.ssh_key != nil and self.pocketknife.ssh_key != ""
                puts "*** Connecting to ssh tunnel ..... via localhost port #{self.pocketknife.local_port} as user #{user} with ssh key *** "
                rye = Rye::Box.new("localhost", {:user => user, :port => self.pocketknife.local_port, :keys => self.pocketknife.ssh_key, :safe => false })  
             else
                puts "*** Connecting to ssh tunnel ..... via localhost port #{self.pocketknife.local_port} as user #{user} *** "
                 rye = Rye::Box.new("localhost", {:user => user, :password => self.pocketknife.password, :port => self.pocketknife.local_port, :safe => false })
             end
          elsif self.pocketknife.ssh_key != nil and self.pocketknife.ssh_key != ""
             puts "*** Connecting to .... #{self.name} as user #{user} with ssh key *** "
             rye = Rye::Box.new(self.name, {:user => user, :keys => self.pocketknife.ssh_key, :safe => false })
          else
             puts "*** Connecting to .... #{self.name} as user #{user} *** "
             rye = Rye::Box.new(self.name, {:user => user, :password => self.pocketknife.password })
          end
          rye.disable_safe_mode
          rye
        end
    end

    # Displays status message.
    #
    # @param [String] message The message to display.
    # @param [Boolean] importance How important is this? +true+ means important, +nil+ means normal, +false+ means unimportant.
    def say(message, importance=nil)
      self.pocketknife.say("* #{self.name}: #{message}", importance)
    end

    # Returns path to this node's <tt>nodes/NAME.json</tt> file, used as <tt>node.json</tt> by <tt>puppet apply</tt>.
    #
    # @return [Pathname]
    def local_node_json_pathname
      return Pathname.new("nodes") + "#{self.name}.json"
    end

    # Does this node have the given executable?
    #
    # @param [String] executable A name of an executable, e.g. <tt>puppet apply</tt>.
    # @return [Boolean] Has executable?
    def has_executable?(executable)
      begin
        self.connection.execute(%{which "#{executable}" && test -x `which "#{executable}"`})
        return true
      rescue Rye::Err
        return false
      end
    end

    # Returns information describing the node.
    #
    # The information is formatted similar to this:
    #   {
    #     :distributor=>"Ubuntu", # String with distributor name
    #     :codename=>"maverick", # String with release codename
    #     :release=>"10.10", # String with release number
    #     :version=>10.1 # Float with release number
    #   }
    #
    # @return [Hash<String, Object] Return a hash describing the node, see above.
    # @raise [UnsupportedInstallationPlatform] Raised if there's no installation information for this platform.
    def platform
       puts "*** platform cache #{self.platform_cache} "
       result = {}
       begin
         output = self.connection.cat("/etc/centos-release").to_s
         if output != nil and output != "" 
            result[:distributor]="centos"
            return result
         end
       rescue 
       end
       begin
         output = self.connection.cat("/etc/redhat-release").to_s
         if output != nil and output != ""              
            result[:distributor]="red hat" 
            return result
         end         
       rescue 
       end 
       begin
         # amazon linux is red hat
         output = self.connection.cat("/etc/system-release").to_s
         if output != nil and output != "" and output.include? "Amazon Linux" 
            result[:distributor]="red hat" 
            return result
         end         
       rescue 
       end             
       lsb_release = "/etc/lsb-release"
       puts "*** lsb_release #{lsb_release}"
       return self.platform_cache ||= begin
        begin
          output = self.connection.cat(lsb_release).to_s
          result = {}
          result[:distributor] = output[/DISTRIB_ID\s*=\s*(.+?)$/, 1]
          result[:release] = output[/DISTRIB_RELEASE\s*=\s*(.+?)$/, 1]
          result[:codename] = output[/DISTRIB_CODENAME\s*=\s*(.+?)$/, 1]
          result[:version] = result[:release].to_f
          puts "*** output #{output}"
          puts "*** result #{result}"
          if result[:distributor] && result[:release] && result[:codename] && result[:version]
            return result
          else
            raise UnsupportedInstallationPlatform.new("Can't install on node '#{self.name}' with invalid '/etc/lsb-release' file", self.name)
          end
        rescue Rye::Err
          raise UnsupportedInstallationPlatform.new("Can't install on node '#{self.name}' without '/etc/lsb-release'", self.name)
        end
      end
    end


    # Installs Puppet and its dependencies on a node if needed.
    #
    # @raise [NotInstalling] Raised if Puppet isn't installed, but user didn't allow installation.
    # @raise [UnsupportedInstallationPlatform] Raised if there's no installation information for this platform.
    def install
      unless self.has_executable?("puppet")
         self.install_puppet
      end
      unless self.has_executable?("librarian-puppet")
         self.install_puppet_librarian
      end	  
    end
	
   # Installs Puppet on the remote node.
    def install_puppet
      self.say("*** Installing puppet ***")
	  if @noupdatepackages == nil or @noupdatepackages != true
	    self.install_packages
	  end	
      case self.platform[:distributor].downcase
        when /ubuntu/, /debian/, /gnu\/linux/
        self.execute <<-HERE
    #{@sudo} apt-get -y install puppet
    HERE
      else
         self.execute <<-HERE
    yum -y install puppet 
    HERE
      end
      self.say("Installed puppet", false)
    end  
	
  # Installs Puppet librarian on the remote node.
    def install_puppet_librarian
      self.say("*** Installing puppet librarian ***")
      case self.platform[:distributor].downcase
        when /ubuntu/, /debian/, /gnu\/linux/
        self.execute <<-HERE
    #{@sudo} apt-get -y install git ruby-dev make &&
    #{@sudo} gem install librarian-puppet
    HERE
      else
         self.execute <<-HERE
    yum -y install git &&
    gem install librarian-puppet  
    HERE
      end
      self.say("Installed puppet librarian", false)
    end	
	
    def install_packages
      self.say("*** Installing packages ***")
      case self.platform[:distributor].downcase
        when /ubuntu/, /debian/, /gnu\/linux/
        self.execute <<-HERE
    #{@sudo} apt-get -y update &&
    #{@sudo} apt-get -y upgrade
    HERE
      else
         self.execute <<-HERE
    yum -y update
     HERE
      end
      self.say("Updated Packages", false)
    end  	

     # Prepares an upload, by creating a cache of shared files used by all nodes.
    #
    # IMPORTANT: This will create files and leave them behind. You should use the block syntax or manually call {cleanup_upload} when done.
    #
    # If an optional block is supplied, calls {cleanup_upload} automatically when done. This is typically used like:
    #
    #   Node.prepare_upload do
    #     mynode.upload
    #   end
    #
    # @yield [] Prepares the upload, executes the block, and cleans up the upload when done.
    def self.prepare_upload(module_list=VAR_POCKETKNIFE_MODULES.basename.to_s, &block)
      begin
        puts("********************** ")
        puts("*** Prepare upload *** ")
        puts("********************** ")
        # TODO either do this in memory or scope this to the PID to allow concurrency
        # minitar gem on windows tar file corrupt so use alternative command
        if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
           puts "*** On windows using tar.exe *** "
           puts "#{ENV['POCKETKNIFE_PUPPET_HOME']}/tar/tar.exe cvf *.*" 
           system "#{ENV['POCKETKNIFE_PUPPET_HOME']}/tar/tar.exe cvf #{TMP_TARBALL.to_s} *.*" 		   
           #puts "#{ENV['POCKETKNIFE_PUPPET_HOME']}/tar/tar.exe cvf #{TMP_TARBALL.to_s} #{VAR_POCKETKNIFE_MANIFESTS.basename.to_s} #{module_list} #{VAR_POCKETKNIFE_HIERA.basename.to_s} hiera.yaml Puppetfile" 
           #system "#{ENV['POCKETKNIFE_PUPPET_HOME']}/tar/tar.exe cvf #{TMP_TARBALL.to_s} #{VAR_POCKETKNIFE_MANIFESTS.basename.to_s} #{module_list} #{VAR_POCKETKNIFE_HIERA.basename.to_s} hiera.yaml Puppetfile" 
        else
		   # TODO: change to get all the files like for windows.....
           TMP_TARBALL.open("w") do |handle|
             Archive::Tar::Minitar.pack(
              [
               VAR_POCKETKNIFE_MANIFESTS.basename.to_s,
  			   VAR_POCKETKNIFE_HIERA.basename.to_s,
			   'Puppetfile',
			   'hiera.yaml'
			   ]+module_list.split(' '),
              handle
             )
           end  
        end
      rescue Exception => e
        cleanup_upload
        raise e
      end

      if block
        begin
          yield(self)
        ensure
          cleanup_upload
        end
      end
    end

    # Cleans up cache of shared files uploaded to all nodes. This cache is created by the {prepare_upload} method.
    def self.cleanup_upload
      [
        TMP_TARBALL
      ].each do |path|
        path.unlink if path.exist?
      end
    end

   # Uploads configuration information to node.
   #
   # IMPORTANT: You must first call {prepare_upload} to create the shared files that will be uploaded.
   def upload
     if @sudo != nil and @sudo != ""
       upload_sudo
     else   
       self.say("*** Uploading configuration ***")
        self.say("*** Removing old files *** ", false)
       self.execute <<-HERE
	rm -f /var/log/puppet/apply.log &&   
    umask 0377 &&
	export GLOBIGNORE=/var/local/pocketknife/modules:/var/local/pocketknife/Puppetfile:/var/local/pocketknife/Puppetfile.lock &&
   rm -rf #{ETC_PUPPET} #{VAR_POCKETKNIFE}/* #{VAR_POCKETKNIFE_CACHE} &&
   export GLOBIGNORE= &&
   mkdir -p "#{ETC_PUPPET}" "#{VAR_POCKETKNIFE}" "#{VAR_POCKETKNIFE}/modules" "#{VAR_POCKETKNIFE_CACHE}"  
   HERE
       self.say("Uploading new files...", false)
       self.connection.file_upload(TMP_TARBALL.to_s, VAR_POCKETKNIFE_TARBALL.to_s)
       self.say("Installing new files...", false)
       self.execute <<-HERE, true
   cd "#{VAR_POCKETKNIFE_CACHE}" &&
   tar xvf "#{VAR_POCKETKNIFE_TARBALL}" &&
   chmod -R u+rwX,go= . &&
   chown -R root:root . &&
   mv * "#{VAR_POCKETKNIFE}"
       HERE
        self.say("*** Finished uploading! *** ", false)
    end
 end   

    # Uploads configuration information to node.
    #
    # IMPORTANT: You must first call {prepare_upload} to create the shared files that will be uploaded.
    def upload_sudo
      self.say("****************************************** ")
      self.say("*** Uploading configuration using sudo *** ")
      self.say("****************************************** ")
      self.say("*** Removing old files ***", false)
      self.execute <<-HERE
   umask 0377 &&
  export GLOBIGNORE=/var/local/pocketknife/modules:/var/local/pocketknife/Puppetfile:/var/local/pocketknife/Puppetfile.lock &&
  #{@sudo}rm -rf #{ETC_PUPPET} #{VAR_POCKETKNIFE}/* #{VAR_POCKETKNIFE_CACHE} && 
  export GLOBIGNORE= &&
  #{@sudo}mkdir -p "#{ETC_PUPPET}" "#{VAR_POCKETKNIFE}" "#{VAR_POCKETKNIFE}/modules" "#{VAR_POCKETKNIFE_CACHE}" &&
  #{@sudo}chmod -R a+rwX "#{ETC_PUPPET}" &&
  #{@sudo}chmod -R a+rwX "#{VAR_POCKETKNIFE}" &&
  #{@sudo}chmod -R a+rwX "#{VAR_POCKETKNIFE_CACHE}"
  HERE

      self.say("*** Uploading new files ***", false)
      #self.say("Uploading #{self.local_node_json_pathname} to #{NODE_JSON}", false)
      #self.connection.file_upload(self.local_node_json_pathname.to_s, NODE_JSON.to_s)
      self.connection.file_upload(TMP_TARBALL.to_s, VAR_POCKETKNIFE_TARBALL.to_s)
      self.say("*** Installing new files ***", false)
      self.execute <<-HERE, true
  cd "#{VAR_POCKETKNIFE_CACHE}" &&
  #{@sudo}tar xvf "#{VAR_POCKETKNIFE_TARBALL}" &&
  #{@sudo}chmod -R a+rwX "#{VAR_POCKETKNIFE_CACHE}"  &&
  #{@sudo}rm "#{VAR_POCKETKNIFE_TARBALL}" &&
  #{@sudo}mv * "#{VAR_POCKETKNIFE}"
      HERE
      self.say("*************************** ", false)
      self.say("*** Finished uploading! *** ", false)
      self.say("*************************** ", false)
    end
    
 

    

    # Applies the configuration to the node. Installs Puppet, Ruby and Rubygems if needed.
    def apply
      self.install
      if self.pocketknife.facts != nil and self.pocketknife.facts != ""
        facts_array = self.pocketknife.facts.split(',').map { |f| f = "export FACTER_#{f}"  } 
        facts_cmd = facts_array.join("; ")
        case self.platform[:distributor].downcase
           when /ubuntu/, /debian/, /gnu\/linux/
            facts_env_array = self.pocketknife.facts.split(',').map { |f| f = "FACTER_#{f}"  }
		    facts_env = facts_env_array.join(" ")
        end 	  		
      else 
        facts_cmd = "true"
      end  
	  
	  if self.connection.file_exists?("#{VAR_POCKETKNIFE}/Puppetfile.lock")
       self.say("******************************************************************* ", true)
       self.say("*** librarian-puppet not run as Puppetfile.lock already in repo *** ", true)
	   self.say("*** specify -n on pocketknife_puppet command force update of modules  *** ", true)
       self.say("******************************************************************* ", true)	  
      elsif self.connection.file_exists?("#{VAR_POCKETKNIFE}/Puppetfile")
       self.say("************************************************************* ", true)
       self.say("*** Run librarian-puppet install using Puppetfile in repo *** ", true)
       self.say("************************************************************* ", true)	  
	   begin 
	     self.execute(<<-HERE, true)
       cd #{VAR_POCKETKNIFE} &&
       #{@sudo} librarian-puppet install --path=modules --verbose
       HERE
        rescue
         error_run = true 
        end 
      else 
	   self.say("*** No #{VAR_POCKETKNIFE}/Puppetfile in Puppet Repository *** ", true)
      end
	  
      self.say("****************************** ", true)
      self.say("*** Applying configuration *** ", true)
      self.say("****************************** ", true)
	  self.say("***sudo is #{@sudo} ", true)	  
	  module_path = #{VAR_POCKETKNIFE_MODULES}
	  if pocketknife.module_path != nil and pocketknife.module_path != ""	  
         @modules_list = pocketknife.module_path.gsub(/:/,' ')
      end
      command = "puppet apply #{@xoptions} #{@hiera}  --logdest /var/log/puppet/apply.log --modulepath=\"#{VAR_POCKETKNIFE_MODULES}#{@modules_path}\" #{VAR_POCKETKNIFE_MANIFESTS}/#{self.pocketknife.manifest}"
      command << " -v -d " if self.pocketknife.verbosity == true
      error_run = false 
      begin 
 
	  self.execute(<<-HERE, true)
 #{@sudo_facts}#{facts_cmd} &&	  	  
 #{@sudo} #{facts_env} #{command}
	 HERE
      rescue
         error_run = true 
      end 
	     self.execute("#{@sudo}rm -rf \"#{VAR_POCKETKNIFE}\" \"#{VAR_POCKETKNIFE_CACHE}\"") if @deleterepo == true
         self.say("*** showing last 100 lines from /var/log/puppet/apply.log *** ")
         self.execute("#{@sudo} tail -n 100 /var/log/puppet/apply.log", true)
         if error_run 
            self.say("*** Finished applying with Error! full log is at /var/log/puppet/apply.log *** ")
	 else
	  self.say("*** Finished applying! full log is at /var/log/puppet/apply.log *** ")
	 end 
    end

    # Deploys the configuration to the node, which calls {#upload} and {#apply}.
    def deploy
      self.upload
      self.apply
    end

    # Executes commands on the external node.
    #
    # @param [String] commands Shell commands to execute.
    # @param [Boolean] immediate Display execution information immediately to STDOUT, rather than returning it as an object when done.
    # @return [Rye::Rap] A result object describing the completed execution.
    # @raise [ExecutionError] Raised if something goes wrong with execution.
    def execute(commands, immediate=false)
      self.say("Executing:\n#{commands}", false)
      if immediate
        self.connection.stdout_hook {|line| puts line}
      end
      return self.connection.execute("(#{commands}) 2>&1")
    rescue Rye::Err => e
      raise Pocketknife_puppet::ExecutionError.new(self.name, commands, e, immediate)
    ensure
      self.connection.stdout_hook = nil
    end

    # Remote path to Puppet's settings
    # @private
    ETC_PUPPET = Pathname.new("/etc/puppet")
    # Remote path to solo.rb
    # @private
    #SOLO_RB = ETC_PUPPET + "solo.rb"
    # Remote path to node.json
    # @private
    #NODE_JSON = ETC_PUPPET + "node.json"
    # Remote path to pocketknife's deployed configuration
    # @private
    VAR_POCKETKNIFE = Pathname.new("/var/local/pocketknife")
    # Remote path to pocketknife's cache
    # @private
    VAR_POCKETKNIFE_CACHE = VAR_POCKETKNIFE + "cache"
    # Remote path to temporary tarball containing uploaded files.
    # @private
    VAR_POCKETKNIFE_TARBALL = VAR_POCKETKNIFE_CACHE + "pocketknife.tmp"
    # Remote path to pocketknife's manifests
    # @private
    VAR_POCKETKNIFE_MANIFESTS = VAR_POCKETKNIFE + "manifests"
    # Remote path to pocketknife's modules
    # @private
    VAR_POCKETKNIFE_MODULES = VAR_POCKETKNIFE + "modules"
	VAR_POCKETKNIFE_HIERA = VAR_POCKETKNIFE + "hieradata"
    # Remote path to pocketknife's roles
    # @private
    #VAR_POCKETKNIFE_ROLES = VAR_POCKETKNIFE + "roles"
    # Remote path to pocketknife's roles
    # @private
    #VAR_POCKETKNIFE_DATA_BAGS = VAR_POCKETKNIFE + "data_bags"
    # Content of the solo.rb file
    # @private
    #SOLO_RB_CONTENT = <<-HERE
#file_cache_path "#{VAR_POCKETKNIFE_CACHE}"
#cookbook_path ["#{VAR_POCKETKNIFE_COOKBOOKS}", "#{VAR_POCKETKNIFE_SITE_COOKBOOKS}"]
#role_path "#{VAR_POCKETKNIFE_ROLES}"
#data_bag_path "#{VAR_POCKETKNIFE_DATA_BAGS}"
    #HERE
    # Remote path to chef-solo-apply
    # @private
    #PUPPET_SOLO_APPLY = Pathname.new("/usr/local/sbin/chef-solo-apply")
    # Remote path to csa
    # @private
    #PUPPET_SOLO_APPLY_ALIAS = PUPPET_SOLO_APPLY.dirname + "csa"
    # Content of the chef-solo-apply file
    # @private
    #PUPPET_SOLO_APPLY_CONTENT = <<-HERE
##!/bin/sh
#chef-solo -j #{NODE_JSON} "$@"
   #HERE
    # Local path to solo.rb that will be included in the tarball
    # @private
    #TMP_SOLO_RB = Pathname.new("solo.rb.tmp")
    # Local path to chef-solo-apply.rb that will be included in the tarball
    # @private
    #TMP_PUPPET_SOLO_APPLY = Pathname.new("chef-solo-apply.tmp")
    # Local path to the tarball to upload to the remote node containing shared files
    # @private
    TMP_TARBALL = Pathname.new("pocketknife.tmp")
  end
end
