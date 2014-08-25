# an openbsd fw
class ibox::types::openbsd_fw(
  $pf_config_class = 'ibox',
  $pf_auth_user    = 'iboxssh',
  $pf_auth_sshkey  = 'some_class_with_ssh_authorized_keys',
) {
  include ::ibox
  class{ 'pf::router':
    config_class => $pf_config_class,
    manage_munin => $ibox::use_munin,
  }
  include pf::bruteforce
  class{'ib_user::authpf':
    user   => $pf_auth_user,
    sshkey => $pf_auth_sshkey,
  }
}
