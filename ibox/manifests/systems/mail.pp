# our general mail configuration
class ibox::systems::mail(
  $use_exim = false,
){
  if $use_exim {
    include ::sendmail::disable
    include ::postfix::disable
    include ::ssmtp::disable
    Package['exim'] -> Package['ssmtp'] -> Service['exim']
    Package['exim'] -> Package['postfix'] -> Service['exim']
    Package['exim'] -> Package['sendmail'] -> Service['exim']
  } else {
    class{'::ssmtp':
      manage_shorewall => $ibox::use_shorewall,
    } -> class{'::sendmail::disable': }
        -> class{'::exim::disable': }
        -> class{'::postfix::disable': }
    Package['ssmtp'] -> Package['exim']
    Package['ssmtp'] -> Package['postfix']
    Package['ssmtp'] -> Package['sendmail']
  }
}
