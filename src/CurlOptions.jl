module CurlOptions

using LibCURL

using ..CurlTypes: CurlHandle

using ..NetCred: NetRCFile, DEFAULT_NETRC

using ..Cookies: CookieFile, apply_cookie, DEFAULT_COOKIE

"""
    apply_redirect(curl::CurlHandle, redirect::Bool = true)

Set the option for curl to follow redirects or not. If `redirect` is true, curl will follow redirects.
"""
function apply_redirect(curl::CurlHandle, redirect::Bool = true)
    if redirect
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1)
    else
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 0)
    end
end

"""
    apply_netrc(curl::CurlHandle, netrc::NetRCFile = DEFAULT_NETRC)

Set the option for curl to use the netrc file for authentication. The path to the netrc file is provided by `netrc.path`.
"""
function apply_netrc(
        curl::CurlHandle, 
        netrc::NetRCFile = DEFAULT_NETRC)
    curl_easy_setopt(curl, CURLOPT_NETRC, CURL_NETRC_OPTIONAL)
    curl_easy_setopt(curl, CURLOPT_NETRC_FILE, netrc.path)
end

"""
    apply_authentication(curl::CurlHandle, cookie::CookieFile = nothing, netrc::NetRCFile = netrc)

Apply cookie, redirect, and netrc settings to the curl handle. If `cookie` is provided, it will be used for authentication.
"""
function apply_authentication(
        curl::CurlHandle, 
        cookie::CookieFile = DEFAULT_COOKIE, 
        netrc::NetRCFile = DEFAULT_NETRC)
    apply_cookie(curl, cookie)
    apply_redirect(curl)
    apply_netrc(curl, netrc)
end

end