# Install the necessary packages and make sure ``libvirtd`` is running
#
# @param package_list
#   List of packages related to libvirt to be managed
#
# @param service_ensure
#   ``ensure`` setting for libvirtd
#
# @param ksm
#   Manage Kernel Shared Memory
#
# @param kvm
#   Manage ``kvm``
#
# @param load_kernel_modules
#   Manage kernel modules from this module
#
# @param manage_sysctl
#   Manage associated sysctl settings from this module
#
# @param package_ensure
#   Ensure setting for all packages in this module
#
# @author https://github.com/simp/pupmod-simp-libvirt/graphs/contributors
#
class libvirt (
  Array[String]  $package_list        = [
    'virt-viewer'
  ],
  String         $service_ensure      = running,
  Boolean        $ksm                 = false,
  Boolean        $kvm                 = true,
  Boolean        $load_kernel_modules = true,
  Boolean        $manage_sysctl       = true,
  String         $package_ensure      = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' })
) {

  simplib::assert_metadata($module_name)

  ensure_packages( $package_list, { ensure => $package_ensure } )

  if $kvm { include 'libvirt::kvm' }
  if $ksm { include 'libvirt::ksm' }

  package { 'libvirt':
    ensure => $package_ensure
  }

  service { 'libvirtd':
    ensure    => $service_ensure,
    enable    => true,
    subscribe => Package['libvirt']
  }
}
