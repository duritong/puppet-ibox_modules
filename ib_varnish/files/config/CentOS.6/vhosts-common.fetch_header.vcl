/*
* Bypass caching of files > 10M
* https://stackoverflow.com/questions/23065255/varnish-bypass-a-large-file
*/
if ( beresp.http.Content-Length ~ "[0-9]{8,}" ) {
     set req.http.x-pipe-mark = "1";
        return(restart);
}

/*
* Save this object for a while beyond its TTL so that we
* can serve stale content in case the backend goes down.
* Cooperates with backend probing and req.grace in vcl_recv.
*/
set beresp.grace = 24h;

/*
* Static resources don't need cookies.
* Matches Cookie removal in vcl_recv.
*/
if ((req.url ~ "\.(jpg|jpeg|gif|png|ico|css|zip|tgz|gz|rar|bz2|pdf|txt|tar|wav|bmp|rtf|js|flv|swf|html|htm|xml|json|iso|mp[34]|xz|7z|avi|mov|ogm|mpe?g|mk[av])$")  && (req.url !~ "\.php\?")) {
    remove beresp.http.Set-Cookie;
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

if (req.http.Cache-Control ~ "no-cache" || req.http.Cache-Control ~ "must-revalidate") {
  #this was a no-cache request!
  set beresp.http.X-Manually-Refreshed = 1;
  set beresp.ttl = 120s;
} else if ( !(req.http.Cache-Control ~ "private" || req.http.Authorization || req.http.Set-Cookie) &&
  beresp.ttl < 15s ) {
  #not private but still not cacheable -> we don't trust the backend
  set beresp.ttl = 15s;
}

include "/etc/varnish/custom_fetch.vcl";
