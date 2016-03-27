# debian specific things for our environment
class ibox::systems::debian {
  include ::apt
  include ::apt::unattended_upgrades
  include ::ib_apt::puppetlabs

  # do not log ips of ssh connections
  include ::loginrecords
}
