module DAACCurl

using LibCURL

"""
    COOKIE_FILENAME

A constant that holds the path to the cookie file.
"""
COOKIE_FILENAME = expanduser("~/.urs_cookies")

"""
    Response

A mutable struct that holds the response data.
"""
mutable struct Response
    data::Vector{UInt8}
end

"""
    NetworkError <: Exception

A struct that represents a network error. It holds an error message.
"""
struct NetworkError <: Exception
    msg::String
end

"""
    curl_write_cb(curlbuf::Ptr{Cvoid}, s::Csize_t, n::Csize_t, p_ctxt::Ptr{Response})

A callback function that is called by `curl_easy_perform`. It writes the response data to `p_ctxt`.
"""
function curl_write_cb(curlbuf::Ptr{Cvoid}, s::Csize_t, n::Csize_t, p_ctxt::Ptr{Response})
    sz = s * n
    data = Array{UInt8}(undef, sz)

    ccall(:memcpy, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, UInt64), data, curlbuf, sz)
    append!(unsafe_load(p_ctxt).data, data)

    sz::Csize_t
end

"""
    curl(URL::String; cookie_filename::String = COOKIE_FILENAME)

Sends a GET request to the specified URL and returns the response as a string.

# Arguments
- `URL::String`: The URL to send the GET request to.
- `cookie_filename::String`: The path to the cookie file. Defaults to `COOKIE_FILENAME`.

# Returns
- `::String`: The response from the server.

# Throws
- `NetworkError`: If the HTTP status code is not 200.
"""
function curl(URL::String; cookie_filename::String = COOKIE_FILENAME)::String
    response = Response(Vector{UInt8}())

    # init a curl handle
    curl = curl_easy_init()

    # Set the URL
    curl_easy_setopt(curl, CURLOPT_URL, URL)

    # Set the cookie file
    curl_easy_setopt(curl, CURLOPT_COOKIEFILE, cookie_filename)

    # Set the cookie jar
    curl_easy_setopt(curl, CURLOPT_COOKIEJAR, cookie_filename)

    # Follow redirects
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1)

    # Enable Netrc
    curl_easy_setopt(curl, CURLOPT_NETRC, CURL_NETRC_OPTIONAL)
    
    c_curl_write_cb = @cfunction(curl_write_cb, Csize_t, (Ptr{Cvoid}, Csize_t, Csize_t, Ptr{Response}))
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, c_curl_write_cb)
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, response)

    # execute the query
    res = curl_easy_perform(curl)

    # retrieve HTTP code
    http_code = Array{Clong}(undef, 1)
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, http_code)

    # Check if the HTTP status code is 200
    if http_code[1] != 200
        throw(NetworkError("HTTP status $(http_code[1]) for URL: $URL"))
    end

    # release handle
    curl_easy_cleanup(curl)

    # return the response as a string
    return String(response.data)
end

export curl

end
