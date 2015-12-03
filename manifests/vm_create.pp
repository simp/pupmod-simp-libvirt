# == Define: libvirt::vm_create
#
# No '/' in the name!
#
# The options in the vm_create() define use the exact same field syntax as
# the virt-install command.
#
# See virt-install(1) for variable details.
#
# If virbr0 doesn't do what you need it to, you may need to set up your own
# bridge using the networking module.
# If you do set up your own bridge, make sure your call of this define
# 'require's that network stanza.
#
# == Examples
#
#  libvirt::vm_create { 'test_system':
#     mac_addr => 'AA:BB:CC:DD:EE:FF',
#     size => '20',
#     networks => { 'type' => 'bridge', target =>  'br0' },
#     pxe => true,
#     disk_opts => { 'bus' => 'virtio' }
#  }
#
# == Parameters
#
# [*name*]
#   Used to name the /usr/sbin/vm-create script
#
# [*size*]
# [*mac_addr*]
# [*sparse*]
# [*mem*]
# [*arch*]
# [*machine*]
# [*ostype*]
# [*osvariant*]
# [*bridge*]
#   A legacy option for connecting to a single bridge. '$bridges' is now the
#   favored option.
#
# [*networks*]
#   An array of hashes of networks where you can specify both the mac and
#   model of each network if desired.
#
#   This option overrides '$bridge'
#
#   Example:
#     [
#       {
#         'type'    => 'bridge',
#         'target'  => '<bridge>',
#         'mac'     => '<macaddr>', # Optional
#         'model'   => '<model>', # Optional
#       },
#       {
#         'type'    => 'network'
#         'target'  => '<network1>',
#         'mac'     => '<macaddr>', # Optional
#         'model'   => '<model>', # Optional
#       }
#     ]
#
# [*vcpus*]
# [*vcpu_options*]
#   A hash of options that match the vcpus extended arguments.
#   Options will be passed directly and without translation.
#   Example:
#     { 'maxvcpus' => '3', 'sockets' => '2' }
#
# [*numatune*]
#   A hash of options that correspond to the numatune options.
#   Example:
#     { 'nodeset' => '1,2,3', 'mode' => 'preferred' }
#
# [*cpu*]
#   A hash of the 'cpu' options:
#     {
#       'name'      => '<cpu_name>',
#       'features'  => ['+<feature>','-<feature>','disable=<feature>']
#       'match'     => <match>
#       'vendor'    => <vendor>
#     }
#
# [*description*]
# [*security*]
#   A hash of the 'security' options:
#     {
#       'type'  => '<type>'
#       'label' => '<label>'
#     }
#
# [*cpuset*]
# [*full_virt*]
# [*accelerate*]
# [*sound*]
# [*noapic*]
# [*noacpi*]
# [*pxe*]
# [*cdrom_path*]
# [*location_url*]
#   This has been overloaded to accept DVD ISO image paths as well.
#   If the target ends in '.iso' the correct option will be used.
#
# [*ks_url*]
# [*target_dir*]
#   The directory in which to install the VM.
#
# [*disk_bus*]
#   A legacy option now superseded by '$disk_opts'
#
# [*disk_opts*]
#   A hash of options as presented to the disk parameter of virt-install
#   Supported options are:
#   bus, perms, cache, format, io, error_policy, serial
#
# [*graphics*]
#   A hash of options that are passed to the '--graphics' option of
#   virt-install, see the man page for details.
#
#   Example:
#   {
#     'type'              => 'vnc',
#     'port'              => <port>                     #optional
#     'tlsport'           => <spice tls port>           #optional
#     'listen'            => <listen address>           #optional
#     'keymap'            => <virtual keymap>           #optional
#     'password'          => <password>                 #optional
#     'passwordvalidto'  => <expire date for password> #optional
#   }
#
# [*virt_type*]
# [*host_device*]
# [*watchdog*]
#   A hash of options to pass to the watchdog option of virt-install.
#   Options are 'model', and 'action'(optional)
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
define libvirt::vm_create (
  $size,
  $mac_addr = '',
  $sparse = false,
  $mem = '512',
  $arch = '',
  $machine = '',
  $ostype = 'linux',
  $osvariant = 'rhel6',
  $bridge = 'virbr0',
  $networks = [],
  $vcpus = '1',
  $vcpu_options = {},
  $numatune = {},
  $cpu = {},
  $description = '',
  $security = {},
  $cpuset = '',
  $full_virt = true,
  $accelerate = true,
  $sound = true,
  $noapic = false,
  $noacpi = false,
  $pxe = false,
  $cdrom_path = '',
  $location_url = '',
  $ks_url = '',
  $target_dir = versioncmp(simp_version(),'5') ? { '-1' => '/srv/VM', default => '/var/VM' },
  $disk_bus = '',
  $disk_opts = {},
  $graphics = {
    'type' => 'vnc',
    'keymap' =>  'en_us'
  },
  $virt_type = '',
  $host_device = '',
  $watchdog = { 'model' => 'default' }
) {

  if !defined(File[$target_dir]) {
    exec { "make ${target_dir}":
      command => "/bin/mkdir -p -m 2755 ${target_dir}",
      onlyif  => "/usr/bin/test ! -d ${target_dir}",
      notify  => File[$target_dir]
    }

    file { $target_dir:
      ensure => 'directory',
      owner  => 'root',
      group  => 'kvm',
      mode   => '2660'
    }
  }

  file { "/usr/local/sbin/vm-create-${name}.sh":
    owner   => 'root',
    group   => 'kvm',
    mode    => '0750',
    content => template('libvirt/newvm.erb'),
    require => File[$target_dir]
  }

  if $::operatingsystem in ['RedHat','CentOS'] {
    $exec_deps = $::operatingsystemmajrelease ? {
      '7' => [
        File["/usr/local/sbin/vm-create-${name}.sh"],
        Package['virt-install'],
        Service['libvirtd']
      ],
      default => [
        File["/usr/local/sbin/vm-create-${name}.sh"],
        Package['python-virtinst'],
        Service['libvirtd']
      ]
    }
  }
  else {
    warning("$::operatingsystem not yet supported. Current options are RedHat and CentOS.")
  }

  exec { "vm-create-${name}":
    command => "/usr/local/sbin/vm-create-${name}.sh &",
    onlyif  => "/usr/bin/virsh domstate ${name}; /usr/bin/test \$? -ne 0",
    require => $exec_deps
  }

  validate_integer($size)
  validate_bool($sparse)
  validate_integer($mem)
  validate_array($networks)
  validate_hash($vcpu_options)
  validate_hash($numatune)
  validate_hash($cpu)
  validate_hash($security)
  validate_bool($full_virt)
  validate_bool($accelerate)
  validate_bool($sound)
  validate_bool($noapic)
  validate_bool($noacpi)
  validate_bool($pxe)
  validate_absolute_path($target_dir)
  validate_hash($disk_opts)
  validate_hash($graphics)
  validate_hash($watchdog)
}
