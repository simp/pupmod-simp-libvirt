require 'spec_helper'

describe 'libvirt::vm' do

  let(:title) {'foo_vm'}
  let(:facts) {{
    :operatingsystemmajrelease => '6',
    :operatingsystem   => 'CentOS'
  }}
  let(:params) {{
    :size       => 50,
    :pxe        => true,
    :target_dir => '/tmp/test_libvirt'
  }}

  it { is_expected.to create_file('/tmp/test_libvirt').with_ensure('directory') }
  it { is_expected.to create_file('/usr/local/sbin/vm-create-foo_vm.sh').with_content(/size=50/) }
end
