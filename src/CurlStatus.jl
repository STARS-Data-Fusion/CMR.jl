module CurlStatus

using URIs
using LibCURL

import ..CurlTypes: CurlHandle

"""
check_status(curl::CurlHandle, URL::URI)::Int

Check the HTTP status code of a given URL using a CurlHandle.

# Arguments
- `curl::CurlHandle`: A CurlHandle object to perform the HTTP request.
- `URL::URI`: The URL to check the status of.

# Returns
- `Int`: The HTTP status code of the URL.

# Throws
- `IOError`: If the HTTP status code is not 200.
"""
function check_status(curl::CurlHandle, URL::URI)::Int
    # retrieve HTTP code
    http_code = Array{Clong}(undef, 1)
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, http_code)
    status = http_code[1]

    # Check if the HTTP status code is 200
    if status != 200
        throw(IOError("status $status for URL: $URL"))
    end

    return status
end

end