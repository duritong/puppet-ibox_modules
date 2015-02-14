# manage root user
class ibox::lib::root_user {
  # manage root user
  user{'root':
    home => '/root',
  }
  if !empty($ibox::root_keys) {
    create_resources('sshd::authorized_key',$ibox::root_keys,{ user => 'root' })
    User['root']{
      purge_ssh_keys => true
    }
  }
}
