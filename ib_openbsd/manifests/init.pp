# a few openbsd settings
class ib_openbsd(
  $kbd          = 'sg',
  $daily_local  = {
    'VERBOSESTATUS' => { value => 0, },
  },
) {
  openbsd::kbd{$kbd: }
  if !empty($daily_local) {
    create_resources('openbsd::daily_local',$daily_local)
  }
}
