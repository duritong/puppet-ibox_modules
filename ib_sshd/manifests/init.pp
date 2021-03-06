# manage sshd
class ib_sshd(
  $allowed_users        = hiera('sshd::allowed_users','root'),
  $allowed_groups       = hiera('sshd::allowed_groups',''),
  $ports                = hiera('sshd::ports',[22]),
  $manage_shorewall     = hiera('sshd::manage_shorewall',hiera('ibox::use_shorewall',false)),
  $shorewall_out_remove = true,
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
    hardened         => hiera('sshd::hardened',true),
    harden_moduli    => hiera('sshd::harden_moduli',true),
    hardened_client  => hiera('sshd::hardened_client',true),
  }

  if $shorewall_out_remove and $manage_shorewall {
    include shorewall::rules::out::ssh::remove
  }
}
