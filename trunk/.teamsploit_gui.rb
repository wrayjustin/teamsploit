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

require 'rubygems'
require 'gtk2'
require '.gui/mdi'
require 'vte'
require 'webkit'
require 'open-uri'
require 'ponder'
require 'eventmachine'

# A TeamSploit MDI window.
class TeamSploitMDI < Gtk::Window

  def initialize
    super
    self.load_config
    @loaded_primaries = 0
    @pages = Array.new
    @version = `svn info | grep "Last Changed Rev:" | awk {' print $4 '}`
    @version.chomp!.strip!
    @gui_version = "0.04 Alpha"
    @notebook = Gtk::MDI::Notebook.new
    layout = Gtk::VBox.new( false, 0 )
    add(layout)
    menu = self.build_menubar
    layout.pack_start(menu, false, false, 0)
    layout.pack_start(@notebook, true, true, 0)
    set_title("TeamSploit (Rev:#{self.version})")
    set_size_request(800,600)
   self.build_menubar
  end

  def load_config
    @config = Hash.new
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
        end
      end
    end
  end

  def load
    primary_windows = @config['TS_WINDOWS'].to_i
    server = @config['TS_MSFD_CONNECT'].to_i
    chat = @config['TS_IRC'].to_i

   if primary_windows.nil? || primary_windows == 0
     primary_windows = 1
   end

    primary_windows.times do |i|
      num = i+1
      if num == 1
        self.load_primary(num)
      else
        self.load_primary_sub(num)
      end
    end

    if server == 1
      self.load_shared
    end

    self.load_listener

    if chat == 1
      self.load_chat
    end

    self.load_about

    @notebook.show_all
  end

  def build_menubar
    menu_bar = Gtk::MenuBar.new
    menu_bar.append(self.build_menubar_file)
    menu_bar.append(self.build_menubar_edit)
    menu_bar.append(self.build_menubar_help)

    return menu_bar
  end

  def build_menubar_file
    menu = Gtk::MenuItem.new( "File" )
    submenu = Gtk::Menu.new

    item1 = Gtk::MenuItem.new("New Primary Tab...")
    item1.signal_connect "activate" do
      self.load_primary_sub(@loaded_primaries + 1)
      @notebook.show_all
    end

    item2 = Gtk::MenuItem.new("New Browser Tab...")
    item2.signal_connect "activate" do
      browser = self.load_browser("http://www.teamsploit.com/")
      @notebook.add_document(Gtk::MDI::Document.new(browser, "Browser"))
      @pages.push(browser)
      @notebook.show_all
    end

    item3 = Gtk::MenuItem.new("Exit")
    item3.signal_connect "activate" do
      EventMachine::stop_event_loop
    end

    submenu.append(item1)
    submenu.append(item2)
    submenu.append(item3)
    menu.set_submenu(submenu)

   return menu
  end

  def build_menubar_edit
    menu = Gtk::MenuItem.new( "Edit" )
    submenu = Gtk::Menu.new

    item1 = Gtk::MenuItem.new("Copy")
    item1.signal_connect "activate" do
      if @pages[@notebook.page].is_a? Vte::Terminal
        @pages[@notebook.page].copy_primary
      end
    end

    item2 = Gtk::MenuItem.new("Paste")
    item2.signal_connect "activate" do
      if @pages[@notebook.page].is_a? Vte::Terminal
        @pages[@notebook.page].paste_primary
      end
    end

    submenu.append(item1)
    submenu.append(item2)
    menu.set_submenu(submenu)

   return menu
  end

  def build_menubar_help
    menu = Gtk::MenuItem.new( "Help" )
    submenu = Gtk::Menu.new

    item1 = Gtk::MenuItem.new("Help...")
    item1.signal_connect "activate" do
      self.load_help
      @notebook.show_all
    end

    item2 = Gtk::MenuItem.new("About...")
    item2.signal_connect "activate" do
      self.load_about
      @notebook.show_all
    end
    submenu.append(item1)
    submenu.append(item2)
    menu.set_submenu(submenu)

   return menu
  end

  def build_context_menu
    menu = Gtk::Menu.new
    item1 = Gtk::MenuItem.new("Copy")
    item1.signal_connect "activate" do
      if @pages[@notebook.page].is_a? Vte::Terminal
        @pages[@notebook.page].copy_primary
      end
    end

    item2 = Gtk::MenuItem.new("Paste")
    item2.signal_connect "activate" do
      if @pages[@notebook.page].is_a? Vte::Terminal
        @pages[@notebook.page].paste_primary
      end
    end

    menu.append(item1)
    menu.append(item2)
    menu.show_all

    return menu
  end

  def build_tab(command)
      tab = Gtk::ScrolledWindow.new
      tab.set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_ALWAYS)
      context = self.build_context_menu
      terminal = Vte::Terminal.new
      terminal.set_scrollback_lines(1000)
      terminal.set_font("Monospace 10", Vte::TerminalAntiAlias::FORCE_ENABLE)
      terminal.fork_command
      if command.nil?
        terminal.fork_command
      else
        terminal.feed_child(command + "\n")
      end
      terminal.signal_connect("child-exited") do |widget|
        widget.destroy
        self.remove(@notebook.page)
      end
      terminal.signal_connect("button_press_event") do |widget, event|
        if event.kind_of? Gdk::EventButton and event.button == 3
          context.popup(nil, nil, event.button, event.time)
        end
      end
      tab.add(terminal)
      @pages.push(terminal)

      return tab
  end

  def load_primary(num)
    tab = build_tab("sudo msfconsole -m .msf -r .teamsploit.rc.primary")
    @notebook.add_document(Gtk::MDI::Document.new(tab, "Primary #{num}"))
    @loaded_primaries += 1
  end

  def load_primary_sub(num)
    tab = build_tab("sudo msfconsole -m .msf -r .teamsploit.rc.primary.sub")
    @notebook.add_document(Gtk::MDI::Document.new(tab, "Primary #{num}"))
    @loaded_primaries += 1
  end

  def load_shared
    host = @config['TS_MSFD_HOST']
    port = @config['TS_MSFD_PORT']
    tab = build_tab("nc #{host} #{port}")
    @notebook.add_document(Gtk::MDI::Document.new(tab, "Shared"))
  end

  def load_listener
    tab = build_tab("sudo msfconsole -m .msf -r .teamsploit.rc.listener")
    @notebook.add_document(Gtk::MDI::Document.new(tab, "Listener"))
  end    

  def load_chat
    irc_nick = @config['TS_IRC_NICK']
    irc_srv = @config['TS_IRC_SERVER']
    irc_port = @config['TS_IRC_PORT']
    irc_chan = "#" + @config['TS_IRC_CHANNEL']
    irc_ssl = @config['TS_IRC_SSL']

    if irc_ssl == 0
      irc_ssl = false
    else
      irc_ssl = true
    end

    layout = Gtk::VBox.new( false, 0 )
    font = Pango::FontDescription.new("Monospace 10")

    chat_area = Gtk::HBox.new(false, 0)
 
    chat_box_win = Gtk::ScrolledWindow.new
    chat_box_win.set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_ALWAYS)

    chat_box = Gtk::TextView.new
    chat_box.set_editable(false)
    chat_box.set_cursor_visible(false)
    chat_box.modify_font(font)
    chat_box.buffer.text = "Chat Loading...Please Wait..."
    chat_box_win.add(chat_box)

    user_store = Gtk::TreeStore.new(String)

    user_list = Gtk::TreeView.new(user_store)
    user_list.set_size_request(100, 0)
    user_list.selection.mode = Gtk::SELECTION_NONE

    user_renderer = Gtk::CellRendererText.new
    user_col = Gtk::TreeViewColumn.new("Users", user_renderer, :text => 0)
    user_list.append_column(user_col)

    chat_area.pack_start(chat_box_win, true, true, 10)
    chat_area.pack_start(user_list, false, false, 10)

    msg_field = Gtk::Entry.new
    msg_field.modify_font(font)
    msg_field.signal_connect "key-release-event" do |widget, event|
      if event.kind_of? Gdk::EventKey  and event.keyval == 65293
        if !widget.text.empty?
          chat_box.scroll_to_iter(chat_box.buffer.get_iter_at_line(chat_box.buffer.line_count), 0, false, 0, 0)
          chat_box.buffer.insert(chat_box.buffer.get_iter_at_line(chat_box.buffer.line_count), "[#{irc_nick}]  " + widget.text + "\n")
          @irc.message(irc_chan, widget.text)
          msg_field.text = ""
          chat_box.scroll_to_iter(chat_box.buffer.get_iter_at_line(chat_box.buffer.line_count), 0, false, 0, 0)
        end
      end
    end

    layout.pack_start(chat_area, true, true, 10)
    layout.pack_start(msg_field, false, false, 10)

    self.load_irc(irc_nick, irc_srv, irc_port, irc_chan, irc_ssl)

    @irc.on :connect do
      @irc.join irc_chan
      chat_box.buffer.text = "Chat Loaded...Talking In #{irc_chan}\n"
      chat_box.scroll_to_iter(chat_box.buffer.get_iter_at_line(chat_box.buffer.line_count), 0, false, 0, 0)
    end

    @irc.on :channel do |event_data|
      chat_box.scroll_to_iter(chat_box.buffer.get_iter_at_line(chat_box.buffer.line_count), 0, false, 0, 0)
      chat_box.buffer.insert(chat_box.buffer.get_iter_at_line(chat_box.buffer.line_count), "[" + event_data[:nick] + "] " + event_data[:message] + "\n")
      chat_box.scroll_to_iter(chat_box.buffer.get_iter_at_line(chat_box.buffer.line_count), 0, false, 0, 0)
    end

    @irc.on :join do |event_data|
      user_store.clear
      @irc.raw("NAMES " + irc_chan)
    end

    @irc.on :part do |event_data|
      user_store.clear
      @irc.raw("NAMES " + irc_chan)
    end

    @irc.on 353 do |event_data|
      user_store.clear
      users = event_data[:params].split(/=/)[1].rstrip.lstrip.split(/\s+/).drop(1)
      users.each do |user|
        user.gsub!(/:/, '') if user =~ /:/
        newuser = user_store.append(nil)
        newuser[0] = user
      end        
    end

    @irc.on 332 do |event_data|
      chat_box.buffer.insert_at_cursor("[ -TOPIC- ] " + event_data[:params] + "\n")
      chat_box.scroll_to_iter(chat_box.buffer.get_iter_at_line(chat_box.buffer.line_count), 0, false, 0, 0)
    end

    @irc.on :topic do |event_data|
      chat_box.buffer.insert_at_cursor("[ -TOPIC- ] " + event_data[:topic] + "\n")
      chat_box.scroll_to_iter(chat_box.buffer.get_iter_at_line(chat_box.buffer.line_count), 0, false, 0, 0)
    end
   
    @notebook.add_document(Gtk::MDI::Document.new(layout, "Chat"))
  end

  def load_about
    about = Gtk::TextView.new
    about.set_editable(false)
    about.set_cursor_visible(false)
    font = Pango::FontDescription.new("Monospace 10")
    about.modify_font(font)
    about.buffer.text = 
      "___________                     _________      .__         .__  __   \n" +
      "\__    ___/___ _____    _____  /   _____/_____ |  |   ____ |__|/  |_ \n" +
      "  |    |_/ __ \\__  \  /     \ \_____  \\____ \|  |  /  _ \|  \   __ \n" +
      "  |    |\  ___/ / __ \|  Y Y  \/        \  |_> >  |_(  <_> )  ||  |  \n" +
      "  |____| \___  >____  /__|_|  /_______  /   __/|____/\____/|__||__|  \n" +
      "             \/     \/      \/        \/|__|  By:  Justin M. Wray    \n" +
      "\n" +
      "=====================================================================\n" +
      "\n" +
      "Copyrighted:  Justin M. Wray (wray.justin@gmail.com)\n" + 
      "\n" +
      "License:\n" +
      "    This program is free software: you can redistribute it and/or modify\n" +
      "    it under the terms of the GNU General Public License as published by\n" +
      "    the Free Software Foundation, either version 3 of the License, or\n" +
      "    (at your option) any later version.\n" +
      "\n" +
      "    This program is distributed in the hope that it will be useful,\n" +
      "    but WITHOUT ANY WARRANTY; without even the implied warranty of\n" +
      "    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n" +
      "    GNU General Public License for more details.\n" +
      "\n" +
      "    You should have received a copy of the GNU General Public License\n" +
      "    along with this program.  If not, see <http://www.gnu.org/licenses/>.\n" +
      "\n" +
      "=====================================================================\n" +
      "\n" +
      "TeamSploit Version: #{@version}\n" +
      "GUI Version: #{@gui_version}\n" +
      "\n" +
      "Website:  http://www.teamsploit.com\n"
    @notebook.add_document(Gtk::MDI::Document.new(about, "About"))
    @pages.push(about)
  end

  def load_help
    help = load_browser("http://www.teamsploit.com/faq.php")
    @notebook.add_document(Gtk::MDI::Document.new(help, "Help"))
    @pages.push(help)
  end

  def load_browser(url)
    layout = Gtk::VBox.new( false, 0 )
    url_area = Gtk::HBox.new(false, 0)
    font = Pango::FontDescription.new("Monospace 10")

    browser = WebKit::WebView.new
    browser.open(url)

    url_box = Gtk::Entry.new
    url_box.modify_font(font)
    url_box.signal_connect "key-release-event" do |widget, event|
      if event.kind_of? Gdk::EventKey  and event.keyval == 65293
        if !widget.text.empty?
          browser.open(widget.text)
        end
      end
    end

    browser.signal_connect "navigation-policy-decision-requested"  do |widget, event, request|
      url_box.text = request.uri
      p
    end

    search_box = Gtk::Entry.new
    search_box.modify_font(font)
    search_box.signal_connect "key-release-event" do |widget, event|
      if event.kind_of? Gdk::EventKey  and event.keyval == 65293
        if !widget.text.empty?
          browser.open("http://www.google.com/search?btnG=1&pws=0&q=" + URI::encode(widget.text))
        end
      end
    end

    url_box.text = url
    search_box.text = "Search Google..."

    url_area.pack_start(url_box, true, true, 10)
    url_area.pack_start(search_box, false, false, 10)

    layout.pack_start(url_area, false, false, 10)
    layout.pack_start(browser, true, true, 10)

    return layout
  end

  def remove(page)
    @notebook.remove_page(page)
  end

  def load_irc(irc_nick, irc_srv, irc_port, irc_chan, irc_ssl)
    @irc = Ponder::Thaum.new do |config|
      config.server = irc_srv
      config.port = irc_port
      config.nick = irc_nick
      config.username = 'TeamSploit'
      config.real_name = 'TeamSploit'
      config.ssl = irc_ssl
      config.verbose = false
    end
  end

  def irc_connect
    if @config['TS_IRC'].to_i == 1
      @irc.connect
    end
  end

  attr_reader :notebook
  attr_accessor :config, :version, :gui_version, :loaded_primaries, :pages, :irc
end

class TeamSploitGUI  
  def initialize
    # Initialize GTK
    Gtk::init

    # Initialize the MDI controller with our window class and the 
    # symbol of the attribute used to access the notebook
    controller = Gtk::MDI::Controller.new(TeamSploitMDI, :notebook)
    # Quit once all windows have been closed
    controller.signal_connect('window_removed') do |controller, window, last|
      if last
        EventMachine::stop_event_loop
      end
    end

    @teamsploit = controller.open_window
    @teamsploit.notebook.set_tab_pos(Gtk::POS_BOTTOM)
    @teamsploit.load
  end

  def chat_connect
    @teamsploit.irc_connect
  end

  def load_window
    Gtk::main
  end

  attr_accessor :teamsploit
end

EM::run do
  client = TeamSploitGUI.new
  client.chat_connect
  give_tick = proc { Gtk::main_iteration; EM.next_tick(give_tick); }
  give_tick.call
end
