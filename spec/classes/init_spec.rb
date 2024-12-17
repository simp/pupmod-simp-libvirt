require 'spec_helper'

describe 'libvirt' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          os_facts
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('libvirt') }
        it { is_expected.to contain_package('libvirt').with_ensure('installed') }
        it { is_expected.to contain_service('libvirtd').with_ensure('running') }
      end
    end
  end
end
