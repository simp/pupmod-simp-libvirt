# Set up libvirt to use KVM.
#
# @author https://github.com/simp/pupmod-simp-libvirt/graphs/contributors
#
class libvirt::kvm {
  include 'libvirt'

  $kvm_package_list = $::libvirt::kvm_package_list
  $package_ensure   = $::libvirt::package_ensure
  $manage_sysctl    = $::libvirt::manage_sysctl
  $load_kernel_modules = $::libvirt::load_kernel_modules

  package { $kvm_package_list:
    ensure => $package_ensure,
  }

  if $load_kernel_modules {
    $cpuvendor = $facts['cpuinfo']['processor0']['vendor_id']
    $kmod = $cpuvendor ? {
      'AuthenticAMD' => 'kvm-amd',
      'GenuineIntel' => 'kvm-intel',
      default        => fail('libvirt: Unknown CPU vendor_id')
    }
    kmod::load { $kmod:
      before => Package[$kvm_package_list]
    }
  }

  if $manage_sysctl {
    sysctl {
      default: ensure => 'present';

      # Enable Forwarding
      'net.ipv4.conf.all.forwarding': value => '1';
      'net.ipv4.ip_forward':          value => '1';

      # Bypass the base hosts's IPTables
      'net.bridge.bridge-nf-call-arptables': value => '0';
      'net.bridge.bridge-nf-call-iptables':  value => '0';
    }

    # TODO: Make native boolean when we use facter 2.0
    if $facts['ipv6_enabled'] == true {
      sysctl { 'net.bridge.bridge-nf-call-ip6tables':
        ensure => 'present',
        value  => '0'
      }
    }
    else {
      sysctl { 'net.bridge.bridge-nf-call-ip6tables':
        ensure => 'absent'
      }
    }
  }
}
