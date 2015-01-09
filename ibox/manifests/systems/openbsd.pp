# a few openbsd defaults
class ibox::systems::openbsd(
  $verbose_daily = 0,
  $kbd           = 'sg',
) {
  include ib_openbsd
  include ib_pf

  include user::openbsd::defaults

  openbsd::kbd{$kbd: }
  openbsd::daily_local{
    'VERBOSESTATUS':
      value => $verbose_daily,
  }

}
