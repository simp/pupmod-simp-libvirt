# == Class: libvirt
#
# Set up libvirt.  Install the necessary packages and make sure libvirtd is
# running.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class libvirt {

  if $::operatingsystem in ['RedHat', 'CentOS'] {
    $package_list = $::lsbmajdistrelease ? {
      '7'     => ['libvirt', 'virt-viewer', 'virt-install'],
      default => ['libvirt', 'virt-viewer', 'python-virtinst']
    }
  }
  else {
    warning("$::operatingsystem not yet supported. Current supported options are RedHat and CentOS.")
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
