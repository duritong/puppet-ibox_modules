# manage sshd
class ib_sshd(
  $allowed_users    = hiera('sshd::allowed_users','root'),
  $allowed_groups   = hiera('sshd::allowed_groups',''),
  $ports            = hiera('sshd::ports',[22]),
  $manage_shorewall = hiera('sshd::manage_shorewall',$ibox::use_shorewall),
) {

  $real_allowed_users = $allowed_groups ? {
    ''      => $allowed_users,
    default => ''
  }

  class{'sshd':
    allowed_users    => $real_allowed_users,
    allowed_groups   => $allowed_groups,
    manage_shorewall => $manage_shorewall,
    ports            => $ports,
    hardened_ssl     => 'no', # we would like to change that
  }
}
