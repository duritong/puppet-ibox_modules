# a wrapper define to make it easier
# to defaine net_in_rules in hiera
define ib_shorewall::hafw::net_in_rule(
    $destination,
    $port             = '-',
    $action           = 'ACCEPT',
    $source           = 'net',
    $proto            = 'tcp',
    $sourceport       = '-',
    $ratelimit        = '-',
    $mark             = '',
    $order            = '140',
){
  $real_source = $source ? {
    'net'   => 'net',
    default => "net:${source}",
  }
  shorewall::rule{
    $name:
      action          => $action,
      source          => $real_source,
      destination     => "loc:${destination}",
      proto           => $proto,
      destinationport => $port,
      sourceport      => $sourceport,
      ratelimit       => $ratelimit,
      mark            => $mark,
      order           => $order,
  }
}
