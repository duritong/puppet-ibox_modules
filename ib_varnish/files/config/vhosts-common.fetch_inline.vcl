/*
* If the response wasn't cacheable, make sure to treat it as
* a regular pass for a while so we don't block clients waiting
* for an object that turns out to be uncacheable.
*/
if (beresp.ttl <= 0s || beresp.http.Set-Cookie || beresp.http.Vary == "*") {
  set beresp.http.X-Cacheable = "NO: Not Cacheable"; // Debugging.
  set beresp.ttl = 2m;
  set beresp.uncacheable = true;
  return (deliver);
/*
* The backend insists that this object is not cacheable,
* so treat it just like a pass in the future.
*/
} elsif (beresp.http.Cache-Control ~ "private") {
  set beresp.http.X-Cacheable = "NO: Cache-Control=private"; // Debugging.
  set beresp.uncacheable = true;
  return (deliver);
/*
* The object is deemed cacheable!
*/
} else {
  set beresp.http.X-Cacheable = "YES"; // Debugging.
}

