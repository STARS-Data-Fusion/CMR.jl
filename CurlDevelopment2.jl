using LibCURL

# Constants and Structs
COOKIE_FILENAME = expanduser("~/.urs_cookies")
mutable struct Response
    data::Vector{UInt8}
    file::IO
end

# Callback function
function curl_write_cb(curlbuf::Ptr{Cvoid}, s::Csize_t, n::Csize_t, p_ctxt::Ptr{Response})
    sz = s * n
    data = Array{UInt8}(undef, sz)
    ccall(:memcpy, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, UInt64), data, curlbuf, sz)
    write(unsafe_load(p_ctxt).file, data)
    sz::Csize_t
end

# Common routine for setting up curl
function setup_curl(curl, URL::String; cookie_filename::String = COOKIE_FILENAME)
    curl_easy_setopt(curl, CURLOPT_URL, URL)
    curl_easy_setopt(curl, CURLOPT_COOKIEFILE, cookie_filename)
    curl_easy_setopt(curl, CURLOPT_COOKIEJAR, cookie_filename)
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1)
    curl_easy_setopt(curl, CURLOPT_NETRC, CURL_NETRC_OPTIONAL)
end

# Function to download text file
function download_text(URL::String; cookie_filename::String = COOKIE_FILENAME)::String
    response = Response(Vector{UInt8}(), IOBuffer())
    curl = curl_easy_init()
    setup_curl(curl, URL, cookie_filename=cookie_filename)
    c_curl_write_cb = @cfunction(curl_write_cb, Csize_t, (Ptr{Cvoid}, Csize_t, Csize_t, Ptr{Response}))
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, c_curl_write_cb)
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, response)
    res = curl_easy_perform(curl)
    curl_easy_cleanup(curl)
    return String(take!(response.file))
end

# Function to download binary file
function download_binary(URL::String; cookie_filename::String = COOKIE_FILENAME)::Vector{UInt8}
    response = Response(Vector{UInt8}(), IOBuffer())
    curl = curl_easy_init()
    setup_curl(curl, URL, cookie_filename=cookie_filename)
    c_curl_write_cb = @cfunction(curl_write_cb, Csize_t, (Ptr{Cvoid}, Csize_t, Csize_t, Ptr{Response}))
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, c_curl_write_cb)
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, response)
    res = curl_easy_perform(curl)
    curl_easy_cleanup(curl)
    return take!(response.file)
end

# Function to download any file and write to local file
function download_file(URL::String, local_path::String; cookie_filename::String = COOKIE_FILENAME)
    open(local_path, "w") do f
        response = Response(Vector{UInt8}(), f)
        curl = curl_easy_init()
        setup_curl(curl, URL, cookie_filename=cookie_filename)
        c_curl_write_cb = @cfunction(curl_write_cb, Csize_t, (Ptr{Cvoid}, Csize_t, Csize_t, Ptr{Response}))
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, c_curl_write_cb)
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, response)
        res = curl_easy_perform(curl)
        curl_easy_cleanup(curl)
    end
end
