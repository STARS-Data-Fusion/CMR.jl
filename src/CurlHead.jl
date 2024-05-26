module CurlHead

using LibCURL
using URIs
using JSON

import ..CurlTypes: CurlHandle, CurlResponseContainer

import ..CurlOptions: apply_authentication

import ..CurlBuffers: apply_buffer

import ..CurlStatus: check_status

import ..NetCred: NetRCFile, DEFAULT_NETRC

export NetRCFile, DEFAULT_NETRC

import ..Cookies: CookieFile, apply_cookie, DEFAULT_COOKIE

export CookieFile

export URI

"""
    head_text(URL::URI; cookie::CookieFile=nothing)::Union{String, Nothing}

Sends a HEAD request to the specified URL and returns the response text. If a CookieFile is provided, it is used in the request.

# Arguments
- `URL::URI`: The URL to which the HEAD request will be sent.
- `CookieFile::CookieFile`: (Optional) A cookie file to be used in the request.

# Returns
- `Union{String, Nothing}`: The response text from the HEAD request. If the HTTP status code is not 200, it returns `Nothing`.

# Errors
- Throws an error if the curl handle fails to initialize.

# Examples
```julia
head_text(URI("http://example.com"), CookieFile(".cookie"))
```
"""
function head_text(
        URL::URI; 
        cookie::CookieFile = DEFAULT_COOKIE,
        netrc::NetRCFile = DEFAULT_NETRC)::Union{String, Nothing}
    # Initialize a curl easy handle
    curl = curl_easy_init()

    if curl == C_NULL
        error("Failed to initialize curl handle")
    end

    # Set the URL
    curl_easy_setopt(curl, CURLOPT_URL, string(URL))

    # We want the headers
    curl_easy_setopt(curl, CURLOPT_HEADER, 1)

    # We don't want the body
    curl_easy_setopt(curl, CURLOPT_NOBODY, 1) 
    
    # Make LibCURL silent
    curl_easy_setopt(curl, CURLOPT_VERBOSE, 0)

    apply_authentication(curl, cookie, netrc)

    buffer = apply_buffer(curl)

    # execute the query
    res = curl_easy_perform(curl)

    check_status(curl, URL)

    # Clean up
    curl_easy_cleanup(curl)

    head = String(buffer.data)

    segments = split(head, "HTTP/2 200")
    # return last segment
    head = segments[length(segments)]

    return head
end

"""
    parse_header(header::String)::Dict

Parse a HTTP header string into a dictionary.

# Arguments
- `header::String`: The HTTP header string to parse.

# Returns
- `Dict{String, String}`: A dictionary where the keys are the header field names and the values are the corresponding field values.

# Example
```julia
header = "Content-Type: application/json\nAuthorization: Bearer token"
parse_header(header)
# Output: Dict("Content-Type" => "application/json", "Authorization" => "Bearer token")
```
"""
function parse_header(header::String)::Dict
    lines = split(header, '\n')
    header_dict = Dict{String, String}()

    for line in lines
        if occursin(':', line)
            key, value = split(line, ':', limit=2)
            header_dict[strip(key)] = strip(value)
        end
    end

    return header_dict
end

"""
    head(URL::URI; cookie::CookieFile = DEFAULT_COOKIE)::Dict

Send a HTTP HEAD request to a URL and parse the response header into a dictionary.

# Arguments
- `URL::URI`: The URL to send the HEAD request to.
- `cookie::CookieFile`: The cookie file to use for the request. Defaults to `DEFAULT_COOKIE`.

# Returns
- `Dict{String, String}`: A dictionary where the keys are the header field names and the values are the corresponding field values. Returns `nothing` if the HEAD request fails.

# Example
```julia
URL = URI("http://example.com")
cookie = CookieFile("cookie.txt")
head(URL, cookie=cookie)
```
# Output: Dict("Content-Type" => "text/html", "Server" => "ECS (dcb/7F5A)")
"""
function head(URL::URI; cookie::CookieFile = DEFAULT_COOKIE)::Dict
    head = head_text(URL, cookie=cookie)
    
    if head === nothing
        return nothing
    end

    lines = split(head, '\n')
    header_dict = Dict{String, String}()
    
    for line in lines
        if occursin(':', line)
            key, value = split(line, ':', limit=2)
            header_dict[strip(key)] = strip(value)
        end
    end

    return header_dict
end

export head

"""
    get_size(URL::URI; cookie::CookieFile=nothing)::Int

Send a HTTP HEAD request to a URL and retrieve the 'content-length' from the response header.

# Arguments
- `URL::URI`: The URL to send the HEAD request to.
- `cookie::CookieFile`: The cookie file to use for the request. If not provided, no cookie file is used.

# Returns
- `Int`: The 'content-length' from the response header as an integer. Returns `nothing` if the HEAD request fails or 'content-length' is not present in the header.

# Example
```julia
URL = URI("http://example.com")
cookie = CookieFile("cookie.txt")
get_size(URL, cookie=cookie)
# Output: 12345 (assuming the content-length of the response is 12345)
```
"""
function get_size(URL::URI; cookie::CookieFile=nothing)::Int
    header = head(URL, cookie=cookie)
    
    if header === nothing
        return nothing
    end

    return parse(Int, header["content-length"])
end

export get_size

end