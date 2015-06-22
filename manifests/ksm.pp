# == Class: libvirt::ksm
#
# A class to configure Kernel Shared Memory components.
# This isn't strictly tied to libvirt, but it's included in the qemu-kvm
# package so it made sense to include it here.
#
# Since there are no useful man pages at this time, the comments were lifted
# from the configuration files.
#
# == Parameters
#
# [*ksm_max_kernel_pages*]
#   The maximum number of unswappable kernel pages which may be allocated by
#   ksm (0 for unlimited) If unset, defaults to half of total memory.
#
# [*ksm_monitor_interval*]
#   The number of seconds ksmtuned should sleep between tuning adjustments
#   Every KSM_MONITOR_INTERVAL seconds ksmtuned adjust how aggressive KSM
#   will search for duplicated pages based on free memory.
#
# [*ksm_sleep_msec*]
#   Millisecond sleep between ksm scans for 16Gb server.  Smaller servers
#   sleep more, bigger sleep less.  How many Milliseconds to sleep between
#   scans of 16GB of RAM.  The actual sleep time is calculated as sleep =
#   KSM_SLEEP_MSEC * 16 / Total GB of RAM The final sleep value will be
#   written to /sys/kernel/mm/ksm/sleep_millisecs
#
# [*ksm_npages_boost*]
#   Amount to increment the number of pages to scan. The number of pages to
#   be scanned will be increased by KSM_NPAGES_BOOST when the amount of free
#   ram < threshold (see KSM_THRES_* below)
#
# [*ksm_npages_decay*]
#   Amount to decrease the number of pages to scan The number of pages to be
#   scanned will be decreased by KSM_NPAGES_DECAY when the amount of free ram
#   >= threshold (see KSM_THRES_* below)
#
# [*ksm_npages_min*]
#   Minimum number of pages to be scanned at all times
#   If this variable is set to 'shmall', then half of the value in
#   /proc/sys/kernel/shmall will be used.
#
# [*ksm_npages_max*]
#   Maximum number of pages to be scanned at all times
#   If this variable is set to 'shmall', then the value in
#   /proc/sys/kernel/shmall will be used.
#
# [*ksm_thres_coef*]
#   If free memory is less than this percentage KSM will be activated.
#   NOTE: Only KSM_THRES_CONST or KSM_THRES_COEF is actually used.  Whichever
#   results in a larger number wins.
#
# [*ksm_thres_const*]
#   If free memory is less than this number KSM will be activated
#   NOTE: Only KSM_THRES_CONST or KSM_THRES_COEF is actually used.  Whichever
#   results in a larger number wins.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class libvirt::ksm (
  $ksm_max_kernel_pages = '',
  $ksm_monitor_interval = '60',
  $ksm_sleep_msec = '100',
  $ksm_npages_boost = '3000',
  $ksm_npages_decay = '-50',
  $ksm_npages_min = 'shmall',
  $ksm_npages_max = 'shmall',
  $ksm_thres_coef = '10',
  $ksm_thres_const = ''
) {

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

  validate_integer($ksm_monitor_interval)
  validate_integer($ksm_sleep_msec)
  validate_integer($ksm_npages_boost)
  validate_re($ksm_npages_decay, '^-\d+$')
  validate_re($ksm_npages_min, '^(shmall|\d+)$')
  validate_re($ksm_npages_max, '^(shmall|\d+)$')
  validate_integer($ksm_thres_coef)
  if $ksm_thres_const != '' {
    validate_integer($ksm_thres_const)
  }
}
