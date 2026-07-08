# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-libvirt` is a SIMP Puppet module that turns an Enterprise Linux host into
a **libvirt/KVM virtualization host**. It installs the libvirt packages and
keeps `libvirtd` running (`manifests/install.pp`, `manifests/service.pp`),
optionally enables **KVM** with the correct CPU-specific kernel module and the
bridge/forwarding `sysctl` tuning (`manifests/kvm.pp`), optionally configures
**KSM** (Kernel Same-page Merging) and its `ksmtuned` daemon
(`manifests/ksm.pp`), grants a group libvirt access through a polkit rule
(`manifests/polkit.pp`), and can define and launch VMs via the `libvirt::vm`
defined type, which renders a `virt-install` wrapper script
(`manifests/vm.pp`, `templates/newvm.erb`).

### Business logic

- **`libvirt` (`manifests/init.pp:26-57`)** — Public entry class (consumers
  `include 'libvirt'`; calls `simplib::assert_metadata` at `init.pp:38`). Always
  includes `libvirt::install` and `libvirt::service` and wires
  `Install ~> Service` (`init.pp:40-43`). Then conditionally:
  - `$kvm` (default **`true`**, `init.pp:32`) → includes `libvirt::kvm` with
    ordering `Install -> Kvm ~> Service` (`init.pp:45-50`).
  - `$ksm` (default **`false`**, `init.pp:31`) → includes `libvirt::ksm`
    (`Ksm ~> Service`, `init.pp:52-56`).
  - `$package_ensure` is the seam (`init.pp:35`).

- **`libvirt::install` / `libvirt::service`** — internal helper classes included
  by `libvirt` (installs `$package_list` + the `libvirt` package; manages the
  `libvirtd` service at `$service_ensure`, default `running`, `enable => true`).
  Note: these helper classes are **not** `assert_private()`'d, but the intended
  entry point is the main `libvirt` class — drive configuration through its
  parameters rather than including the helpers directly.

- **`libvirt::kvm` (`manifests/kvm.pp:14-77`)** — `inherits libvirt`. Ensures
  the KVM packages, and when `$load_kernel_modules` selects the CPU-specific
  module from the `cpuinfo` fact: `AuthenticAMD → kvm_amd`,
  `GenuineIntel → kvm_intel`, **anything else `fail()`s**
  (`kvm.pp:24-28`). When `$manage_sysctl`, enables IPv4 forwarding and sets the
  `net.bridge.bridge-nf-call-{arptables,iptables}` knobs to `'0'` so bridged VM
  traffic bypasses the host firewall; the ip6tables knob is `'0'` when
  `ipv6_enabled`, else `absent` (`kvm.pp:35-76`).

- **`libvirt::ksm` (`manifests/ksm.pp:67-111`)** — configures Kernel Same-page
  Merging (shipped in `qemu-kvm`; see the class-header comment `ksm.pp:1-4`).
  Manages `/etc/ksmtuned.conf` from `templates/ksmtuned.erb` and
  `/etc/sysconfig/ksm` from `templates/ksm.erb`, and toggles the `ksmtuned` and
  `ksm` services on `$enable` (`ksm.pp:85-110`). Also carries the seam at
  `ksm.pp:69`. The `ksm_npages_min`/`ksm_npages_max` defaults are the literal
  `'shmall'` which the template resolves from `/proc/sys/kernel/shmall`.

- **`libvirt::polkit` (`manifests/polkit.pp:23-41`)** — Public, optional. Emits
  a single `polkit::authorization::basic_policy` for action
  **`org.libvirt.unix.manage`** (`polkit.pp:39`), allowing members of `$group`
  (default `'virtusers'`) to manage libvirt. It is **not** included by the main
  class — declare it yourself when you want the rule.

