# Set up libvirt to use KVM
#
# @param package_list
#   List of packages to be managed for KVM
#
# @param package_ensure
# @param manage_sysctl
# @param load_kernel_modules
#
# @author https://github.com/simp/pupmod-simp-libvirt/graphs/contributors
#
class libvirt::kvm (
  $package_list       = [
    'libsndfile',
    'qemu-img',
    'qemu-kvm',
    'qemu-kvm-tools'
  ],
  $package_ensure      = $::libvirt::package_ensure,
  $manage_sysctl       = $::libvirt::manage_sysctl,
  $load_kernel_modules = $::libvirt::load_kernel_modules
) inherits libvirt {

  ensure_packages($package_list, { ensure => $package_ensure } )

  if $load_kernel_modules {
    $_kvm_kmod = $facts['cpuinfo']['processor0']['vendor_id'] ? {
      'AuthenticAMD' => 'kvm-amd',
      'GenuineIntel' => 'kvm-intel',
      default        => fail('libvirt: Unknown CPU vendor_id')
    }

    kmod::load { $_kvm_kmod:
      before => Package[$package_list]
    }
  }

  if $manage_sysctl {
    sysctl {
      default: ensure => 'present';

      # Enable Forwarding
      'net.ipv4.conf.all.forwarding': value => '1';
      'net.ipv4.ip_forward':          value => '1';
    }

    unless $facts['libvirt_br_netfilter_loaded'] {
      if $load_kernel_modules {
        kmod::load { 'br_netfilter': }

        Kmod::Load['br_netfilter'] -> Sysctl['net.bridge.bridge-nf-call-arptables']
        Kmod::Load['br_netfilter'] -> Sysctl['net.bridge.bridge-nf-call-iptables']

        if $facts['ipv6_enabled'] {
          Kmod::Load['br_netfilter'] -> Sysctl['net.bridge.bridge-nf-call-ip6tables']
        }
      }
    }

    sysctl {
      default: ensure => 'present';

      # Bypass the base hosts's IPTables
      'net.bridge.bridge-nf-call-arptables': value => '0';
      'net.bridge.bridge-nf-call-iptables':  value => '0';
    }

    if $facts['ipv6_enabled'] {
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
