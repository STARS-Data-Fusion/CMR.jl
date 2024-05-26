module CurlBuffers

using LibCURL

import ..CurlTypes: CurlHandle, CurlResponseContainer

"""
    curl_write_cb(curlbuf::CurlHandle, s::Csize_t, n::Csize_t, p_ctxt::Ptr{CurlResponseContainer})

This is a callback function that is invoked by `curl_easy_perform`. 

# Arguments
- `curlbuf::CurlHandle`: The buffer from which data is read.
- `s::Csize_t`: The size of the data type in bytes.
- `n::Csize_t`: The number of elements to read.
- `p_ctxt::Ptr{CurlResponseContainer}`: A pointer to the CurlResponseContainer where the response data is written.

The function reads `s * n` bytes of data from `curlbuf` and appends it to the data in the CurlResponseContainer pointed to by `p_ctxt`.

# Returns
- `sz::Csize_t`: The total number of bytes read and written.

# Note
This function uses the `memcpy` C function to copy data from `curlbuf` to a Julia array, and then appends this array to the data in `p_ctxt`.
"""
function curl_write_cb(curlbuf::CurlHandle, s::Csize_t, n::Csize_t, p_ctxt::Ptr{CurlResponseContainer})
    sz = s * n
    data = Array{UInt8}(undef, sz)

    ccall(:memcpy, CurlHandle, (CurlHandle, CurlHandle, UInt64), data, curlbuf, sz)
    append!(unsafe_load(p_ctxt).data, data)

    sz::Csize_t
end

"""
    apply_buffer(curl::CurlHandle)::CurlResponseContainer

This function sets up a buffer for storing the response data from a cURL request.

# Arguments
- `curl::CurlHandle`: The cURL handle for the request.

# Returns
- `buffer::CurlResponseContainer`: A container for the response data.

# Details
The function first creates a new `CurlResponseContainer` with an empty `Vector{UInt8}`. It then sets the cURL options `CURLOPT_WRITEFUNCTION` and `CURLOPT_WRITEDATA` to use this buffer. The `CURLOPT_WRITEFUNCTION` option is set to the `curl_write_cb` function, which is responsible for writing the response data to the buffer. The `CURLOPT_WRITEDATA` option is set to the buffer itself, so that `curl_write_cb` knows where to write the data.
"""
function apply_buffer(curl::CurlHandle)::CurlResponseContainer
    buffer = CurlResponseContainer(Vector{UInt8}())

    c_curl_write_cb = @cfunction(curl_write_cb, Csize_t, (CurlHandle, Csize_t, Csize_t, Ptr{CurlResponseContainer}))
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, c_curl_write_cb)
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, buffer)

    return buffer
end

end