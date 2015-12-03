# == Class: libvirt::kvm
#
# Set up libvirt to use KVM.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class libvirt::kvm {
  include 'libvirt'
  include 'sysctl'

  exec { 'kvm_mod_check':
    command => '/usr/local/sbin/loadkvm.rb',
    require => File['/usr/local/sbin/loadkvm.rb'],
    before  => Service['libvirtd']
  }

  file { '/usr/local/sbin/loadkvm.rb':
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
    source => 'puppet:///modules/libvirt/loadkvm.rb'
  }

  if $::operatingsystem in ['RedHat', 'CentOS'] {
    $package_list = $::operatingsystemmajrelease ? {
      '7' => [
        'ipxe-roms',
        'ipxe-roms-qemu',
        'qemu-kvm',
        'qemu-kvm-tools',
        'qemu-img',
        'libsndfile'
      ],
      default => [
        'gpxe-roms',
        'gpxe-roms-qemu',
        'qemu-kvm',
        'qemu-kvm-tools',
        'qemu-img',
        'virt-v2v',
        'libsndfile'
      ]
    }
  }
  else {
    warning("$::operatingsystem not yet supported. Current options are RedHat and CentOS")
  }
  package { $package_list:
    ensure => 'latest',
    notify => Exec['kvm_mod_check']
  }

  # Enable Forwarding
  sysctl::value { 'net.ipv4.conf.all.forwarding': value => '1' }
  sysctl::value { 'net.ipv4.ip_forward': value => '1' }

  # Bypass the base hosts's IPTables
  sysctl::value { 'net.bridge.bridge-nf-call-arptables': value => '0' }
  sysctl::value { 'net.bridge.bridge-nf-call-iptables':  value => '0' }

  # TODO: Make native boolean when we use facter 2.0
  if $::ipv6_enabled == true {
    sysctl::value { 'net.bridge.bridge-nf-call-ip6tables': value => '0' }
  }
  else {
    sysctl::value { 'net.bridge.bridge-nf-call-ip6tables': value => 'nil' }
  }
}
