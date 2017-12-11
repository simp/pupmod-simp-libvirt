# Return whether or not the br_netfilter kernel module is loaded
#
Facter.add('libvirt_br_netfilter_loaded') do
  confine :kernel => 'Linux'
  setcode do
    %x{/sbin/sysctl -n net.bridge.bridge-nf-call-iptables >& /dev/null}

    $?.success?
  end
end

