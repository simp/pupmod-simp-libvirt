require 'spec_helper'

describe 'libvirt::vm' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts
      end

      let(:title) { 'foo_vm' }

      {
        default: {
          size: 50,
          pxe: true,
          target_dir: '/tmp/test_libvirt',
        },
        larger_disk_size: {
          size: 100,
          pxe: true,
          target_dir: '/tmp/test_libvirt',
        },
        specify_disk_opts: {
          size: 100,
          disk_opts: { 'bus' => '1', 'format' => 'qcow', 'io' => 'test' },
          pxe: true,
          target_dir: '/tmp/test_libvirt',
        },
        increased_vcpus: {
          vcpus: 4,
          size: 50,
          pxe: true,
          target_dir: '/tmp/test_libvirt',
        },
        larger_memory_size: {
          mem: 1024,
          size: 50,
          pxe: true,
          target_dir: '/tmp/test_libvirt',
        },
      }.each do |name, testcase|
        context "when test case = #{name}" do
          let(:params) do
            testcase
          end

          it { is_expected.to create_file('/tmp/test_libvirt').with_ensure('directory') }

          create_vm = File.open("#{File.dirname(__FILE__)}/data/#{name}.txt", 'rb').read
          it { is_expected.to create_file('/usr/local/sbin/vm-create-foo_vm.sh').with_content(create_vm) }
        end
      end
    end
  end
end
