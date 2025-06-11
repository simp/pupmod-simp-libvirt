require 'spec_helper_acceptance'

test_name 'libvirt'

def virt_support(host)
  kernel_flags = on(host, %(cat /proc/cpuinfo | grep flags | head -1 | cut -f2 -d':')).output.strip.split

  kernel_flags.include?('vmx') || kernel_flags.include?('svm')
end

describe 'libvirt' do
  hosts.each do |host|
    context 'should set up libvirt' do
      let(:manifest) do
        <<-EOF
          include 'libvirt'
        EOF
      end

      let(:hieradata) do
        new_hieradata = {
          'libvirt::kvm' => true,
          'libvirt::ksm' => true
        }

        unless virt_support(host)
          # Nested virtualization issues
          new_hieradata['libvirt::manage_sysctl'] = false
          new_hieradata['libvirt::load_kernel_modules'] = false
        end

        new_hieradata
      end

      it 'applies successfully' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'has libvirt running' do
        result = on(host, 'puppet resource service libvirtd').output
        expect(result).to match(%r{running})
      end

      it 'has ksmtuned running' do
        result = on(host, 'puppet resource service ksmtuned').output
        expect(result).to match(%r{running})
      end

      it 'has ksm enabled' do
        result = on(host, 'puppet resource service ksm').output
        expect(result).to match(%r{enable\s*=>\s*['"]?true['"]?})
      end

      it 'is able to use virsh' do
        result = on(host, 'virsh version').output
        expect(result).not_to match(%r{failure})
      end

      if virt_support(host)
        it 'has net.bridge.bridge-nf-call-arptables set to 1' do
          result = on(host, 'sysctl -n net.bridge.bridge-nf-call-arptables').output.strip
          expect(result).to eq '1'
        end

        it 'is able to spin up a VM' do
          vm_manifest = <<-EOF
            include libvirt

            libvirt::vm { 'test':
              mac_addr  => '00:16:3e:aa:bb:cc',
              'size'    => 5,
              disk_opts => { 'bus' => 'virtiio' }
            }
          EOF

          apply_manifest_on(host, vm_manifest)
        end
      else
        it "#{host} does not have virtualization support for advanced tests"
      end
    end
  end
end
