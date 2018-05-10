require 'monitor'
require 'net/ssh'
require 'net/telnet'
require 'net/scp'

class Netdev 
  attr_reader :host, :port

  def initialize(config = {})
  	@host = config['ip'].strip
   	@type = config['type']
    	@mgmt_if = config['mgmt_if']
    	@sw = nil
    	@keys = config['key'].strip || '/root/key2'
   	@version = config['version'].to_s || '0.0'
    	@sshusers = config['sshusers']
    	@sshpass = config['sshpass']
    	@oaipwd = config['oaipwd']
    	@defaultConfig = config['default']
    	@ch = nil
    	info("Initialized networking device at #{@host}, of #{@type} type, #{@sshusers}, #{@sshpass}, #{@oaipwd} and #{@defaultConfig}")
    	info("Key for controlling the device is #{@keys}")
  end

  def close
    	@manager.close
    	@sw.close unless @sw.nil?
  end

  def telnet_get(command)
    	#logs in and retrieves OF info from switch
    	@sw.cmd(command).split(/\n/)
  end

  def sshNoPwd(command)
	puts command
  	begin
      		ret = false
      		tryAgain = true
      		a = 0
      		result = ''  
     	 	# Start SSH connection
		puts @host
		puts @sshusers
      		Net::SSH.start(@host, @sshusers, :password => @sshpass, :paranoid => false) do |ssh|
      			# Open a channel
        		channel = ssh.open_channel do |channel, success|
           			# Callback to receive data. It will read the
           			# data and store it in result var or
           			# send the pasword if it's required.
           			ret = true if success
           			channel.on_data do |channel, data|
           				if data =~ /^\[sudo\] password for /
             					# Send the password
             					channel.send_data "#{sshpass}\n"
           				else
             					# Store the data
						puts result
             					result += data.to_s
           				end  # end of if data
         			end #end of channel open
         			# Request a pseudo TTY
         			channel.request_pty
         			# Execute the command
         			channel.exec(command)
         			# Wait for response
         			channel.wait
      		end # end of ssh connection   
      		#ret = true
    	end #end of begin  

	puts "HERE"

    	Net::SSH.start(@host, @sshusers, :password => @sshpass,  :paranoid => false) do |ssh|
		a = ssh.exec!("#{command}")
		return a
    	end
    	rescue Errno::ECONNRESET
      		while tryAgain
        		print "RETRY SSH - Errno::ECONNRESET"
        		retry
      		end
    	rescue Errno::ECONNREFUSED
      		while tryAgain
        		print "RETRY SSH - Errno::ECONNREFUSED"
        		retry
        	end
      	rescue Errno::EHOSTUNREACH
      		while tryAgain
        		print "RETRY SSH - Errno::EHOSTUNREACH"
        		retry
      		end
    	rescue => e
      		error("Exception in ssh command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
   	end
 end


  def sshWithPwd(command)
    	begin
      		ret = false
      		tryAgain = true
      		a = 0
      		result = ''  
      		# Start SSH connection
      		Net::SSH.start(@host, @sshusers, :password => @sshpass, :paranoid => false) do |ssh|
      			# Open a channel
        		channel = ssh.open_channel do |channel, success|
           			# Callback to receive data. It will read the
           			# data and store it in result var or
           			# send the pasword if it's required.
           			ret = true if success
           			channel.on_data do |channel, data|
           			if data =~ /^\[sudo\] password for /
             				# Send the password
             				channel.send_data "#{sshpass}\n"
           			else
             				# Store the data
             				result += data.to_s
           			end  # end of if data
         		end #end of channel open
         		# Request a pseudo TTY
         		channel.request_pty
         		# Execute the command
         		channel.exec(command)
         		# Wait for response
         		channel.wait
      		end # end of ssh connection
    
      		# Wait for opened channel
      		channel.wait
      		#ret = true
    	end #end of begin  

    	Net::SSH.start(@host, @sshusers, :password => @sshpass, :paranoid => false) do |ssh|
		a = ssh.exec!("#{command}")
		return a
    	end

    	#return true


    	rescue Errno::ECONNRESET
      		while tryAgain
        		print "RETRY SSH - Errno::ECONNRESET"
        		retry
      		end
    	rescue Errno::ECONNREFUSED
      		while tryAgain
        		print "RETRY SSH - Errno::ECONNREFUSED"
        		retry
        	end
      	rescue Errno::EHOSTUNREACH
      		while tryAgain
        	print "RETRY SSH - Errno::EHOSTUNREACH"
        	retry
      	end
    	rescue => e
      		error("Exception in ssh command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
   	end
 end


  def sshKey(command)
    	begin
      		tryAgain = true
       		Net::SSH.start(@host, @sshusers, :host_key => 'ssh-rsa', :keys => [@keys], :paranoid => false) do |ssh|
        		a = ssh.exec!(command)
        		return a
      		end
      	rescue Errno::ECONNRESET
        	while tryAgain
          		print "RETRY SSH - Errno::ECONNRESET"
          		retry
        	end
      	rescue Errno::ECONNREFUSED
        	while tryAgain
          		print "RETRY SSH - Errno::ECONNREFUSED"
          		retry
        	end
      	rescue Errno::EHOSTUNREACH
        	while tryAgain
          		print "RETRY SSH - Errno::EHOSTUNREACH"
          		retry
        	end
      	rescue => e
        	error("Exception in ssh command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    	end
  end

  def scpWithKey(file_path,remote_path,action)
    	begin
      		tryAgain = true
      		if action.eql? "upload"
        		Net::SCP.upload!(@host, @sshusers, file_path, remote_path, :ssh => { :host_key => 'ssh-rsa', :keys => [@keys], :paranoid => false })
        		return "true"
      		elsif action.eql? "download"
        		Net::SCP.download!(@host, @sshusers, remote_path, file_path, :ssh => { :host_key => 'ssh-rsa', :keys => [@keys], :paranoid => false })   
      		end
      	rescue Errno::ECONNRESET
        	while tryAgain
         		print "RETRY SSH - Errno::ECONNRESET"
          		retry
        	end
      	rescue Errno::ECONNREFUSED
        	while tryAgain
          		print "RETRY SSH - Errno::ECONNREFUSED"
          		retry
        	end
      	rescue Errno::EHOSTUNREACH
        	while tryAgain
          		print "RETRY SSH - Errno::EHOSTUNREACH"
          		retry
        	end
      	rescue => e
        	error("Exception in ssh command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    	end
  end

  def scpWithPwd(file_path,remote_path,action)
    	begin
      		tryAgain = true
      		if action.eql? "upload"
        		Net::SCP.upload!(host, @sshusers, file_path, remote_path, :ssh => { :password => @sshpass, :paranoid => false })
        		return "true"
      		elsif action.eql? "download"
        		Net::SCP.download!(host, @sshusers, remote_path, file_path, :ssh => { :password => @sshpass, :paranoid => false })   
      		end
      	rescue Errno::ECONNRESET
        	while tryAgain
          		print "RETRY SSH - Errno::ECONNRESET"
          		retry
        	end
      	rescue Errno::ECONNREFUSED
        	while tryAgain
          		print "RETRY SSH - Errno::ECONNREFUSED"
          		retry
        	end
      	rescue Errno::EHOSTUNREACH
        	while tryAgain
          		print "RETRY SSH - Errno::EHOSTUNREACH"
          		retry
        	end
      	rescue => e
        	error("Exception in ssh command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    	end
  end

  def scpNoPwd(file_path,remote_path,action)
    	begin
      		tryAgain = true
      		if action.eql? "upload"
        		Net::SCP.upload!(host, @sshusers, file_path, remote_path, :ssh => {  :password => @sshpass, :paranoid => false })
        		return "true"
      		elsif action.eql? "download"
        		Net::SCP.download!(host, @sshusers, remote_path, file_path, :ssh => {  :password => @sshpass, :paranoid => false })   
      		end
      	rescue Errno::ECONNRESET
        	while tryAgain
          		print "RETRY SSH - Errno::ECONNRESET"
          		retry
        	end
      	rescue Errno::ECONNREFUSED
        	while tryAgain
          		print "RETRY SSH - Errno::ECONNREFUSED"
          		retry
        	end
      	rescue Errno::EHOSTUNREACH
        	while tryAgain
          		print "RETRY SSH - Errno::EHOSTUNREACH"
          		retry
        	end
      	rescue => e
        	error("Exception in ssh command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    	end
  end


  def reset_to_defaults_withKey(file_path)
    	begin
      		tryAgain = true
      		Net::SCP.upload!(@host, @sshusers, file_path, "/config/femto.db", :ssh => { :host_key => 'ssh-rsa', :keys => @keys, :paranoid => false })
      			return true
      	rescue Errno::ECONNRESET
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNRESET"
          		retry
        	end
      	rescue Errno::ECONNREFUSED
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNREFUSED"
          		retry
        	end
      	rescue Errno::EHOSTUNREACH
        	while tryAgain
          		print "RETRY SCP - Errno::EHOSTUNREACH"
          		retry
        	end
      	rescue => e
        	error("Exception in scp command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    	end
  end

  def reset_to_defaults_withPwd(file_path)
    	begin
      		tryAgain = true
      		Net::SCP.upload!(@host, @sshusers, file_path, "/config/femto.db", :ssh => { :password => @sshpass, :paranoid => false })
      			return true
      	rescue Errno::ECONNRESET
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNRESET"
          		retry
        	end
      	rescue Errno::ECONNREFUSED
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNREFUSED"
          		retry
        	end
      	rescue Errno::EHOSTUNREACH
        	while tryAgain
          		print "RETRY SCP - Errno::EHOSTUNREACH"
          		retry
        	end
      	rescue => e
        	error("Exception in scp command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    	end
  end

  def reset_to_defaults_NoPwd(file_path)
    	begin
      		tryAgain = true
      		Net::SCP.upload!(@host, @sshusers, file_path, "#{@defaultConfig}", :ssh => { :paranoid => false })
      			return true
      	rescue Errno::ECONNRESET
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNRESET"
          		retry
        	end
      	rescue Errno::ECONNREFUSED
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNREFUSED"
          		retry
        	end
      	rescue Errno::EHOSTUNREACH
        	while tryAgain
          		print "RETRY SCP - Errno::EHOSTUNREACH"
          		retry
        	end
      	rescue => e
        	error("Exception in scp command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    	end
  end


##TODO: Harmonize OAI code as well, can reuse functions with the SSHPASS
  def oai_reset_to_defaults(file_path, bs)
    begin
      tryAgain = true
      Net::SCP.upload!(@host, @sshusers[bs], config[bs], "/tmp/enb_lterf.conf", :ssh => { :password => @sshpass[bs], :paranoid => false })
      return true
      rescue Errno::ECONNRESET
        while tryAgain
          print "RETRY SCP - Errno::ECONNRESET"
          retry
        end
      rescue Errno::ECONNREFUSED
        while tryAgain
          print "RETRY SCP - Errno::ECONNREFUSED"
          retry
        end
      rescue Errno::EHOSTUNREACH
        while tryAgain
          print "RETRY SCP - Errno::EHOSTUNREACH"
          retry
        end
      rescue => e
        error("Exception in scp command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    end
  end

  def save_settings_withKey(file_path)
    	begin
     		tryAgain = true
      		Net::SCP.download!(@host, @sshusers, "/config/femto.db", file_path, :ssh => { :host_key => 'ssh-rsa', :keys => [@keys], :paranoid => false })
      		return true
      	rescue Errno::ECONNRESET
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNRESET"
          		retry
        	end
      	rescue Errno::ECONNREFUSED
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNREFUSED"
          		retry
        	end
      	rescue Errno::EHOSTUNREACH
        	while tryAgain
         		print "RETRY SCP - Errno::EHOSTUNREACH"
          		retry
        	end
      	rescue => e
        	error("Exception in scp command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    	end
  end
  
  def get_config
  	return "Type of BS : #{@type} | Ip : #{@host} | Managment Iterface : #{@mgmt_if}\n\n" 
  end

  def upload_settings_withKey(file_path)
    	begin
      		tryAgain = true
      		Net::SCP.upload!(@host, @sshusers, file_path, "/config/femto.db", :ssh => { :host_key => 'ssh-rsa', :keys => [@keys], :paranoid => false })
      			return true
      	rescue Errno::ECONNRESET
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNRESET"
          		retry
        	end
      	rescue Errno::ECONNREFUSED
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNREFUSED"
          		retry
        	end
      	rescue Errno::EHOSTUNREACH
        	while tryAgain
          		print "RETRY SCP - Errno::EHOSTUNREACH"
          		retry
        	end
      	rescue => e
        	error("Exception in scp command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    	end
  end

  def save_settings_withPwd(file_path)
    	begin
      		tryAgain = true
      		Net::SCP.download!(@host, @sshusers, "/config/femto.db", file_path, :ssh => { :password => @sshpass, :paranoid => false })
      		return true
      	rescue Errno::ECONNRESET
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNRESET"
          		retry
        	end
      	rescue Errno::ECONNREFUSED
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNREFUSED"
          		retry
        	end
      	rescue Errno::EHOSTUNREACH
        	while tryAgain
          		print "RETRY SCP - Errno::EHOSTUNREACH"
          		retry
        	end
      	rescue => e
        	error("Exception in scp command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    	end
  end

  # For OAI control only
  def save_settings_NoPwd(file_path)
    	begin
      		tryAgain = true
      		Net::SCP.download!(@host, @sshusers, "/tmp/enb_lterf.conf", file_path, :ssh => { :paranoid => false })
      		return true
      	rescue Errno::ECONNRESET
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNRESET"
          		retry
        	end
      	rescue Errno::ECONNREFUSED
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNREFUSED"
          		retry
        	end
      	rescue Errno::EHOSTUNREACH
        	while tryAgain
          		print "RETRY SCP - Errno::EHOSTUNREACH"
          		retry
        	end
      	rescue => e
        	error("Exception in scp command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    	end
  end
  
  def upload_settings_withPwd(file_path)
    	begin
      		tryAgain = true
      		Net::SCP.upload!(@host, @sshusers, file_path, "/config/femto.db", :ssh => { :password => @sshpass, :paranoid => false })
      		return true
	rescue Errno::ECONNRESET
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNRESET"
          		retry
        	end
      	rescue Errno::ECONNREFUSED
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNREFUSED"
          		retry
        	end
      	rescue Errno::EHOSTUNREACH
        	while tryAgain
          		print "RETRY SCP - Errno::EHOSTUNREACH"
          		retry
        	end
      	rescue => e
        	error("Exception in scp command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    	end
  end

  def upload_settings_withKey(file_path)
    	begin
      		tryAgain = true
      		Net::SCP.upload!(@host, @sshusers, file_path, "/config/femto.db", :ssh => { :host_key => 'ssh-rsa', :keys => [@keys], :paranoid => false })
      		return true
	rescue Errno::ECONNRESET
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNRESET"
          		retry
        	end
      	rescue Errno::ECONNREFUSED
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNREFUSED"
          		retry
        	end
      	rescue Errno::EHOSTUNREACH
        	while tryAgain
          		print "RETRY SCP - Errno::EHOSTUNREACH"
          		retry
        	end
      	rescue => e
        	error("Exception in scp command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    	end
  end

  # for OAI control only
  def upload_settings_NoPwd(file_path)
    	begin
      		tryAgain = true
      		Net::SCP.upload!(@host, @sshusers, file_path, "/tmp/enb_lterf.conf", :ssh => { :paranoid => false })
      		return true
	rescue Errno::ECONNRESET
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNRESET"
          		retry
        	end
      	rescue Errno::ECONNREFUSED
        	while tryAgain
          		print "RETRY SCP - Errno::ECONNREFUSED"
          		retry
        	end
      	rescue Errno::EHOSTUNREACH
        	while tryAgain
          		print "RETRY SCP - Errno::EHOSTUNREACH"
          		retry
        	end
      	rescue => e
        	error("Exception in scp command: #{e.message}\n\t#{e.backtrace.join("\n\t")}")
    	end
  end

end # of class netdev
