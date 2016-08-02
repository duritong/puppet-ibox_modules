/*
* Bypass caching of files > 10M
* https://stackoverflow.com/questions/23065255/varnish-bypass-a-large-file
* https://github.com/dreamhost/varnish-vcl-collection/commit/76e0ed203a103144e9bb2762e4ce322217faa7e4
* http://book.varnish-software.com/4.0/chapters/VCL_Built_in_Subroutines.html#hit-for-pass
*/
if (std.integer(beresp.http.Content-Length, 0) > 10485760) {
  set beresp.ttl = 2m;
  set beresp.uncacheable = true;
}

/*
* Save this object for a while beyond its TTL so that we
* can serve stale content in case the backend goes down.
* Cooperates with backend probing and bereq.grace in vcl_recv.
*/
set beresp.grace = 24h;

/*
* Static resources don't need cookies.
* Matches Cookie removal in vcl_recv.
*/
if ((bereq.url ~ "\.(jpg|jpeg|gif|png|ico|css|zip|tgz|gz|rar|bz2|pdf|txt|tar|wav|bmp|rtf|js|flv|swf|html|htm|xml|json|iso|mp[34]|xz|7z|avi|mov|ogm|mpe?g|mk[av])$")  && (bereq.url !~ "\.php\?")) {
  unset beresp.http.Set-Cookie;
}

# Called after the response headers has been successfully retrieved from the backend.
# Pause ESI request and remove Surrogate-Control header
if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
  unset beresp.http.Surrogate-Control;
  set beresp.do_esi = true;
}
# Varnish 4 fully supports Streaming, so use streaming here to avoid locking.
if ((bereq.url ~ "\.(zip|tgz|gz|rar|bz2|tar|wav|flv|swf|iso|mp[34]|xz|7z|avi|mov|ogm|mpe?g|mk[av])$") && (bereq.url !~ "\.php\?")) {
  unset beresp.http.set-cookie;
  set beresp.do_stream = true; # Check memory usage it'll grow in fetch_chunksize blocks (128k by default) if
  # the backend doesn't send a Content-Length header, so only enable it for big objects
  set beresp.do_gzip = false; # Don't try to compress it for storage
}

/*
* every object is cacheable for at least 1m
*/
if (beresp.ttl <= 0s) {
  set beresp.ttl = 1m;
}

if (bereq.http.Cache-Control ~ "no-cache" || bereq.http.Cache-Control ~ "must-revalidate") {
  #this was a no-cache request!
  set beresp.http.X-Manually-Refreshed = 1;
  set beresp.ttl = 120s;
} else if ( !(bereq.http.Cache-Control ~ "private" || bereq.http.Authorization || bereq.http.Set-Cookie) &&
  beresp.ttl < 15s ) {
  #not private but still not cacheable -> we don't trust the backend
  set beresp.ttl = 15s;
}

include "/etc/varnish/custom_fetch.vcl";
