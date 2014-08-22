# manage things on RedHat based systems
class ibox::systems::redhat {
  include ib_yum

  class{[ 'authconfig' ]:
    stage => setup,
  }

  #disable some stuff
  if $::virtual == 'kvm' {
    include acpid
  } else {
    include acpid::disable
  }

  include etc_updates

  include dbus
  include abrt::disable
  include kexec_tools::disable

  include kudzu::disable
  include readahead::disable
  include avahi::disable
  include autofs::disable

  if $::operatingsystemmajrelease < 7 {
    include iscsi::disable
    include hal::disable
  }

  case $::operatingsystemmajrelease {
    5: {
      include syslog
      include dbus::disable
      include cups::disable
    }
    default: {
      include rsyslog
      include dbus
      include abrt::disable
      include kexec_tools::disable
    }
  }

  # some tiny fix due to anaconda putting that there
  exec{'sed -i /DNS1=/d /etc/sysconfig/network-scripts/ifcfg-eth0':
    onlyif => 'grep -q DNS1 /etc/sysconfig/network-scripts/ifcfg-eth0';
  }
}
