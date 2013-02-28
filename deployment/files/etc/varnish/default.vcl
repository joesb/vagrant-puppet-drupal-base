include "acl.vcl";
include "backends.vcl";
include "esi.vcl";

sub vcl_recv {

  if (req.request == "GET" && req.url ~ "^/varnishcheck$") {
    error 200 "Varnish is Ready";
  }

  # ESI
  call esi_block__recv;

  # Allow the backend to serve up stale content if it is responding slowly.
  if (!req.backend.healthy) {
    # Use anonymous, cached pages if all backends are down.
    unset req.http.Cookie;
    if (req.http.X-Forwarded-Proto == "https") {
      set req.http.X-Forwarded-Proto = "http";
    }
    set req.grace = 30m;
  } 
  else {
    set req.grace = 15s;
  }
 
  if (req.request == "PURGE") {
    # Check if the ip coresponds with the acl purge
    if (!client.ip ~ purge) {
    # Return error code 405 (Forbidden) when not
      error 405 "Not allowed.";
    }
    return (lookup);
  }

  # Do not cache these paths.
  if (req.url ~ "^/status\.php$" ||
      req.url ~ "^/update\.php$" ||
      req.url ~ "^/ooyala/ping$" ||
      req.url ~ "^/admin" ||
      req.url ~ "^/admin/.*$" ||
      req.url ~ "^/user" ||
      req.url ~ "^/user/.*$" ||
      req.url ~ "^/users/.*$" ||
      req.url ~ "^/info/.*$" ||
      req.url ~ "^/flag/.*$" ||
      req.url ~ "^.*/ajax/.*$" ||
      req.url ~ "^.*/ahah/.*$" ||
      req.url ~ "^/pma/.*$" ||
      req.url ~ "^.*/esi/.*$" ) {
    return (pass);
  }

  # Pipe these paths directly to Apache for streaming.
  if (req.url ~ "^/admin/content/backup_migrate/export") {
    return (pipe);
  }

  # Handle compression correctly. Different browsers send different
  # "Accept-Encoding" headers, even though they mostly all support the same
  # compression mechanisms. By consolidating these compression headers into
  # a consistent format, we can reduce the size of the cache and get more hits.=
  # @see: http:// varnish.projects.linpro.no/wiki/FAQ/Compression
  if (req.http.Accept-Encoding) {
    if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|tbz|mp3|ogg)$") {
      # No point in compressing these
      remove req.http.Accept-Encoding;
    }
    else if (req.http.Accept-Encoding ~ "gzip") {
      # If the browser supports it, we'll use gzip.
      set req.http.Accept-Encoding = "gzip";
    }
    else if (req.http.Accept-Encoding ~ "deflate") {
      # Next, try deflate if it is supported.
      set req.http.Accept-Encoding = "deflate";
    }
    else if (req.url ~ "^.*/esi/.*$") {
      unset req.http.Accept-Encoding;
    }
    else {
      # Unknown algorithm. Remove it and send unencoded.
      unset req.http.Accept-Encoding;
    }
  }

  # Always cache the following file types for all users.
  if (req.url ~ "(?i)\.(png|gif|jpeg|jpg|ico|swf|css|js)(\?[a-z0-9]+)?$") {
    # unset req.http.Cookie;
  }

  # Remove all cookies that Drupal doesn't need to know about. ANY remaining
  # cookie will cause the request to pass-through to a backend. For the most part
  # we always set the NO_CACHE cookie after any POST request, disabling the
  # Varnish cache temporarily. The session cookie allows all authenticated users
  # to pass through as long as they're logged in.
  #
  # 1. Append a semi-colon to the front of the cookie string.
  # 2. Remove all spaces that appear after semi-colons.
  # 3. Match the cookies we want to keep, adding the space we removed
  #    previously, back. (\1) is first matching group in the regsuball.
  # 4. Remove all other cookies, identifying them by the fact that they have
  #    no space after the preceding semi-colon.
  # 5. Remove all spaces and semi-colons from the beginning and end of the
  #    cookie string.
  if (req.http.Cookie) {
    set req.http.Cookie = ";" + req.http.Cookie;
    set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
    set req.http.Cookie = regsuball(req.http.Cookie, ";(S{1,2}ESS[a-z0-9]+|NO_CACHE)=", "; \1=");
    set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");

    if (req.http.Cookie == "") {
      # If there are no remaining cookies, remove the cookie header. If there
      # aren't any cookie headers, Varnish's default behavior will be to cache
      # the page.
      unset req.http.Cookie;
    }
    else {
      # If there is any cookies left (a session or NO_CACHE cookie), do not
      # cache the page. Pass it on to Apache directly.
      return (pass);
    }
  }

  ## From default below ##
  if (req.restarts == 0) {
    if (req.http.x-forwarded-for) {
      set req.http.X-Forwarded-For =
      req.http.X-Forwarded-For + ", " + client.ip;
    } else {
      set req.http.X-Forwarded-For = client.ip;
    }
  }
  if (req.request != "GET" &&
    req.request != "HEAD" &&
    req.request != "PUT" &&
    req.request != "POST" &&
    req.request != "TRACE" &&
    req.request != "OPTIONS" &&
    req.request != "DELETE") {
      /* Non-RFC2616 or CONNECT which is weird. */
      return (pipe);
  }
  if (req.request != "GET" && req.request != "HEAD") {
      /* We only deal with GET and HEAD by default */
      return (pass);
  }
  ## Unset Authorization header if it has the correct details...
  #if (req.http.Authorization == "Basic <hash>") {
  #  unset req.http.Authorization;
  #}
  if (req.http.Authorization || req.http.Cookie) {
      /* Not cacheable by default */
      return (pass);
  }
  return (lookup);
}

