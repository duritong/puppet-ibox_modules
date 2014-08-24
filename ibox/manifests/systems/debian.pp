# debian specific things for our environment
class ibox::systems::debian {
  class{'apt':
    disable_update => true,
  }
  include apt::unattended_upgrades
  include ib_apt::puppetlabs

  # do not log ips of ssh connections
  include loginrecords
}
