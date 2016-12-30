# manage things on RedHat based systems
class ibox::systems::redhat(
  $with_abrt = false,
) {
  include ::ib_yum

  class{[ '::authconfig' ]:
    stage => setup,
  }

  #disable some stuff
  if $::virtual == 'kvm' and versioncmp($::operatingsystemmajrelease,'5') > 0 {
    include ::acpid
  } else {
    include ::acpid::disable
  }

  include ::etc_updates

  include ::dbus
  if $with_abrt {
    include ::abrt
  } else {
    include ::abrt::disable
  }
  include ::kexec_tools::disable

  include ::kudzu::disable
  include ::readahead::disable
  include ::avahi::disable
  include ::autofs::disable

  if versioncmp($::operatingsystemmajrelease,'7') < 0 {
    include ::iscsi::disable
    include ::hal::disable
  }

  if versioncmp($::operatingsystemmajrelease,'6') < 0 {
    include ::dbus::disable
    include ::cups::disable
  } else {
    include ::dbus
    include ::kexec_tools::disable
  }

  # some tiny fix due to anaconda putting that there
  exec{'sed -i /^DNS1=/d /etc/sysconfig/network-scripts/ifcfg-*':
    onlyif => 'grep -qE \'^DNS1\' /etc/sysconfig/network-scripts/ifcfg-*';
  }
}
