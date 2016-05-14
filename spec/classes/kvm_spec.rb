require 'spec_helper'

describe 'libvirt::kvm' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }
        it { is_expected.to create_class('libvirt::kvm') }
        it { is_expected.to contain_class('sysctl') }
        if (['RedHat', 'CentOS'].include?(os_facts[:operatingsystem]))
          if (os_facts[:operatingsystemmajrelease].to_s >= '7')
            it { is_expected.to contain_package('ipxe-roms').with_ensure('latest') }
            it { is_expected.to contain_package('ipxe-roms-qemu').with_ensure('latest') }
          else
            it { is_expected.to contain_package('gpxe-roms').with_ensure('latest') }
            it { is_expected.to contain_package('gpxe-roms-qemu').with_ensure('latest') }
            it { is_expected.to contain_package('virt-v2v').with_ensure('latest') }
          end
          it { is_expected.to contain_package('qemu-kvm').with_ensure('latest') }
          it { is_expected.to contain_package('qemu-kvm-tools').with_ensure('latest') }
          it { is_expected.to contain_package('qemu-img').with_ensure('latest') }
          it { is_expected.to contain_package('libsndfile').with_ensure('latest') }
        end
      end
    end
  end
end
