service 'dnsmask' do
  supports :status => true, :restart => true, :reload => false, :enable => true, :disable => true

  action :start
end

template '/etc/dnsmasq.conf' do
  source 'dnsmasq.conf'
  owner 'root'
  group 'root'
  mode 0644

  variables node.dnsmask_pxe
  notifies :restart, 'service[dnsmask]', :delayed
end