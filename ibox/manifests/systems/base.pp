# things that are necessary for all systems
class ibox::systems::base {
  include ib_vim
  include bash

  include stdlib
  include certs::ssl_config

  include fwtools

  include which
  include crypto
  include tar

  screen::screenrc{'root_screenrc': }
  tmux::config{'tmux_root': }

  # disable logwatch so far
  include logwatch::disable
  include ibp

  include resolvconf

  include ib_sshd

  include motd::client

  include ib_virt
  include ib_ntp
}
