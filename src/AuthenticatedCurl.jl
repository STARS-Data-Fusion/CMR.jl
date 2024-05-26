module AuthenticatedCurl

using LibCURL
using URIs
using JSON

import ..CurlTypes: CurlHandle, CurlResponseContainer

import ..CurlOptions: apply_authentication

import ..CurlBuffers: apply_buffer

import ..CurlStatus: check_status

import ..CurlHead: head, get_size

import ..NetCred
import ..NetCred: NetRCFile, DEFAULT_NETRC

export NetRCFile

import ..Cookies
import ..Cookies: CookieFile, apply_cookie, DEFAULT_COOKIE

export CookieFile

export URI

"""
    curl_binary(URL::URI; cookie::CookieFile=nothing)::Vector{UInt8}

Sends a GET request to the specified URL and returns the response as raw binary data.

# Arguments
- `URL::URI`: The URL to send the GET request to.
- `cookie::CookieFile`: The cookie file to use for the request. Defaults to `nothing`.

# Returns
- `::Vector{UInt8}`: The response from the server as raw binary data.

# Throws
- `IOError`: If the HTTP status code is not 200.
"""
function curl_binary(
        URL::URI; 
        cookie::CookieFile = DEFAULT_COOKIE,
        netrc::NetRCFile = DEFAULT_NETRC)::Vector{UInt8}
    # init a curl handle
    curl = curl_easy_init()

    # Set the URL
    curl_easy_setopt(curl, CURLOPT_URL, string(URL))

    apply_authentication(curl, cookie)

    buffer = apply_buffer(curl)

    # execute the query
    res = curl_easy_perform(curl)

    check_status(curl, URL)

    # release handle
    curl_easy_cleanup(curl)

    # return the response as raw binary data
    return buffer.data
end

export curl_binary

"""
    curl(URL::URI; cookie::CookieFile=nothing)::String

Sends a GET request to the specified URL and returns the response as a string.

# Arguments
- `URL::URI`: The URL to send the GET request to.
- `cookie::CookieFile`: The CookieFile to use for the request. Defaults to `nothing`.

# Returns
- `::String`: The response from the server.

# Throws
- `IOError`: If the HTTP status code is not 200.
"""
function curl(
        URL::URI; 
        cookie::CookieFile = DEFAULT_COOKIE)::String
    String(curl_binary(URL; cookie=cookie))
end

export curl

end
