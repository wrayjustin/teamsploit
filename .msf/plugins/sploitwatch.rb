##	Sploit Watch
##		Player Tracking and Reporting
##
##	Copyright (C) 2012 iSight Security, Inc.
##
##    This program is free software: you can redistribute it and/or modify
##    it under the terms of the GNU General Public License as published by
##    the Free Software Foundation, either version 3 of the License, or
##    (at your option) any later version.
##
##    This program is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU General Public License for more details.
##
##    You should have received a copy of the GNU General Public License
##    along with this program.  If not, see <http://www.gnu.org/licenses/>.


##  Load HTTP
require 'net/http'
require 'net/https'
require 'uri'

##  MSF Module
module Msf
	##  MSF Plugin
	class Plugin::SploitWatch < Msf::Plugin

		##  Initalization	
		def respond_to?(name)
			true
		end

		##  Debug Only
		def method_missing(name, *args)
			if (self.framework.datastore['SPLOITWATCH_DEBUG'] == "devel")
				self.status("[DEBUG] Non-Reported (Method): #{name}(#{args.join(", ")})")
			end
			return
                end

		##  Module Execution
		def on_module_run(mod)
			self.send_data({'sploitwatch'=>'true', 'activityType'=>1, 'eventId'=>self.framework.datastore['SPLOITWATCH_EVENT'], 'player'=>self.framework.datastore['SPLOITWATCH_HANDLE'], 'playerIP'=>mod.datastore['LHOST'], 'module'=>mod.fullname, 'target'=>mod.datastore['RHOST'], 'details'=>mod.datastore})
		end

		##  Module Error
		def on_module_error(mod, error)
			self.send_data({'sploitwatch'=>'true', 'activityType'=>2, 'eventId'=>self.framework.datastore['SPLOITWATCH_EVENT'], 'player'=>self.framework.datastore['SPLOITWATCH_HANDLE'], 'playerIP'=>mod.datastore['LHOST'], 'module'=>mod.fullname, 'target'=>mod.datastore['RHOST'], 'details'=>error})
		end

		##  Module Success
		def on_exploit_success(mod, session)
			self.send_data({'sploitwatch'=>'true', 'activityType'=>3, 'eventId'=>self.framework.datastore['SPLOITWATCH_EVENT'], 'player'=>self.framework.datastore['SPLOITWATCH_HANDLE'], 'playerIP'=>mod.datastore['LHOST'], 'module'=>mod.fullname, 'target'=>mod.datastore['RHOST'], 'details'=>session.type})
		end

		##  Session Opened
		def on_session_open(session)
			self.send_data({'sploitwatch'=>'true', 'activityType'=>4, 'eventId'=>self.framework.datastore['SPLOITWATCH_EVENT'], 'player'=>self.framework.datastore['SPLOITWATCH_HANDLE'], 'playerIP'=>playerIP, 'module'=>session.type, 'target'=>target, 'details'=>session.via_exploit})
		end

		##  Session Closed
		def on_session_close(session)
			self.send_data({'sploitwatch'=>'true', 'activityType'=>5, 'eventId'=>self.framework.datastore['SPLOITWATCH_EVENT'], 'player'=>self.framework.datastore['SPLOITWATCH_HANDLE'], 'playerIP'=>playerIP, 'module'=>session.type, 'target'=>target})
		end

		##  Sessions Command
		def on_session_command(session, cmd)
			target,vport = session.tunnel_peer.split(':')
			if cmd == "exit"
				self.send_data({'sploitwatch'=>'true', 'activityType'=>5, 'eventId'=>self.framework.datastore['SPLOITWATCH_EVENT'], 'player'=>self.framework.datastore['SPLOITWATCH_HANDLE'], 'playerIP'=>session.session_host, 'module'=>session.type, 'target'=>target})
			elsif (self.framework.datastore['SPLOITWATCH_CMD_REPORT'] == "true")
				self.send_data({'sploitwatch'=>'true', 'activityType'=>6, 'eventId'=>self.framework.datastore['SPLOITWATCH_EVENT'], 'player'=>self.framework.datastore['SPLOITWATCH_HANDLE'], 'playerIP'=>session.session_host, 'module'=>session.type, 'target'=>target, 'details'=>cmd})
			end					
		end

		##  Command
		def on_ui_command(cmd)
			if (self.framework.datastore['SPLOITWATCH_CMD_REPORT'] == "true")
				self.send_data({'sploitwatch'=>'true', 'activityType'=>6, 'eventId'=>self.framework.datastore['SPLOITWATCH_EVENT'], 'player'=>self.framework.datastore['SPLOITWATCH_HANDLE'], 'playerIP'=>"Unknown", 'module'=>'metasploit', 'target'=>target, 'details'=>cmd})
			end
		end

		def send_data(data)
				begin
					uri = URI.parse(self.framework.datastore['SPLOITWATCH_SRV_URI'])
					http = Net::HTTP.new(uri.host, uri.port)
					post = Net::HTTP::Post.new(uri.path)
					if (uri.scheme = 'https')
						http.use_ssl = true 
						http.verify_mode = OpenSSL::SSL::VERIFY_NONE
					end
					post.form_data = data
					response = http.request(post)
				if (self.framework.datastore['SPLOITWATCH_DEBUG'] == "true" || self.framework.datastore['SPLOITWATCH_DEBUG'] == "devel")
					self.status(response.body)
				end
				rescue
					self.status("error")
				end
		end

		def status(type)
			case type
				when "error"
					print_error("SploitWatch:  Connection Failed - Did You Set Your Variables?")
				else
					print_status(type)
			end
		end

		##  Initialize Metasploit Plugin
	        def initialize(framework, opts)
	                super
	                self.framework.events.add_exploit_subscriber(self)
	                self.framework.events.add_session_subscriber(self)
	                self.framework.events.add_general_subscriber(self)
	                self.framework.events.add_db_subscriber(self)
	                self.framework.events.add_ui_subscriber(self)
			self.framework.datastore['SPLOITWATCH_SRV_URI'] = "http://192.168.201.2/sendData.php"
			self.framework.datastore['SPLOITWATCH_HANDLE'] = "Unknown"
			self.framework.datastore['SPLOITWATCH_EVENT'] = "Unknown"
			self.framework.datastore['SPLOITWATCH_CMD_REPORT'] = false
			self.framework.datastore['SPLOITWATCH_DEBUG'] = false
	        end

		##  Unload Plugin
	        def cleanup
	                self.framework.events.remove_exploit_subscriber(self)
	                self.framework.events.remove_session_subscriber(self)
	                self.framework.events.remove_general_subscriber(self)
	                self.framework.events.remove_db_subscriber(self)
	                self.framework.events.remove_ui_subscriber(self)
	        end

		##  Plugin Name
		def name
			"sploitwatch"
		end

		##  Plugin Description
		def desc
			"Player Tracking and Reporting"
		end
	end
end
