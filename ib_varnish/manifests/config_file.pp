# a wrapper to simplify a bit our usage
define ib_varnish::config_file(
  $sources,
){
  $source_int = $sources[$name]
  if $source_int and !empty($source_int){
    $real_source = $source_int
  } else {
    # a default set of sources that allow some tweaking
    $real_source = [
      "puppet:///modules/auto_varnish/config/${::operatingsystem}.${::operatingsystemmajrelease}/${name}.vcl",
      "puppet:///modules/auto_varnish/config/${name}.vcl",
      "puppet:///modules/site_varnish/config/${::operatingsystem}.${::operatingsystemmajrelease}/${name}.vcl",
      "puppet:///modules/site_varnish/config/${name}.vcl",
      "puppet:///modules/ib_varnish/config/${::operatingsystem}.${::operatingsystemmajrelease}/${name}.vcl",
      "puppet:///modules/ib_varnish/config/${name}.vcl",
    ]
  }
  varnish::config_file{
    $name:
      source => $real_source,
  }
}
