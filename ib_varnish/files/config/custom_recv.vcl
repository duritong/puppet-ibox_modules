# here you can tune how varnish should handle a request,
# e.g. you can block brute-forcing or other problems
# 
# e.g. joomla brute force
if (req.url ~ "/administrator/" && req.http.host ~ "joomla.example.com" && req.http.user-agent == "Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.76 Safari/537.36" ) {
    return (synth(403, "You are banned from this site."));
}
