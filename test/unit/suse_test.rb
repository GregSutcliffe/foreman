require 'test_helper'

class SuseTest < ActiveSupport::TestCase

  #-suse:
  #-  type: Host::Managed
  #-  name: suse01.yourdomain.net
  #-  ip: 2.3.4.205
  #-  mac: ad:bb:cc:da:ae:ff
  #-  environment: production
  #-  architecture: x86_64
  #-  build: true
  #-  ptable: suse
  #-  domain: yourdomain
  #-  medium: suse
  #-  operatingsystem: suse
  #-  subnet: one
  #-  puppet_proxy: puppetmaster
  #-  compute_resource: one
  #-  root_pass: xybxa6JUkz63w
  #-  provision_method: build

  test "os label for suse" do
    assert_equal "OpenSuse 11.4", operatingsystems(:suse).to_label
  end

  test "pxedir for suse" do
   assert_equal "boot/$arch/loader", operatingsystems(:suse).pxedir
  end

  test "kernel location for 64bit arch suse" do
    host = FactoryGirl.create(:host, :operatingsystem => operatingsystems(:suse),
                              :architecture => architectures(:x86_64))
    assert_equal "boot/OpenSuse-11.4-x86_64-linux", host.os.kernel(host.arch)
  end

  test "initrd location for 64bit arch suse" do
    host = FactoryGirl.create(:host, :operatingsystem => operatingsystems(:suse),
                              :architecture => architectures(:x86_64))
    assert_equal "boot/OpenSuse-11.4-x86_64-initrd", host.os.initrd(host.arch)
  end

  test "pxe prefix for suse" do
    host = FactoryGirl.create(:host, :operatingsystem => operatingsystems(:suse),
                              :architecture => architectures(:x86_64))
    prefix = host.os.pxe_prefix(host.arch)
    assert_equal "boot/OpenSuse-11.4-x86_64", prefix
  end

  test "pxe files for suse" do
    host = FactoryGirl.create(:host, :with_medium,
                              :operatingsystem => operatingsystems(:suse),
                              :architecture => architectures(:x86_64),
                              :medium => media(:suse) )
    host.medium.operatingsystems << host.os
    host.arch.operatingsystems << host.os

    prefix = host.os.pxe_prefix(host.arch).to_sym

    kernel = { prefix => "http://mirror.isoc.org.il/pub/opensuse/distribution/11.4/repo/oss/boot/x86_64/loader/linux"  }
    initrd = { prefix => "http://mirror.isoc.org.il/pub/opensuse/distribution/11.4/repo/oss/boot/x86_64/loader/initrd" }
    assert host.os.pxe_files(host.medium, host.arch).include?(kernel)
    assert host.os.pxe_files(host.medium, host.arch).include?(initrd)
  end

end
