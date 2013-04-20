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
