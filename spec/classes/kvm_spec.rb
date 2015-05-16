require 'spec_helper'

describe 'libvirt::kvm' do

  let(:facts) {{
    :lsbmajdistrelease => '6',
    :operatingsystem   => 'CentOS'
  }}

  it { should create_class('libvirt::kvm') }
  it { should contain_class('sysctl') }
  it { should contain_package('gpxe-roms').with_ensure('latest') }
  it { should contain_package('gpxe-roms-qemu').with_ensure('latest') }
  it { should contain_package('qemu-kvm').with_ensure('latest') }
  it { should contain_package('qemu-kvm-tools').with_ensure('latest') }
  it { should contain_package('virt-v2v').with_ensure('latest') }
  it { should contain_package('qemu-img').with_ensure('latest') }
  it { should contain_package('libsndfile').with_ensure('latest') }
end
