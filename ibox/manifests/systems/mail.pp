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
    if $use_exim != true {
      include "::ib_exim::${use_exim}"
    }
  } else {
    class{'::ssmtp':
      manage_shorewall => true
    } -> class{'::sendmail::disable': }
        -> class{'::exim::disable': }
        -> class{'::postfix::disable': }
    Package['ssmtp'] -> Package['exim']
    Package['ssmtp'] -> Package['postfix']
    Package['ssmtp'] -> Package['sendmail']
  }
}
