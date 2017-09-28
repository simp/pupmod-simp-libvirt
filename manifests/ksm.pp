# A class to configure Kernel Shared Memory components.
# This isn't strictly tied to libvirt, but it's included in the qemu-kvm
# package so it made sense to include it here.
#
# Since there are no useful man pages at this time, the comments were lifted
# from the configuration files.
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
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class libvirt::ksm (
  Optional[Integer]               $ksm_max_kernel_pages = undef,
  Integer                         $ksm_monitor_interval = 60,
  Integer                         $ksm_sleep_msec       = 100,
  Integer                         $ksm_npages_boost     = 3000,
  Integer[default,0]              $ksm_npages_decay     = -50,
  Variant[Enum['shmall'],Integer] $ksm_npages_min       = 'shmall',
  Variant[Enum['shmall'],Integer] $ksm_npages_max       = 'shmall',
  Integer                         $ksm_thres_coef       = 10,
  Optional[Integer]               $ksm_thres_const      = undef
) {
  include 'libvirt::kvm'

  file { '/etc/ksmtuned.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('libvirt/ksmtuned.erb'),
    notify  => Service['ksmtuned']
  }

  file { '/etc/sysconfig/ksm':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('libvirt/ksm.erb'),
    notify  => Service['ksm']
  }

  service { 'ksm':
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['qemu-kvm']
  }

  service { 'ksmtuned':
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['qemu-kvm']
  }
}
