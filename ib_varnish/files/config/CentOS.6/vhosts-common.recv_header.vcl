/*
* ACME proxy - handled by local nginx
*/
if (req.url~ "^/.well-known/acme-challenge/") {
  set req.url = "/acme/"+req.http.host + req.url;
  set req.backend = localhost_80;
  return (lookup);
}

/*
* Static resources don't need cookies.
* Matches Set-Cookie removal in vcl_fetch.
*/
if ((req.url ~ "\.(jpg|jpeg|gif|png|ico|css|zip|tgz|gz|rar|bz2|pdf|txt|tar|wav|bmp|rtf|js|flv|swf|html|htm|xml|json|iso|mp[34]|xz|7z|avi|mov|ogm|mpe?g|mk[av])$") && (req.url !~ "\.php\?")) {
  remove req.http.Cookie;
}

/*
* Normalize Accept-Encoding to avoid duplicates, and don't
* compress already compressed content.
*/
if (req.http.Accept-Encoding) {
  if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|tbz|mp3|ogg)$") {
    remove req.http.Accept-Encoding;
  } else {
    if (req.http.Accept-Encoding ~ "gzip") {
      set req.http.Accept-Encoding = "gzip";
    } elsif (req.http.Accept-Encoding ~ "deflate" && req.http.User-Agent !~ "MSIE") {
      set req.http.Accept-Encoding = "deflate";
    } else {
      remove req.http.Accept-Encoding;
    }
  }
}

include "/etc/varnish/custom_recv.vcl";
