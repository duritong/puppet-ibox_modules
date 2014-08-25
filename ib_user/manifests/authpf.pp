# an authpf user
class ib_user::authpf(
  $user   = 'iboxssh',
  $sshkey = 'some_class_with_ssh_authorized_keys',
) {
  user::managed{$user:
    uid     => '1001',
    gid     => '1001',
    shell   => '/usr/sbin/authpf',
    sshkey  => $sshkey,
  }
  pf::authpf_user{$user: }
}
