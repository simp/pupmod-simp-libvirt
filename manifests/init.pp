# Set up libvirt.  Install the necessary packages and make sure libvirtd is
# running.
#
# The easiest way to obtain all package dependencies for libvirt is to
# unpack the distribution ISO that corresponds with your flavor of SIMP.
# SIMP provides a utility for exactly that, `/usr/local/bin/unpack_dvd`
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class libvirt {

  if $facts['operatingsystem'] in ['RedHat', 'CentOS'] {
    $package_list = $facts['operatingsystemmajrelease'] ? {
      '7'     => ['libvirt', 'virt-viewer', 'virt-install'],
      default => ['libvirt', 'virt-viewer', 'python-virtinst']
    }
  }
  else {
    warning("${facts['operatingsystem']} not yet supported. Current supported options are RedHat and CentOS.")
  }

  package { $package_list: ensure => 'latest' }

  service { 'libvirtd':
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['libvirt']
  }
}
