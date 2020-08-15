Redmine::Plugin.register :time_card do
  name 'Time Card plugin'
  author 'Kazuyuki Iwama'
  description 'A simple plug-in that records the punch in/out'
  version '1.0.0'

  menu :account_menu, :timecard, { :controller => 'time_card', :action => 'index' }, :caption => :plugin_title, :if => Proc.new { User.current.logged? }
end
