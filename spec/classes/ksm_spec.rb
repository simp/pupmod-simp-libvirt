require 'spec_helper'

describe 'libvirt::ksm' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts.merge({ :shmall => '4294967296' })}

        let(:params) {{
          :ksm_max_kernel_pages => '40',
          :ksm_monitor_interval => '60'
        }}

        it { is_expected.to create_class('libvirt::ksm') }
        it { is_expected.to create_file('/etc/ksmtuned.conf').with_content(/KSM_MONITOR_INTERVAL=60/) }
        it { is_expected.to create_file('/etc/sysconfig/ksm').with_content(/KSM_MAX_KERNEL_PAGES=40/) }
        it { is_expected.to contain_service('ksm') }
        it { is_expected.to contain_service('ksmtuned').with_ensure('running') }
      end
    end
  end
end
