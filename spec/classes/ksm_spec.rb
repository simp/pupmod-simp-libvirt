require 'spec_helper'

describe 'libvirt::ksm' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts.merge({
          :simplib_sysctl => {
            'kernel.shmall' => '18446744073692774399'
          }
        })}

        let(:params) {{
          :ksm_max_kernel_pages => 40,
          :ksm_monitor_interval => 60
        }}

        it { is_expected.to create_class('libvirt::ksm') }
        it { is_expected.to create_file('/etc/ksmtuned.conf').with_content(/KSM_MONITOR_INTERVAL=60/) }

        # I think these might be VERY wrong defaults
        it { is_expected.to create_file('/etc/ksmtuned.conf').with_content(/KSM_NPAGES_MIN=9223372036846387199/) }
        it { is_expected.to create_file('/etc/ksmtuned.conf').with_content(/KSM_NPAGES_MAX=18446744073692774399/) }

        it { is_expected.to create_file('/etc/sysconfig/ksm').with_content(/KSM_MAX_KERNEL_PAGES=40/) }
        it { is_expected.to contain_service('ksm') }
        it { is_expected.to contain_service('ksmtuned').with_ensure('running') }
      end
    end
  end
end
