require 'spec_helper'

describe 'libvirt::kvm' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) {
          facts = os_facts.dup
          facts[:libvirt_br_netfilter_loaded] = false
          facts
        }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('libvirt::kvm') }
        if (['RedHat', 'CentOS'].include?(os_facts[:operatingsystem]))
          it { is_expected.to contain_sysctl('net.bridge.bridge-nf-call-arptables') }
          it { is_expected.to contain_sysctl('net.bridge.bridge-nf-call-iptables') }
          it { is_expected.to contain_sysctl('net.ipv4.conf.all.forwarding') }
          it { is_expected.to contain_sysctl('net.ipv4.ip_forward') }

          it { is_expected.to contain_kmod__load('br_netfilter').that_comes_before('Sysctl[net.bridge.bridge-nf-call-arptables]') }
          it { is_expected.to contain_kmod__load('br_netfilter').that_comes_before('Sysctl[net.bridge.bridge-nf-call-iptables]') }

          if os_facts[:ipv6_enabled]
            it { is_expected.to contain_kmod__load('br_netfilter').that_comes_before('Sysctl[net.bridge.bridge-nf-call-ip6tables]') }
            it { is_expected.to contain_sysctl('net.bridge.bridge-nf-call-ip6tables') }
          else
            it { is_expected.to contain_sysctl('net.bridge.bridge-nf-call-ip6tables').with(ensure: 'absent') }
          end
        end

        context 'with br_netfilter loaded' do
          let(:facts) {
            facts = os_facts.dup
            facts[:libvirt_br_netfilter_loaded] = true
            facts
          }

          it { is_expected.to compile.with_all_deps }

          it { is_expected.to_not contain_kmod__load('br_netfilter') }
        end

        context 'load the appropriate kvm kernel module' do
          context 'on Intel hardware' do
            let(:facts) {
              os_facts.merge(
                cpuinfo: { 'processor0' => { 'vendor_id' => 'GenuineIntel' } }
              )
            }
            it { is_expected.to contain_kmod__load('kvm_intel') }
          end
          context 'on AMD hardware' do
            let(:facts) {
              os_facts.merge(
                cpuinfo: { 'processor0' => { 'vendor_id' => 'AuthenticAMD' } }
              )
            }
            it { is_expected.to contain_kmod__load('kvm_amd') }
          end
        end
      end
    end
  end
end
