require 'spec_helper'

describe 'libvirt::polkit' do
  supported_os = on_supported_os.delete_if { |e| e.include?('-6-') } # TODO: do this right
  supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('libvirt::polkit') }
        it {
          is_expected.to create_polkit__authorization__basic_policy('Allow users in virtusers to use libvirt').with(
            ensure: 'present',
            priority: 10,
            action_id: 'org.libvirt.unix.manage',
          )
        }
      end
    end
  end
end
