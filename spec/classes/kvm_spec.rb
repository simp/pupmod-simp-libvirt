require 'spec_helper'

describe 'libvirt::kvm' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('libvirt::kvm') }
        if (['RedHat', 'CentOS'].include?(os_facts[:operatingsystem]))
          it { is_expected.to contain_sysctl('net.bridge.bridge-nf-call-arptables') }
          it { is_expected.to contain_sysctl('net.bridge.bridge-nf-call-iptables') }
          it { is_expected.to contain_sysctl('net.ipv4.conf.all.forwarding') }
          it { is_expected.to contain_sysctl('net.ipv4.ip_forward') }

          if os_facts[:ipv6_enabled]
            it { is_expected.to contain_sysctl('net.bridge.bridge-nf-call-ip6tables') }
          else
            it { is_expected.to contain_sysctl('net.bridge.bridge-nf-call-ip6tables').with(ensure: 'absent') }
          end

          if (os_facts[:operatingsystemmajrelease].to_s >= '7')
            it { is_expected.to contain_package('ipxe-roms').with_ensure('installed') }
            it { is_expected.to contain_package('ipxe-roms-qemu').with_ensure('installed') }
          else
            it { is_expected.to contain_package('gpxe-roms').with_ensure('installed') }
            it { is_expected.to contain_package('gpxe-roms-qemu').with_ensure('installed') }
            it { is_expected.to contain_package('virt-v2v').with_ensure('installed') }
          end
          it { is_expected.to contain_package('qemu-kvm').with_ensure('installed') }
          it { is_expected.to contain_package('qemu-kvm-tools').with_ensure('installed') }
          it { is_expected.to contain_package('qemu-img').with_ensure('installed') }
          it { is_expected.to contain_package('libsndfile').with_ensure('installed') }
        end
      end

      context 'load the appropriate kvm kernel module' do
        context 'on Intel hardware' do
          let(:facts) {
            os_facts.merge(
              cpuinfo: { 'processor0' => { 'vendor_id' => 'GenuineIntel' } }
            )
          }
          it { is_expected.to contain_kmod__load('kvm-intel') }
        end
        context 'on AMD hardware' do
          let(:facts) {
            os_facts.merge(
              cpuinfo: { 'processor0' => { 'vendor_id' => 'AuthenticAMD' } }
            )
          }
          it { is_expected.to contain_kmod__load('kvm-amd') }
        end
      end
    end
  end
end
