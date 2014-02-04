# manage sshd
class ib_sshd(
  $allowed_users  = 'root',
  $allowed_groups = '',
) {

  $real_allowed_users = $allowed_groups ? {
    ''      => $allowed_users,
    default => ''
  }
  

  class{'sshd':
    allowed_users    => $real_allowed_users,
    allowed_groups   => $allowed_groups,
    manage_shorewall => $ibox::use_shorewall,
  }
}
