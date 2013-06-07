# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Requires Ruby1.9 and a _clean_ database
# Hosts will not be savable if edited as the proxy added does not really exist
# Do not set num_hosts > available IPs in your subnet

# Libs
require 'facter'
require 'mocha/setup'

### BEGIN EDITABLE DATA ###
num_hosts = 100
subnet_interface = 'em1'

operating_systems = [
  { :name => 'RedHat', :major => '6', :minor => '4', :type => 'Redhat' },
  { :name => 'RedHat', :major => '5', :minor => '8', :type => 'Redhat' },
  { :name => 'CentOS', :major => '6', :minor => '4', :type => 'Redhat' },
  { :name => 'CentOS', :major => '5', :minor => '8', :type => 'Redhat' },
  { :name => 'Fedora', :major => '18', :type => 'Redhat' },
  { :name => 'Fedora', :major => '17', :type => 'Redhat' },
  { :name => 'Debian', :major => '6', :minor => '0', :type => 'Debian', :release_name => 'squeeze' },
  { :name => 'Debian', :major => '7', :minor => '0', :type => 'Debian', :release_name => 'wheezy' },
  { :name => 'Ubuntu', :major => '10', :minor => '04', :type => 'Debian', :release_name => 'lucid' },
  { :name => 'Ubuntu', :major => '12', :minor => '04', :type => 'Debian', :release_name => 'precise' },
]
### END EDITABLE DATA ###

#This disables the DNS/DHCP orchestration
#Resolv::DNS.any_instance.stubs(:getname).returns('foo.fqdn')
#Resolv::DNS.any_instance.stubs(:getaddress).returns('127.0.0.1')
#Net::DNS::ARecord.any_instance.stubs(:conflicts).returns([])
#Net::DNS::ARecord.any_instance.stubs(:conflicting?).returns(false)
#Net::DNS::PTRRecord.any_instance.stubs(:conflicting?).returns(false)
#Net::DNS::PTRRecord.any_instance.stubs(:conflicts).returns([])
#Net::DHCP::Record.any_instance.stubs(:create).returns(true)
#Net::DHCP::SparcRecord.any_instance.stubs(:create).returns(true)
#Net::DHCP::Record.any_instance.stubs(:conflicting?).returns(false)
#ProxyAPI::Puppet.any_instance.stubs(:environments).returns(['production'])
#ProxyAPI::DHCP.any_instance.stubs(:unused_ip).returns('127.0.0.1')

# Set correct hostname
Setting[:foreman_url] = Facter.fqdn

# Basics...
loc=Location.create :name => 'Default'
org=Organization.create :name => 'Default'
loc.organizations = Organization.all ; loc.save
org.locations = Location.all ; org.save

env = Environment.create :name => 'production'
env.locations = Location.all
env.organizations = Organization.all

# Stub out a fake proxy
ProxyAPI::Features.any_instance.stubs(:features).returns(['puppet','puppetca','dns','dhcp','tftp'])
# Https will fail due to missing/unreadable cert files
sp=SmartProxy.create(:name => 'Test Proxy', :url => "http://#{Facter.fqdn}:8443/")
sp.locations = Location.all
sp.organizations = Organization.all
sp.save

operating_systems.each do |data|
  os = Operatingsystem.create(:name => data[:name], :major => data[:major])
  os.minor = data[:minor] || ''
  os.release_name = data[:release_name] if data[:release_name]
  os.type = data[:type]
  os.save
end

# Some Installation Media come as standard
Medium.create(:name => 'RHEL mirror', :path => 'http://mirror.example.com/rhel/$major.$minor/os/$arch', :os_family => 'Redhat', :operatingsystems => Operatingsystem.where(:name => 'RedHat'))
Medium.create(:name => 'Debian mirror', :path => 'http://ftp.debian.org/debian', :os_family => 'Debian', :operatingsystems => Operatingsystem.where(:name => 'Debian'))
Medium.find_by_name('CentOS mirror').update_attributes({:os_family => 'Redhat', :operatingsystems => Operatingsystem.where(:name => 'CentOS') })
Medium.find_by_name('Fedora Mirror').update_attributes({:os_family => 'Redhat', :operatingsystems => Operatingsystem.where(:name => 'Fedora')})
Medium.find_by_name('Ubuntu Mirror').update_attributes({:os_family => 'Debian', :operatingsystems => Operatingsystem.where(:name => 'Ubuntu')})
Medium.all.each { |m| m.locations = Location.all ; m.organizations = Organization.all ; m.save }

