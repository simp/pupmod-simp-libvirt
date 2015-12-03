require 'spec_helper'

describe 'libvirt::vm_create' do

  let(:title) {'foo_vm'}
  let(:facts) {{
    :operatingsystemmajrelease => '6',
    :operatingsystem   => 'CentOS'
  }}
  let(:params) {{
    :size       => '50',
    :pxe        => true,
    :target_dir => '/tmp/test_libvirt'
  }}

  it { should create_file('/tmp/test_libvirt').with_ensure('directory') }
  it { should create_file('/usr/local/sbin/vm-create-foo_vm.sh').with_content(/size=50/) }
end
