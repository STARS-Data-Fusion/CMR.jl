module AuthenticatedCurl

using LibCURL
using URIs
using JSON

import ..NetCred: NetRCFile

export NetRCFile

import ..Cookies: Cookie

export Cookie

export URI

"""
    Response

A mutable struct that holds the response data.
"""
mutable struct CurlResponseContainer
    data::Vector{UInt8}
end

"""
    curl_write_cb(curlbuf::Ptr{Cvoid}, s::Csize_t, n::Csize_t, p_ctxt::Ptr{CurlResponseContainer})

A callback function that is called by `curl_easy_perform`. It writes the response data to `p_ctxt`.
"""
function curl_write_cb(curlbuf::Ptr{Cvoid}, s::Csize_t, n::Csize_t, p_ctxt::Ptr{CurlResponseContainer})
    sz = s * n
    data = Array{UInt8}(undef, sz)

    ccall(:memcpy, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, UInt64), data, curlbuf, sz)
    append!(unsafe_load(p_ctxt).data, data)

    sz::Csize_t
end

function head_text(URL::URI; cookie::Cookie=nothing)::Union{String, Nothing}
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

    if cookie !== nothing
        # Set the cookie file
        curl_easy_setopt(curl, CURLOPT_COOKIEFILE, cookie.filename)

        # Set the cookie jar
        curl_easy_setopt(curl, CURLOPT_COOKIEJAR, cookie.filename)
    end

    # Follow redirects
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1)

    # Enable Netrc
    curl_easy_setopt(curl, CURLOPT_NETRC, CURL_NETRC_OPTIONAL)

    response = CurlResponseContainer(Vector{UInt8}())

    c_curl_write_cb = @cfunction(curl_write_cb, Csize_t, (Ptr{Cvoid}, Csize_t, Csize_t, Ptr{CurlResponseContainer}))
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, c_curl_write_cb)
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, response)

    # execute the query
    res = curl_easy_perform(curl)

    # retrieve HTTP code
    http_code = Array{Clong}(undef, 1)
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, http_code)

    # Clean up
    curl_easy_cleanup(curl)

    # Check if the HTTP status code is 200
    if http_code[1] == 200
        # return the response as a string
        head = String(response.data)
    end

    segments = split(head, "HTTP/2 200")
    # return last segment
    head = segments[length(segments)]

    return head
end

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

function head(URL::URI; cookie::Cookie=nothing)::Dict
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

function get_size(URL::URI; cookie::Cookie=nothing)::Int
    header = head(URL, cookie=cookie)
    
    if header === nothing
        return nothing
    end

    return parse(Int, header["content-length"])
end

export size

"""
    curl(URL::String; cookie_filename::String = COOKIE_FILENAME)

Sends a GET request to the specified URL and returns the response as a string.

# Arguments
- `URL::String`: The URL to send the GET request to.
- `cookie_filename::String`: The path to the cookie file. Defaults to `COOKIE_FILENAME`.

# Returns
- `::String`: The response from the server.

# Throws
- `IOError`: If the HTTP status code is not 200.
"""
function curl(URL::URI; cookie::Cookie=nothing)::String
    response = CurlResponseContainer(Vector{UInt8}())

    # init a curl handle
    curl = curl_easy_init()

    # Set the URL
    curl_easy_setopt(curl, CURLOPT_URL, string(URL))

    if cookie !== nothing
        # Set the cookie file
        curl_easy_setopt(curl, CURLOPT_COOKIEFILE, cookie.filename)

        # Set the cookie jar
        curl_easy_setopt(curl, CURLOPT_COOKIEJAR, cookie.filename)
    end

    # Follow redirects
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1)

    # Enable Netrc
    curl_easy_setopt(curl, CURLOPT_NETRC, CURL_NETRC_OPTIONAL)
    
    c_curl_write_cb = @cfunction(curl_write_cb, Csize_t, (Ptr{Cvoid}, Csize_t, Csize_t, Ptr{CurlResponseContainer}))
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, c_curl_write_cb)
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, response)

    # execute the query
    res = curl_easy_perform(curl)

    # retrieve HTTP code
    http_code = Array{Clong}(undef, 1)
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, http_code)

    # Check if the HTTP status code is 200
    if http_code[1] != 200
        throw(IOError("status $(http_code[1]) for URL: $URL"))
    end

    # release handle
    curl_easy_cleanup(curl)

    # return the response as a string
    return String(response.data)
end

export curl

end
