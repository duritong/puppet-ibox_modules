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

  if $::operatingsystemmajrelease < 6 {
    include dbus::disable
    include cups::disable
  } else {
    include dbus
    include abrt::disable
    include kexec_tools::disable
  }

  # some tiny fix due to anaconda putting that there
  exec{'sed -i /^DNS1=/d /etc/sysconfig/network-scripts/ifcfg-*':
    onlyif => 'grep -qE \'^DNS1\' /etc/sysconfig/network-scripts/ifcfg-*';
  }
}