- **`libvirt::vm` (`manifests/vm.pp:138-203`)** — Public defined type; the API
  for creating a VM. It `include`s `libvirt::kvm`, ensures `$target_dir`
  (default `/var/VM`, mode `2660`, group `kvm`) exists, renders
  `/usr/local/sbin/vm-create-${name}.sh` from `templates/newvm.erb`
  (`vm.pp:190-196`), and runs it (`vm.pp:198-202`). The `exec` is idempotent
  via `onlyif => "virsh domstate ${name}; test $? -ne 0"` — the script only runs
  when the domain does not yet exist, and it runs backgrounded with output to
  `/dev/null`. Parameters mirror `virt-install(1)` field syntax (`vm.pp:1-4`);
  key ones: `$size` (required, disk GB), `$networks` (array of
  `{type,target,mac,model}` hashes; overrides the legacy `$bridge`/`virbr0`),
  `$pxe` vs `$location_url` (boot source; a `.iso` suffix switches the flag),
  `$disk_opts`, `$graphics` (default VNC), and the numa/cpu/security hashes.

### Gotchas / non-obvious details

- **KVM is on by default; KSM is off.** Just `include 'libvirt'` gives you KVM
  (`init.pp:31-32`).
- **Unknown CPU vendor fails the catalog.** `libvirt::kvm` only knows AMD and
  Intel (`kvm.pp:24-28`); exotic/nested-virt CPUs need `$load_kernel_modules =>
  false` plus manual module handling.
- **br_netfilter loading is fact-gated.** The custom fact
  `libvirt_br_netfilter_loaded` (`lib/facter/libvirt_br_netfilter_loaded.rb`)
  runs `sysctl -n net.bridge.bridge-nf-call-iptables` and returns whether that
  succeeded. `kvm.pp:44` loads `br_netfilter` (and orders it before the bridge
  sysctls) **only** when the fact is false — i.e. when the module isn't already
  loaded — to avoid a redundant `kmod::load` (`kvm.pp:44-55`).
- **Bridged VM traffic bypasses the host firewall by design.** The
  `bridge-nf-call-*` sysctls are set to `'0'` (`kvm.pp:57-75`); this is
  intentional, not a mistake.
- **`libvirt::vm` shells out.** It generates and runs a `virt-install` wrapper
  rather than declaring libvirt resources; failures are swallowed
  (`> /dev/null 2>&1`), so debug by running the generated
  `/usr/local/sbin/vm-create-<name>.sh` by hand (`vm.pp:198-202`).
- **`simp/simp_options` is NOT a declared dependency** in `metadata.json`, yet
  the manifests consume the `simp_options::package_ensure` seam via
  `simplib::lookup` (provided by `simp/simplib`).

## The `simp_options` / `simplib::lookup` seam

The module's only lookup seam (the natural target for a lookup-path unit test):

| Line | Key | `default_value` |
|------|-----|-----------------|
| `init.pp:35` | `simp_options::package_ensure` | `'installed'` |
| `ksm.pp:69` | `simp_options::package_ensure` | `'installed'` |

Keep routing package state through `simplib::lookup('simp_options::package_ensure',
{ 'default_value' => ... })` with an explicit default rather than assuming
`simp_options` is included. No `assert_optional_dependency` calls exist in this
module.

## Dependencies

Module dependencies (from `metadata.json`):

- `simp/simplib` `>= 4.9.0 < 6.0.0` (provides `simplib::lookup`,
  `simplib::assert_metadata`)
- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0` (provides `ensure_packages`,
  `Stdlib::AbsolutePath`)
- `simp/polkit` `>= 6.1.0 < 8.0.0` (provides
  `polkit::authorization::basic_policy` and the `Polkit::Result` type used by
  `libvirt::polkit`)
- `puppet/augeasproviders_sysctl` `>= 2.4.0 < 7.0.0` (provides the `sysctl`
  type used in `kvm.pp`)
- `puppet/kmod` `>= 2.1.0 < 5.0.0` (provides `kmod::load` used in `kvm.pp`)

No optional dependencies (`metadata.json` declares no
`simp.optional_dependencies`).

Runtime requirement (from `metadata.json` `requirements`): `openvox
>= 8.0.0 < 9.0.0`.

Supported OS matrix (from `metadata.json`): CentOS 9/10; RedHat 8/9/10;
OracleLinux 8/9/10; Rocky 8/9/10; AlmaLinux 8/9/10. (The `data/os/` tree still
carries EL7-era files, but they are outside the supported matrix.)

## Repository layout

- `manifests/init.pp` — the `libvirt` class (orchestration).
- `manifests/install.pp`, `manifests/service.pp` — package install / `libvirtd`
  service (internal helpers).
- `manifests/kvm.pp` — KVM kernel module + bridge/forwarding sysctl.
- `manifests/ksm.pp` — KSM + `ksmtuned` configuration and services.
- `manifests/polkit.pp` — optional polkit rule for group libvirt access.
- `manifests/vm.pp` — the `libvirt::vm` defined type (virt-install wrapper).
- `lib/facter/libvirt_br_netfilter_loaded.rb` — custom fact: is `br_netfilter`
  loaded? (probes `sysctl`).
- `templates/ksmtuned.erb` → `/etc/ksmtuned.conf`; `templates/ksm.erb` →
  `/etc/sysconfig/ksm`; `templates/newvm.erb` → the `vm-create-<name>.sh`
  script.
- `data/common.yaml` + `data/os/*.yaml` — module data (e.g. the OS-specific KVM
  `package_list`); `hiera.yaml` is the v5 hierarchy.
- `metadata.json` — deps, OS matrix, OpenVox requirement.
- `spec/classes/`, `spec/defines/` — rspec-puppet unit tests.
- `spec/acceptance/suites/default/00_default_spec.rb` — beaker acceptance suite
  (applies `libvirt` with kvm+ksm, checks the services and, on
  virtualization-capable hardware, exercises `libvirt::vm`); nodesets under
  `spec/acceptance/nodesets/`. **This suite is present in-tree but is NOT wired
  into CI** — `.github/workflows/pr_tests.yml` runs only the unit/lint matrix
  (no `acceptance` job).
- No `types/` (this module declares no custom Puppet data types).

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Run a single spec
bundle exec rspec spec/defines/vm_spec.rb

# Puppet lint
bundle exec rake lint

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run the (in-tree, not-in-CI) beaker acceptance suite locally
bundle exec rake beaker:suites[default]
```

Relevant gem pins (from `Gemfile`): `puppetlabs_spec_helper ~> 8.0.0`,
`simp-rake-helpers ~> 5.24.0`, `simp-rspec-puppet-facts ~> 4.0.0`,
`simp-beaker-helpers ~> 2.0.0`, `rubocop ~> 1.88.0`. `spec/spec_helper.rb`
requires `puppetlabs_spec_helper/module_spec_helper`.

## Conventions

- Drive configuration through the `libvirt` class parameters, not by including
  the `install`/`service`/`kvm`/`ksm` helpers directly.
- Preserve the `@summary` / `@param` puppet-strings docstrings — they drive
  `REFERENCE.md`. Regenerate `REFERENCE.md` after changing docs or parameters.
- Keep OS-specific package lists (e.g. the KVM/KSM `package_list`) in
  `data/os/*.yaml`, not hard-coded in the manifests.
- Continue routing package state through
  `simplib::lookup('simp_options::package_ensure', { 'default_value' => ... })`
  rather than assuming `simp_options` is included.
- `libvirt::vm` intentionally shells out to `virt-install`; if you extend it,
  keep the generated script idempotent via the `virsh domstate` guard.
- `Gemfile`, `spec/spec_helper.rb`, and `.github/workflows/pr_tests.yml` carry a
  **puppetsync** notice — they are baseline-managed and the next sync overwrites
  local edits. Push changes to those files upstream to the baseline, not here.
- Match the existing 2-space Puppet indentation and aligned-arrow parameter
  style used in `manifests/`.
