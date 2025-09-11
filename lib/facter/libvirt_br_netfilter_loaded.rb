# Return whether or not the br_netfilter kernel module is loaded
#
require 'English'
Facter.add('libvirt_br_netfilter_loaded') do
  confine kernel: 'Linux'
  setcode do
    `/sbin/sysctl -n net.bridge.bridge-nf-call-iptables >& /dev/null`

    $CHILD_STATUS.success?
  end
end
