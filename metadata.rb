name             "dnsmasq-pxe"
maintainer       "Mike Adolphs"
maintainer_email "mike@fooforge.com"
license          "Apache 2.0"
description      "Chef cookbook for configuring dnsmask to only answer PXE requests"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"
recommends       "pxe_dust", ">= 1.4.1"

%w{ ubuntu debian }.each do |os|
  supports os
end
