#!/usr/bin/ruby

kvm = "unknown"

File.open("/proc/cpuinfo","r").each do |line|
  if line =~ /vendor_id\s*:\s*(.*)/ then
    if $1 =~ /AMD/i then
      kvm = "kvm-amd"
    else
      kvm = "kvm-intel"
    end
  end
end.close

if not %x{"/sbin/lsmod"}.include?(kvm) then
  exit system("/sbin/modprobe #{kvm}")
else
  exit 0
end
