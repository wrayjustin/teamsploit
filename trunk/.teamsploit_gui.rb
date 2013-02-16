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
require '.gui/mdi'
require 'vte'

# A TeamSploit MDI window.
class TeamSploitMDI < Gtk::Window

  def initialize
    super
    @primary_windows = Integer(ARGV[0])
    @loaded_primaries = 0
    @pages = Array.new
    @version = `svn info | grep "Last Changed Rev:" | awk {' print $4 '}`
    @version.chomp!.strip!
    @gui_version = "0.01 Alpha"
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

  def load
    server = ARGV[1]

   if @primary_windows.nil? || @primary_windows == 0
     @primary_windows = 1
   end

    @primary_windows.times do |i|
      num = i+1
      if num == 1
        self.load_primary(num)
      else
        self.load_primary_sub(num)
      end
    end

    unless server.nil?
      self.load_shared
    end

    self.load_listener
    self.load_chat
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

    item2 = Gtk::MenuItem.new("Exit")
    item2.signal_connect "activate" do
      Gtk.main_quit
    end

    submenu.append(item1)
    submenu.append(item2)
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
      terminal.set_font("Monospace 10", Vte::TerminalAntiAlias::FORCE_ENABLE)
      terminal.fork_command
      terminal.feed_child(command + "\n")
      terminal.signal_connect("child-exited") do |widget|
        widget.destroy
        self.remove(@notebook.page)
      end
      terminal.signal_connect("button_press_event") do |widget, event|
        if event.kind_of? Gdk::EventButton and event.button == 3
          context.popup(nil, nil, event.button, event.time)
        end
      end
      tab.add_with_viewport(terminal)
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
    tab = build_tab(nil)
    @notebook.add_document(Gtk::MDI::Document.new(tab, "Shared"))
  end

  def load_listener
    tab = build_tab("sudo msfconsole -m .msf -r .teamsploit.rc.listener")
    @notebook.add_document(Gtk::MDI::Document.new(tab, "Listener"))
  end    

  def load_chat
    tab = build_tab(nil)
    @notebook.add_document(Gtk::MDI::Document.new(tab, "Chat"))
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
    help = Gtk::TextView.new
    help.set_editable(false)
    help.set_cursor_visible(false)
    font = Pango::FontDescription.new("Monospace 10")
    help.modify_font(font)
    help.buffer.text = "Help Documentation Goes Here..."
    @notebook.add_document(Gtk::MDI::Document.new(help, "Help"))
    @pages.push(help)
  end

  def remove(page)
    @notebook.remove_page(page)
  end

  attr_reader :notebook
  attr_accessor :version, :gui_version, :primary_windows, :loaded_primaries, :pages
end

# Initialize GTK
Gtk::init

controller = Gtk::MDI::Controller.new(TeamSploitMDI, :notebook)
controller.signal_connect('window_removed') do |controller, window, last|
  Gtk::main_quit if last
end

teamsploit = controller.open_window
teamsploit.notebook.set_tab_pos(Gtk::POS_BOTTOM)
teamsploit.load

# Start it all up
Gtk::main
