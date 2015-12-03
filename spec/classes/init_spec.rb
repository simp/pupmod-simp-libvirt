require 'spec_helper'

describe 'libvirt' do

  let(:facts) {{
    :operatingsystemmajrelease => '6',
    :operatingsystem   => 'CentOS'
  }}

  it { should create_class('libvirt') }
  it { should contain_package('libvirt').with_ensure('latest') }
  it { should contain_package('virt-viewer').with_ensure('latest') }
  it { should contain_package('python-virtinst').with_ensure('latest') }
  it { should contain_service('libvirtd').with_ensure('running') }
end
