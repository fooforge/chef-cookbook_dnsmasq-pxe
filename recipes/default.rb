file '/etc/resolvconf/update.d/dnsmasq' do
  action :delete
end

cookbook_file "/etc/default/dnsmasq.conf" do
  source "defaults"
  owner 'root'
  group 'root'
  mode  0644

end

cookbook_file "/etc/init.d/dnsmasq" do
  source "init_script.sh"
  owner 'root'
  group 'root'
  mode  0755

end

service 'dnsmasq' do
  supports :status => true, :restart => true, :reload => false, :enable => true, :disable => true

  action :start
end

template '/etc/dnsmasq.conf' do
  source 'dnsmasq.conf.erb'
  owner 'root'
  group 'root'
  mode 0644

  variables node.dnsmasq_pxe
  notifies :restart, 'service[dnsmasq]', :delayed
end
