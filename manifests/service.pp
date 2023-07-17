# Make sure ``libvirtd`` is running
#
# @param service_ensure
#   ``ensure`` setting for libvirtd
# @author https://github.com/simp/pupmod-simp-libvirt/graphs/contributors
#
class libvirt::service (
  String $service_ensure = $libvirt::service_ensure
) {
  simplib::assert_metadata($module_name)

  service { 'libvirtd':
    ensure => $service_ensure,
    enable => true
  }
}
