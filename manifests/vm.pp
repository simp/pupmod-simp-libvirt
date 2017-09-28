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
# @example
#  libvirt::vm_create { 'test_system':
#     mac_addr => 'AA:BB:CC:DD:EE:FF',
#     size => '20',
#     networks => { 'type' => 'bridge', target =>  'br0' },
#     pxe => true,
#     disk_opts => { 'bus' => 'virtio' }
#  }
#
# @param name
#   Used to name the /usr/sbin/vm-create script
#   No '/' in the name!
#
# @param size
# @param mac_addr
# @param sparse
# @param mem
# @param arch
# @param machine
# @param ostype
# @param osvariant
# @param bridge
#   A legacy option for connecting to a single bridge. '$bridges' is now the
#   favored option.
#
# @param networks
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
# @param vcpus
# @param vcpu_options
#   A hash of options that match the vcpus extended arguments.
#   Options will be passed directly and without translation.
#   Example:
#     { 'maxvcpus' => '3', 'sockets' => '2' }
#
# @param numatune
#   A hash of options that correspond to the numatune options.
#   Example:
#     { 'nodeset' => '1,2,3', 'mode' => 'preferred' }
#
# @param cpu
#   A hash of the 'cpu' options:
#     {
#       'name'      => '<cpu_name>',
#       'features'  => ['+<feature>','-<feature>','disable=<feature>']
#       'match'     => <match>
#       'vendor'    => <vendor>
#     }
#
# @param description
# @param security
#   A hash of the 'security' options:
#     {
#       'type'  => '<type>'
#       'label' => '<label>'
#     }
#
# @param cpuset
# @param full_virt
# @param accelerate
# @param sound
# @param noapic
# @param noacpi
# @param pxe
# @param cdrom_path
# @param location_url
#   This has been overloaded to accept DVD ISO image paths as well.
#   If the target ends in '.iso' the correct option will be used.
#
# @param ks_url
# @param target_dir
#   The directory in which to install the VM.
#
# @param disk_bus
#   A legacy option now superseded by '$disk_opts'
#
# @param disk_opts
#   A hash of options as presented to the disk parameter of virt-install
#   Supported options are:
#   bus, perms, cache, format, io, error_policy, serial
#
# @param graphics
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
# @param virt_type
# @param host_device
# @param watchdog
#   A hash of options to pass to the watchdog option of virt-install.
#   Options are 'model', and 'action'(optional)
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define libvirt::vm (
  Integer              $size,
  Optional[String]     $mac_addr     = undef,
  Boolean              $sparse       = false,
  Integer              $mem          = 512,
  Optional[String]     $arch         = undef,
  Optional[String]     $machine      = undef,
  String               $ostype       = 'linux',
  String               $osvariant    = 'rhel6',
  String               $bridge       = 'virbr0',
  Optional[Array]      $networks     = undef,
  Integer              $vcpus        = 1,
  Optional[Hash]       $vcpu_options = undef,
  Optional[Hash]       $numatune     = undef,
  Optional[Hash]       $cpu          = undef,
  Optional[String]     $description  = undef,
  Optional[Hash]       $security     = undef,
  Optional[String]     $cpuset       = undef,
  Boolean              $full_virt    = true,
  Boolean              $accelerate   = true,
  Boolean              $sound        = true,
  Boolean              $noapic       = false,
  Boolean              $noacpi       = false,
  Boolean              $pxe          = false,
  Optional[String]     $cdrom_path   = undef,
  Optional[String]     $location_url = undef,
  Optional[String]     $ks_url       = undef,
  Stdlib::AbsolutePath $target_dir   = '/var/VM',
  Optional[String]     $disk_bus     = undef,
  Optional[Hash]       $disk_opts    = undef,
  Hash                 $graphics     = { 'type' => 'vnc', 'keymap' => 'en_us' },
  Optional[String]     $virt_type    = undef,
  Optional[String]     $host_device  = undef,
  Hash                 $watchdog     = { 'model' => 'default' }
) {

  include 'libvirt'

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

  if $facts['operatingsystem'] in ['RedHat','CentOS'] {
    $exec_deps = $facts['operatingsystemmajrelease'] ? {
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
    warning("${facts['operatingsystem']} not yet supported. Current options are RedHat and CentOS.")
  }

  exec { "vm-create-${name}":
    command => "/usr/local/sbin/vm-create-${name}.sh &",
    onlyif  => "/usr/bin/virsh domstate ${name}; /usr/bin/test \$? -ne 0",
    require => $exec_deps
  }
}
