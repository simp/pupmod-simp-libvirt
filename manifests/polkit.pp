# Add a rule file allowing members of a group to use libvirt
#
# @param ensure Create or destroy the rules file
#
# @param content An arbitrary string of javascript polkit configuration
#
# @param priority Priority of the file to be created
#
# @param rulesd Location of the poklit rules directory
#
class libvirt::polkit (
  Enum['present','absent']      $ensure   = 'present',
  Variant[String,Array[String]] $group    = 'virtusers',
  Integer[0,99]                 $priority = 10,
  Polkit::Result                $result   = 'yes',
  Boolean                       $local    = true,
  Boolean                       $active   = true,
) {

  polkit::authorization::basic_policy { "Allow users in ${group} to use libvirt":
    ensure    => $ensure,
    group     => $group,
    priority  => $priority,
    result    => $result,
    local     => $local,
    active    => $active,
    action_id => 'org.libvirt.unix.manage',
  }

}
