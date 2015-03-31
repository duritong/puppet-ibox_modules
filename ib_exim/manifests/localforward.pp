# a local exim forwarder
class ib_exim::localforward {
  class{'ib_exim':
    pgsql          => false,
    localonly      => true,
    nagios_checks  => false,
    component_type => 'localforward'
  }
  # this group is used as trusted group for localforwards
  require webhosting::wwwmailers
  # forward mails @localhost to systems
  sendmail::mailalias{ 'root':
    recipient => hiera('sendmail_mailroot')
  }

  exim::config_snippet{'trusted_options': }
}
