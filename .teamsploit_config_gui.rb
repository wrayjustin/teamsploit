#!/usr/bin/env ruby1.8

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

require 'gtk2'

def load_config
  @config = Hash.new
  @new_config = Hash.new
  File.open("teamsploit.conf", "r") do |infile|
    while (line = infile.gets)
      if line =~ /^#/
        next
      elsif line =~ /=/
        line.gsub!(/#.*/, '')
        values = line.split(/=/)
        key = values[0].to_s.lstrip.rstrip
        value = values[1].to_s.lstrip.rstrip
        @config[key] = value
        @new_config[key] = value
      end
    end
  end
end

def build_config
  config_file = File.read("teamsploit.conf.dist")

  @new_config.each_pair do |key, value|
    key.gsub!(/^\"/, '')
    key.gsub!(/\"$/, '')

    config_file.gsub!(/^#{key}=.*\n/, "#{key}=#{value}\n")
  end

  config_file.gsub!(/TS_CONFIG=[10]/, "TS_CONFIG=1")

  return config_file
end

def assistant_close (assistant)
  new_config_file = build_config
  File.open("teamsploit.conf", "w") {|file| file.puts new_config_file}
  assistant.destroy
end

class PageInfo
  attr_accessor :widget, :index, :title, :type, :complete
  def initialize(w, i, ti, ty, c)
    @widget, @index, @title, @type, @complete = w, i, ti, ty, c
  end
end

def load_wizard
  @assistant = Gtk::Assistant.new
  @assistant.set_title("TeamSploit Config Wizard")
  @assistant.set_size_request(800, 650)
  @assistant.signal_connect('destroy') { Gtk.main_quit }
  @assistant.signal_connect('cancel')  { @assistant.destroy }
  @assistant.signal_connect('close')   { |w| assistant_close(w) }
end

def load_page(widget, title, type, complete)
  page = PageInfo.new(widget, -1, title, type, complete)
  page.index = @assistant.append_page(page.widget)
  @assistant.set_page_title(page.widget, page.title)
  @assistant.set_page_type(page.widget, page.type)
  @assistant.set_page_complete(page.widget, page.complete)
  @assistant.show_all

  return page.index
end  

def load_entry(title, key)
  hbox = Gtk::HBox.new(false, 10)
  label = Gtk::Label.new(title)
  entry = Gtk::Entry.new
  entry.text = @config[key]

  entry.signal_connect('changed') do |entry, parent|
    @new_config[key] = entry.text
  end

  hbox.pack_start(label, false, false, 10)
  hbox.pack_start(entry, true, true, 10)
end

def load_toggle(title, key, active)
  section = Gtk::VBox.new(false, 10)
  label = Gtk::Label.new(title)
  buttons = Gtk::HBox.new(false, 10)
  yes = Gtk::RadioButton.new("Yes")
  no = Gtk::RadioButton.new(yes, "No")

  if active == "yes" || active == "true"
    d1 = yes
    d0 = no
  else
    d1 = no
    d0 = yes
  end

  if @config[key].to_i == 1 || @config[key] == "true"
    d1.active = true
  else
    d0.active = true
  end

  d1.signal_connect('toggled') do |button, widget|
    if active == "true" || active == "false"
      @new_config[key] = true
    else
      @new_config[key] = 1
    end
  end

  d0.signal_connect('toggled') do |button, widget|
    if active == "true" || active == "false"
      @new_config[key] = false
    else
      @new_config[key] = 0
    end
  end

  buttons.pack_start(yes, false, false, 10)
  buttons.pack_start(no, false, false, 10)

  section.pack_start(label, false, false, 10)
  section.pack_start(buttons, false, false, 10)
end

def load_intro_page
  widget = Gtk::Label.new(
    "Welcome to the TeamSploit Configuration Wizard!\n" +
    "\n" +
    "Using this wizard you can configure TeamSploit.\n" +
    "Would you like to proceed with configuring\n" +
    "TeamSploit through the wizard, or use the current\n" +
    "configuration?\n" +
    "\n" +
    "Select 'Forward' to continue configuration or\n" +
    "'Cancel' to use the current configuration."
  )
end

def load_general_page
  page = Gtk::VBox.new(false, 10)

  page.pack_start(load_entry("Primary Network Interface:", "TS_MY_INT"), false, false, 10)
  page.pack_start(load_entry("Number of Primary Consoles:", "TS_WINDOWS"), false, false, 10)
  page.pack_start(load_toggle("Do you wish to SKIP the configuration wizard in the future?", "TS_SKIP_CONFIG_WIZ", "yes"), false, false, 10)
end

def load_database_page
  page = Gtk::VBox.new(false, 10)
  
  page.pack_start(load_toggle("Do you wish to configure a Team Database?", "TS_LOCAL", "no"), false, false, 10)
  page.pack_start(load_entry("Database Name:", "TS_DB_NAME"), false, false, 10)
  page.pack_start(load_entry("Database Host:", "TS_DB_HOST"), false, false, 10)
  page.pack_start(load_entry("Database Port:", "TS_DB_PORT"), false, false, 10)
  page.pack_start(load_entry("Database Username:", "TS_DB_USER"), false, false, 10)
  page.pack_start(load_entry("Database Password:", "TS_DB_PASS"), false, false, 10)
end

def load_msfd_page
  page = Gtk::VBox.new(false, 10)

  page.pack_start(load_toggle("Do you wish to connect to a MSFD service?", "TS_MSFD_CONNECT", "yes"), false, false, 10)
  page.pack_start(load_entry("MSFD Host:", "TS_MSFD_HOST"), false, false, 10)
  page.pack_start(load_entry("MSFD Port:", "TS_MSFD_PORT"), false, false, 10)
end

def load_teammates_page
  page = Gtk::VBox.new(false, 10)

  page.pack_start(load_toggle("Do you wish to share shells with your self and teammates?", "TS_SHARE_SHELLS", "yes"), false, false, 10)
  page.pack_start(load_entry("Teammate Addresses:", "TS_TEAM_MATES"), false, false, 10)
  page.pack_start(load_entry("Team Port (Primary):", "TS_TEAM_PORT"), false, false, 10)
  page.pack_start(load_entry("Team Port (Secondary):", "TS_TEAM_PORT_2"), false, false, 10)
  page.pack_start(load_entry("Team Port (HTTP):", "TS_TEAM_PORT_HTTP"), false, false, 10)
  page.pack_start(load_entry("Team Port (HTTPS):", "TS_TEAM_PORT_HTTPS"), false, false, 10)
  page.pack_start(load_entry("Team Port (DNS):", "TS_TEAM_PORT_DNS"), false, false, 10)
end

def load_targets_page
  page = Gtk::VBox.new(false, 10)

  page.pack_start(load_toggle("Do you wish to auto-target?", "TS_TARGET_SOLO", "no"), false, false, 10)
  page.pack_start(load_entry("Target Ranges:", "TS_TARGET_RANGES"), false, false, 10)
end

def load_postexploit_page
  page = Gtk::VBox.new(false, 10)

  page.pack_start(load_toggle("Do you wish to launch TrollWare during Auto Post Exploitation?", "TS_TROLLWARE", "yes"), false, false, 10)
  page.pack_start(load_toggle("Do you wish to launch Net Stopper during Auto Post Exploitation?", "TS_NETSTOPPER", "yes"), false, false, 10)
  page.pack_start(load_toggle("Do you wish to launch Unpatcher during Auto Post Exploitation?", "TS_UNPATCHER", "yes"), false, false, 10)
  page.pack_start(load_entry("Username To Add:", "TS_ADMIN_USER"), false, false, 10)
  page.pack_start(load_entry("Password For Added User::", "TS_ADMIN_PASS"), false, false, 10)
end

def load_nessus_page
  page = Gtk::VBox.new(false, 10)

  page.pack_start(load_toggle("Do you wish to connect to Nessus?", "TS_NESSUS_CONNECT", "yes"), false, false, 10)
  page.pack_start(load_toggle("Do you wish to automatically scan with Nessus?", "TS_NESSUS_AUTOSCAN", "yes"), false, false, 10)
  page.pack_start(load_entry("Nessus Host:", "TS_NESSUS_HOST"), false, false, 10)
  page.pack_start(load_entry("Nessus Port:", "TS_NESSUS_PORT"), false, false, 10)
  page.pack_start(load_entry("Nessus Username:", "TS_NESSUS_USER"), false, false, 10)
  page.pack_start(load_entry("Nessus Password:", "TS_NESSUS_PASS"), false, false, 10)
  page.pack_start(load_entry("Nessus Policy ID:", "TS_NESSUS_POLICY"), false, false, 10)
end

def load_nexpose_page
  page = Gtk::VBox.new(false, 10)

  page.pack_start(load_toggle("Do you wish to connect to Nexpose?", "TS_NEXPOSE_CONNECT", "yes"), false, false, 10)
  page.pack_start(load_toggle("Do you wish to automatically scan with Nexpose?", "TS_NEXPOSE_AUTOSCAN", "yes"), false, false, 10)
  page.pack_start(load_entry("Nexpose Host:", "TS_NEXPOSE_HOST"), false, false, 10)
  page.pack_start(load_entry("Nexpose Port:", "TS_NEXPOSE_PORT"), false, false, 10)
  page.pack_start(load_entry("Nexpose Username:", "TS_NEXPOSE_USER"), false, false, 10)
  page.pack_start(load_entry("Nexpose Password:", "TS_NEXPOSE_PASS"), false, false, 10)
end

def load_openvas_page
  page = Gtk::VBox.new(false, 10)

  page.pack_start(load_toggle("Do you wish to connect to OpenVAS?", "TS_OPENVAS_CONNECT", "yes"), false, false, 10)
  page.pack_start(load_toggle("Do you wish to automatically scan with OpenVAS?", "TS_OPENVAS_AUTOSCAN", "yes"), false, false, 10)
  page.pack_start(load_entry("OpenVAS Host:", "TS_OPENVAS_HOST"), false, false, 10)
  page.pack_start(load_entry("OpenVAS Port:", "TS_OPENVAS_PORT"), false, false, 10)
  page.pack_start(load_entry("OpenVAS Username:", "TS_OPENVAS_USER"), false, false, 10)
  page.pack_start(load_entry("OpenVAS Password:", "TS_OPENVAS_PASS"), false, false, 10)
end

def load_autosploit_page
  page = Gtk::VBox.new(false, 10)

  page.pack_start(load_toggle("Do you wish to launch automated exploitation? (You need to have previously defined a scanner)?", "TS_AUTO_OWN", "yes"), false, false, 10)
  page.pack_start(load_entry("Concurrent Exploitation Threads:", "TS_AUTO_OWN_JOBS"), false, false, 10)
end

def load_irc_page
  page = Gtk::VBox.new(false, 10)

  page.pack_start(load_toggle("Do you wish to connect to an IRC server?", "TS_IRC", "yes"), false, false, 10)
  page.pack_start(load_entry("Nickname:", "TS_IRC_NICK"), false, false, 10)
  page.pack_start(load_entry("Server Host:", "TS_IRC_SERVER"), false, false, 10)
  page.pack_start(load_entry("Server Port:", "TS_IRC_PORT"), false, false, 10)
  page.pack_start(load_entry("Channel:", "TS_IRC_CHANNEL"), false, false, 10)
  page.pack_start(load_toggle("Do you wish to use SSL for your connection? (Server must support SSL)?", "TS_IRC_SSL", "yes"), false, false, 10)
end

def load_sploitwatch_page
  page = Gtk::VBox.new(false, 10)

  page.pack_start(load_toggle("Do you wish to automatically report activity through SploitWatch?", "TS_SPLOITWATCH", "yes"), false, false, 10)
  page.pack_start(load_entry("Player Handle:", "TS_SPLOITWATCH_HANDLE"), false, false, 10)
  page.pack_start(load_entry("Event Id:", "TS_SPLOITWATCH_EVENT"), false, false, 10)
  page.pack_start(load_entry("Server URI:", "TS_SPLOITWATCH_SRV_URI"), false, false, 10)
  page.pack_start(load_toggle("Do you wish to report all command being executed?", "TS_SPLOITWATCH_CMD_REPORT", "true"), false, false, 10)
end

def load_trojans_page
  scroll = Gtk::ScrolledWindow.new
  page = Gtk::VBox.new(false, 10)

  page.pack_start(load_toggle("Do you wish to generate trojans?", "TS_TROJAN", "yes"), false, false, 10)
  page.pack_start(load_entry("Trojan Path:", "TS_TROJAN_PATH"), false, false, 10)
  page.pack_start(load_entry("Trojan Password:", "TS_TROJAN_PASSWORD"), false, false, 10)
  page.pack_start(load_entry("Trojan Loader:", "TS_TROJAN_LOADER"), false, false, 10)
  page.pack_start(load_entry("Trojan Startup:", "TS_TROJAN_STARTUP"), false, false, 10)
  page.pack_start(load_entry("Persistence:", "TS_TROJAN_PERSIST"), false, false, 10)
  page.pack_start(load_entry("Hide:", "TS_TROJAN_HIDE"), false, false, 10)
  page.pack_start(load_entry("New Account:", "TS_TROJAN_ACCOUNT"), false, false, 10)
  page.pack_start(load_entry("New Account Password:", "TS_TROJAN_PASSWD"), false, false, 10)
  page.pack_start(load_entry("SSH Key:", "TS_TROJAN_SSHKEY"), false, false, 10)
  page.pack_start(load_entry("Reverse Port:", "TS_TROJAN_RE_PORT"), false, false, 10)

  scroll.add_with_viewport(page)
end

def load_server_page
  page = Gtk::VBox.new(false, 10)

  page.pack_start(load_toggle("Do you wish to run a TeamSploit MSFD Server?", "TS_SERVER", "yes"), false, false, 10)
  page.pack_start(load_entry("MSFD Port:", "TS_SERVER_MSFD_PORT"), false, false, 10)
  page.pack_start(load_entry("MSFRPCD Port", "TS_SERVER_MSFRPCD_PORT"), false, false, 10)
  page.pack_start(load_entry("MSFRPCD Username", "TS_SERVER_MSFRPCD_USER"), false, false, 10)
  page.pack_start(load_entry("MSFRPCD Password", "TS_SERVER_MSFRPCD_PASS"), false, false, 10)
end

def load_review_page
  page = Gtk::ScrolledWindow.new
  subpage = Gtk::VBox.new(false, 10)

  label = label = Gtk::Label.new("Please review, and if need be go back or modify the configuration below.")

  @config_pane = Gtk::TextView.new
  @config_pane.set_editable(true)
  @config_pane.set_cursor_visible(true)
  @config_pane.modify_font(Pango::FontDescription.new("Monospace 10"))
  @config_pane.buffer.text = build_config

  subpage.pack_start(label, false, false, 10)
  subpage.pack_start(@config_pane, true, true, 10)

  page.add_with_viewport(subpage)
end

def start_wizard
  load_config
  load_wizard
  load_page(load_intro_page, "TeamSploit Configuration", Gtk::Assistant::PAGE_INTRO, true)
  load_page(load_general_page, "General Settings", Gtk::Assistant::PAGE_CONTENT, true)
  load_page(load_database_page, "Database Settings", Gtk::Assistant::PAGE_CONTENT, true)
  load_page(load_msfd_page, "Shared Console", Gtk::Assistant::PAGE_CONTENT, true)
  load_page(load_teammates_page, "Team Mates", Gtk::Assistant::PAGE_CONTENT, true)
  load_page(load_targets_page, "Targets", Gtk::Assistant::PAGE_CONTENT, true)
  load_page(load_postexploit_page, "Post Exploitation", Gtk::Assistant::PAGE_CONTENT, true)
  load_page(load_nessus_page, "Nessus Configuration", Gtk::Assistant::PAGE_CONTENT, true)
  load_page(load_nexpose_page, "Nepose Configuration", Gtk::Assistant::PAGE_CONTENT, true)
  load_page(load_openvas_page, "OpenVAS Configuration", Gtk::Assistant::PAGE_CONTENT, true)
  load_page(load_autosploit_page, "Automated Exploitation", Gtk::Assistant::PAGE_CONTENT, true)
  load_page(load_irc_page, "Internet Relay Chat", Gtk::Assistant::PAGE_CONTENT, true)
  load_page(load_sploitwatch_page, "Tracking and Reporting", Gtk::Assistant::PAGE_CONTENT, true)
  load_page(load_trojans_page, "TeamSploit Trojans", Gtk::Assistant::PAGE_CONTENT, true)
  load_page(load_server_page, "TeamSploit MSFD Server", Gtk::Assistant::PAGE_CONTENT, true)
  review_page = load_page(load_review_page, "Review Configuration", Gtk::Assistant::PAGE_CONFIRM, true)

  @assistant.signal_connect('prepare') do |assistant, widget, last|
    @config_pane.buffer.text = build_config
  end

  @assistant.show_all
  Gtk.main
end

# Bring it all together now...
start_wizard
