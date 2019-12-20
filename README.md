[![License](https://img.shields.io/:license-apache-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/libvirt.svg)](https://forge.puppetlabs.com/simp/libvirt)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/libvirt.svg)](https://forge.puppetlabs.com/simp/libvirt)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-libvirt.svg)](https://travis-ci.org/simp/pupmod-simp-libvirt)

#### Table of Contents

<!-- vim-markdown-toc GFM -->

* [Overview](#overview)
* [This is a SIMP module](#this-is-a-simp-module)
* [Module Description](#module-description)
* [Usage](#usage)
  * [Basic Usage](#basic-usage)
  * [Advanced Usage](#advanced-usage)
* [Development](#development)
  * [Acceptance tests](#acceptance-tests)

<!-- vim-markdown-toc -->

## Overview

This module manages the installation of `libvirt` as well as providing a
rudimentary ability to create virtual machines on your system.

## This is a SIMP module

This module is a component of the [System Integrity Management Platform](https://simp-project.com),
a compliance-management framework built on Puppet.

If you find any issues, they can be submitted to our [JIRA](https://simp-project.atlassian.net/).

This module is optimally designed for use within a larger SIMP ecosystem, but it can be used independently:
* When included within the SIMP ecosystem, security compliance settings will be
  managed from the Puppet server.
* If used independently, all SIMP-managed security subsystems will be disabled by
  default and must be explicitly opted into by administrators.  Please review
  ``simp_options`` for details.

## Module Description

You can use this module to install and manage basic aspects of libvirt, KSM,
KVM, and the polkit rules that surround usage of libvirt capabilities.

You can also use the `libvirt::vm` defined type to spin up local virtual
machines on your nodes.

See [REFERENCE.md](./REFERENCE.md) for API details.

## Usage

### Basic Usage

Simply include the `libvirt` class to add support to your system.

```puppet
include libvirt
```

If you want KSM support, then you should set the follwing in Hiera:

```yaml
---
libvirt::ksm: true
```

### Advanced Usage

This example uses the `simp-network` module to create a bridge and then spins up
a single VM on the resulting system. It also allows users in the `virshusers`
group to execute libvirt commands via polkit.

```puppet
include libvirt
include network

# Set up a local bridge on the network
network::eth { "em1":
  bridge => 'br0',
  hwaddr => $facts['macaddress_em1']
}

network::eth { "br0":
  net_type => 'Bridge',
  hwaddr   => $facts['macaddress_em1'],
  require  => Network::Eth['em1']
}

# Create polkit policy to allow users in virsh users group to use libvirt
class { 'libvirt::polkit':
  ensure => present,
  group  => 'virshusers',
  local  => true,
  active => true
}

# Create group and add users.
group{ 'virshusers':
  members => ['user1','user2']
}

# Kickstart a VM on the system and bind it to the local bridge
libvirt::vm { 'test_system':
  mac_addr  => 'AA:BB:CC:DD:EE:FF',
  size      => 20,
  networks  => { 'type' => 'bridge', 'target' => 'br0' },
  pxe       => true,
  disk_opts => { 'bus' => 'virtio' },
  require   => Network::Eth['br0']
}
```

## Development

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/Contribution_Procedure.html)

### Acceptance tests

This module includes [Beaker](https://github.com/puppetlabs/beaker) acceptance
tests using the SIMP [Beaker Helpers](https://github.com/simp/rubygem-simp-beaker-helpers).
By default the tests use [Vagrant](https://www.vagrantup.com/) with
[VirtualBox](https://www.virtualbox.org) as a back-end; Vagrant and VirtualBox
must both be installed to run these tests without modification. To execute the
tests run the following:

```shell
bundle exec rake beaker:suites
```

Some environment variables may be useful:

```shell
BEAKER_debug=true
BEAKER_provision=no
BEAKER_destroy=no
BEAKER_use_fixtures_dir_for_modules=yes
BEAKER_fips=yes
```

* `BEAKER_debug`: show the commands being run on the STU and their output.
* `BEAKER_destroy=no`: prevent the machine destruction after the tests finish so you can inspect the state.
* `BEAKER_provision=no`: prevent the machine from being recreated. This can save a lot of time while you're writing the tests.
* `BEAKER_use_fixtures_dir_for_modules=yes`: cause all module dependencies to be loaded from the `spec/fixtures/modules` directory, based on the contents of `.fixtures.yml`.  The contents of this directory are usually populated by `bundle exec rake spec_prep`.  This can be used to run acceptance tests to run on isolated networks.
* `BEAKER_fips=yes`: enable FIPS-mode on the virtual instances. This can
  take a very long time, because it must enable FIPS in the kernel
  command-line, rebuild the initramfs, then reboot.

Please refer to the [SIMP Beaker Helpers documentation](https://github.com/simp/rubygem-simp-beaker-helpers/blob/master/README.md)
for more information.
