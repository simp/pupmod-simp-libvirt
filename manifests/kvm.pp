# Set up libvirt to use KVM.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class libvirt::kvm {
  include '::libvirt'

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

  if $facts['operatingsystem'] in ['RedHat', 'CentOS'] {
    $package_list = $facts['operatingsystemmajrelease'] ? {
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
    warning("${facts['operatingsystem']} not yet supported. Current options are RedHat and CentOS")
  }
  package { $package_list:
    ensure => 'latest',
    notify => Exec['kvm_mod_check']
  }

  # Enable Forwarding
  sysctl { 'net.ipv4.conf.all.forwarding':
    ensure => 'present',
    val    => '1'
  }
  sysctl { 'net.ipv4.ip_forward':
    ensure => 'present',
    val    => '1'
  }

  # Bypass the base hosts's IPTables
  sysctl { 'net.bridge.bridge-nf-call-arptables':
    ensure => 'present',
    val    => '0'
  }
  sysctl { 'net.bridge.bridge-nf-call-iptables':
    ensure => 'present',
    val    => '0'
  }

  # TODO: Make native boolean when we use facter 2.0
  if $facts['ipv6_enabled'] == true {
    sysctl { 'net.bridge.bridge-nf-call-ip6tables':
      ensure => 'present',
      val    => '0'
    }
  }
  else {
    sysctl { 'net.bridge.bridge-nf-call-ip6tables':
      ensure => 'absent'
    }
  }
}
