# Install the necessary packages
#
# @param package_list
#   List of packages related to libvirt to be managed
#
# @param package_ensure
#   Ensure setting for all packages in this module
#
# @author https://github.com/simp/pupmod-simp-libvirt/graphs/contributors
#
class libvirt::install (
  Array[String]  $package_list   = $libvirt::package_list,
  String         $package_ensure = $libvirt::package_ensure
) {
  simplib::assert_metadata($module_name)

  ensure_packages( $package_list, { ensure => $package_ensure } )
  package { 'libvirt': ensure => $package_ensure }
}
