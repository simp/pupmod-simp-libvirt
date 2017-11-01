# Set up libvirt.  Install the necessary packages and make sure libvirtd is
# running.
#
# The easiest way to obtain all package dependencies for libvirt is to
# unpack the distribution ISO that corresponds with your flavor of SIMP.
# SIMP provides a utility for exactly that, `/usr/local/bin/unpack_dvd`
#
# @param package_list List of packages related to libvirt to be managed
# @param service_ensure Ensure setting for libvirtd
# @param ksm Enable management of ksm
# @param kvm Enable management of kvm
# @param load_kernel_modules Enable management of kernel modules in this module
#
# @param ksm_max_kernel_pages
#   The maximum number of unswappable kernel pages which may be allocated by
#   ksm (0 for unlimited) If unset, defaults to half of total memory.
#
# @param ksm_monitor_interval
#   The number of seconds ksmtuned should sleep between tuning adjustments
#   Every KSM_MONITOR_INTERVAL seconds ksmtuned adjust how aggressive KSM
#   will search for duplicated pages based on free memory.
#
# @param ksm_sleep_msec
#   Millisecond sleep between ksm scans for 16Gb server.  Smaller servers
#   sleep more, bigger sleep less.  How many Milliseconds to sleep between
#   scans of 16GB of RAM.  The actual sleep time is calculated as sleep =
#   KSM_SLEEP_MSEC * 16 / Total GB of RAM The final sleep value will be
#   written to /sys/kernel/mm/ksm/sleep_millisecs
#
# @param ksm_npages_boost
#   Amount to increment the number of pages to scan. The number of pages to
#   be scanned will be increased by KSM_NPAGES_BOOST when the amount of free
#   ram < threshold (see KSM_THRES_* below)
#
# @param ksm_npages_decay
#   Amount to decrease the number of pages to scan The number of pages to be
#   scanned will be decreased by KSM_NPAGES_DECAY when the amount of free ram
#   >= threshold (see KSM_THRES_* below)
#
# @param ksm_npages_min
#   Minimum number of pages to be scanned at all times
#   If this variable is set to 'shmall', then half of the value in
#   /proc/sys/kernel/shmall will be used.
#
# @param ksm_npages_max
#   Maximum number of pages to be scanned at all times
#   If this variable is set to 'shmall', then the value in
#   /proc/sys/kernel/shmall will be used.
#
# @param ksm_thres_coef
#   If free memory is less than this percentage KSM will be activated.
#   NOTE: Only KSM_THRES_CONST or KSM_THRES_COEF is actually used.  Whichever
#   results in a larger number wins.
#
# @param ksm_thres_const
#   If free memory is less than this number KSM will be activated
#   NOTE: Only KSM_THRES_CONST or KSM_THRES_COEF is actually used.  Whichever
#   results in a larger number wins.
#
# @param kvm_package_list List of packages related to kvm to be managed
# @param manage_sysctl Disable to avoid setting sysctl settings in this module.
# @param package_ensure Ensure setting for all packages in this module
#
# @author https://github.com/simp/pupmod-simp-libvirt/graphs/contributors
#
class libvirt (
  Array[String] $package_list,
  String $service_ensure,
  Boolean $ksm,
  Boolean $kvm,
  Boolean $load_kernel_modules,

  # KSM
  Optional[Integer]               $ksm_max_kernel_pages,
  Integer                         $ksm_monitor_interval,
  Integer                         $ksm_sleep_msec,
  Integer                         $ksm_npages_boost,
  Integer[default,0]              $ksm_npages_decay,
  Variant[Enum['shmall'],Integer] $ksm_npages_min,
  Variant[Enum['shmall'],Integer] $ksm_npages_max,
  Integer                         $ksm_thres_coef,
  Optional[Integer]               $ksm_thres_const,

  # KVM
  Array[String] $kvm_package_list,
  Boolean $manage_sysctl,

  String $package_ensure = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
) {

  if $kvm { include 'libvirt::kvm' }

  # This is a workaround until we can afford a breaking change to disallow
  # calling the ksm class by itself
  if $ksm {
    class { 'libvirt::ksm':
      ksm_max_kernel_pages => $ksm_max_kernel_pages,
      ksm_monitor_interval => $ksm_monitor_interval,
      ksm_sleep_msec       => $ksm_sleep_msec,
      ksm_npages_boost     => $ksm_npages_boost,
      ksm_npages_decay     => $ksm_npages_decay,
      ksm_npages_min       => $ksm_npages_min,
      ksm_npages_max       => $ksm_npages_max,
      ksm_thres_coef       => $ksm_thres_coef,
      ksm_thres_const      => $ksm_thres_const,
    }
  }

  package { $package_list: ensure => $package_ensure }

  service { 'libvirtd':
    ensure     => $service_ensure,
    enable     => true,
    require    => Package['libvirt']
  }
}