# Architectures
['x86_64','i386'].each do |name|
  arch                  = Architecture.create(:name => name)
  arch.operatingsystems = Operatingsystem.all
  arch.save
end

# Domains
d               = Domain.create(:name => Facter.domain, :fullname => Facter.domain)
d.dns           = Feature.find_by_name('DNS').smart_proxies.first
d.locations     = Location.all
d.organizations = Organization.all
d.save

# Subnets - use Import Subnet code
s               = Subnet.create(:name => Facter.domain)
network         = (Facter.send("network_#{subnet_interface}") || '192.168.122.0')
s.network       = network
mask            = (Facter.send("netmask_#{subnet_interface}") || '255.255.255.0')
s.mask          = mask
s.dhcp          = Feature.find_by_name('DHCP').smart_proxies.first
s.dns           = Feature.find_by_name('DNS').smart_proxies.first
s.tftp          = Feature.find_by_name('TFTP').smart_proxies.first
s.locations     = Location.all
s.organizations = Organization.all
s.domains       = [d]
s.save

# Templates - all of this is fake template data
## Partitions
ptr   = Ptable.find_or_initialize_by_name 'RedHat Disk Layout'
data = {
  :layout           => 'put a real template here',
  :os_family        => 'Redhat'
}
ptr.update_attributes(data)
ptr.save
ptd   = Ptable.find_or_initialize_by_name 'Debian Disk Layout'
data = {
  :layout           => 'put a real template here',
  :os_family        => 'Debian'
}
ptd.update_attributes(data)
ptd.save
Operatingsystem.where(:type=>'Redhat').each {|o| o.ptables = [ptr] ; o.save}
Operatingsystem.where(:type=>'Debian').each {|o| o.ptables = [ptd] ; o.save}

# PXE
pxe = ConfigTemplate.find_or_initialize_by_name 'PXE Template'
data = {
  :template         => 'put a real template here',
  :snippet          => false,
  :template_kind_id => TemplateKind.find_by_name("PXELinux").id
}
pxe.update_attributes(data)
pxe.locations = Location.all
pxe.organizations = Organization.all
pxe.operatingsystems = Operatingsystem.all
pxe.save
Operatingsystem.all.each {|o| o.os_default_templates.build(:template_kind_id => TemplateKind.find_by_name('PXELinux').id, :config_template_id => pxe.id) ; o.save }

# Provision
prov = ConfigTemplate.find_or_initialize_by_name 'Provision Template'
data = {
  :template         =>  'put a real template here',
  :snippet          => false,
  :template_kind_id => TemplateKind.find_by_name("provision").id
}
prov.update_attributes(data)
prov.organizations = Organization.all
prov.operatingsystems = Operatingsystem.all
prov.operatingsystems = Operatingsystem.all
prov.save
Operatingsystem.all.each {|o| o.os_default_templates.build(:template_kind_id => TemplateKind.find_by_name('provision').id, :config_template_id => pxe.id) ; o.save }

## Hostgroups
hg = Hostgroup.create :name => "Base"
hg.environment = Environment.find_by_name('production')
hg.locations = Location.all
hg.organizations = Organization.all
hg.save

# Add some Hosts
Host.any_instance.stubs(:boot_server).returns('boot_server')
Host.any_instance.stubs(:queue_dhcp).returns(true)
Host.any_instance.stubs(:queue_dns).returns(true)
Host.any_instance.stubs(:queue_tftp).returns(true)

iprange=IPAddr.new("#{network}/#{mask}").to_range.to_a

Range.new(1,num_hosts).each do |index|
  h=Host.create(:name => "test_#{index}.#{Facter.domain}")
  h.managed = true
  h.hostgroup = hg
  h.location = loc
  h.organization = org
  h.puppet_proxy = sp
  h.puppet_ca_proxy = sp
  h.environment = env
  h.mac = (1..6).map{"%0.2X"%rand(256)}.join(":")
  h.domain = d
  h.subnet = s
  h.ip = iprange.delete(iprange.first).to_s
  h.arch = Architecture.all.sample
  h.operatingsystem = Operatingsystem.all.sample
  h.last_report = Time.at((1.hour.ago.to_f - Time.now.to_f)*rand + Time.now.to_f)
  h.save
end
