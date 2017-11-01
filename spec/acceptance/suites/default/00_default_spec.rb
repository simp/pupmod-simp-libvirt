require 'spec_helper_acceptance'

test_name 'libvirt'

describe 'libvirt' do
  hosts.each do |host|
    context 'should set up libvirt' do
      let(:manifest) { <<-EOF
          include 'libvirt'
          include 'libvirt::kvm'
        EOF
      }
      let(:hieradata) {{
        # Nested virtualization issues
        'libvirt::manage_sysctl' => false,
        'libvirt::load_kernel_modules' => false
      }}
      it 'should apply successfully' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
      end
      it 'should be idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end
      it 'should have libvirt running' do
        result = on(host, 'puppet resource service libvirtd').output
        expect(result).to match(/running/)
      end
      it 'should be able to use virsh' do
        result = on(host, 'virsh version').output
        expect(result).not_to match(/failure/)
      end
    end
  end
end
