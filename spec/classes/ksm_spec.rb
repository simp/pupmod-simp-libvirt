require 'spec_helper'

describe 'libvirt::ksm' do

  let(:facts) {{
    :shmall => '4294967296'
  }}

  let(:params) {{
    :ksm_max_kernel_pages => '40',
    :ksm_monitor_interval => '60'
  }}

  it { should create_class('libvirt::ksm') }
  it { should create_file('/etc/ksmtuned.conf').with_content(/KSM_MONITOR_INTERVAL=60/) }
  it { should create_file('/etc/sysconfig/ksm').with_content(/KSM_MAX_KERNEL_PAGES=40/) }
  it { should contain_service('ksm') }
  it { should contain_service('ksmtuned').with_ensure('running') }
end