sub vcl_pipe {
    # Note that only the first request to the backend will have
    # X-Forwarded-For set.  If you use X-Forwarded-For and want to
    # have it set for all requests, make sure to have:
    set bereq.http.connection = "close";
    # here.  It is not set by default as it might break some broken web
    # applications, like IIS with NTLM authentication.

    if (req.http.X-Forwarded-For) {
        set bereq.http.X-Forwarded-For = req.http.X-Forwarded-For;
    } else {
        set bereq.http.X-Forwarded-For = regsub(client.ip, ":.*", "");
    }
}

sub vcl_pass {
    set bereq.http.connection = "close";

    if (req.http.X-Forwarded-For) {
        set bereq.http.X-Forwarded-For = req.http.X-Forwarded-For;
    } else {
        set bereq.http.X-Forwarded-For = regsub(client.ip, ":.*", "");
    }
}

# Routine used to determine the cache key if storing/retrieving a cached page.
sub vcl_hash {
  if (req.http.X-Forwarded-Proto == "https") {
    hash_data(req.http.X-Forwarded-Proto);
  }
  
  # If the client supports compression, keep that in a different cache
   if (req.http.Accept-Encoding) {
       hash_data(req.http.Accept-Encoding);
   }

  # ESI
  call esi_block__hash;
}

sub vcl_hit {
  if (req.request == "PURGE") {
    purge;
    error 200 "Purged.";
  }
}

sub vcl_miss {
  if (req.request == "PURGE") {
    purge;
    error 200 "Purged.";
  }
}

# Code determining what to do when serving items from the Apache servers.
sub vcl_fetch {
  # Don't allow static files to set cookies.
  if (req.url ~ "(?i)\.(png|gif|jpeg|jpg|ico|swf|css|js)(\?[a-z0-9]+)?$") {
    # beresp == Back-end response from the web server.
    unset beresp.http.set-cookie;
  }
  else if (beresp.http.Cache-Control) {
    unset beresp.http.Expires;
    set beresp.do_gzip = true;
  }

  if (beresp.status == 301) {
    set beresp.ttl = 1h;
    return(deliver);
  }

  ## Doesn't seem to work as expected
  #if (beresp.status == 500) {
  #  set beresp.saintmode = 10s;
  #  return(restart);
  #}

  # Allow items to be stale if needed.
  set beresp.grace = 1h;

  # ESI
  # don't ESI anything with a 3/4 letter extension
  # (e.g. don't try to ESI images, css, etc).
  if (! req.url ~ "\..{3,4}$") {
    set beresp.do_esi = true;
  }

  call esi_block__fetch;
}

# Set a header to track a cache HIT/MISS.
sub vcl_deliver {
  if (obj.hits > 0) {
    set resp.http.X-Varnish-Cache = "HIT";
  }
  else {
    set resp.http.X-Varnish-Cache = "MISS";
  }
}

# In the event of an error, show friendlier messages.
sub vcl_error {
     set obj.http.Content-Type = "text/html; charset=utf-8";
     set obj.http.Retry-After = "5";
     synthetic {"<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
   <head>
     <title>"} + obj.status + " " + obj.response + {"</title>
   </head>
   <body>
     <h1>Error "} + obj.status + " " + obj.response + {"</h1>
     <p>"} + obj.response + {"</p>
     <h3>Guru Meditation:</h3>
     <p>XID: "} + req.xid + {"</p>
     <hr>
     <p>Varnish cache server</p>
   </body>
</html>
"};
     return (deliver);
}

