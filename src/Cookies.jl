module Cookies

using LibCURL

import Base: expanduser

using ..CurlTypes: CurlHandle

struct CookieFile
    filename::String

    function CookieFile(filename::String)
        new(expanduser(filename))
    end
end

export CookieFile

const DEFAULT_COOKIE = nothing

export DEFAULT_COOKIE

"""
    apply_cookie(curl::Ptr{Cvoid}, cookie::CookieFile)

This function applies the provided cookie settings to the given curl handle. If a `CookieFile` is provided, 
it sets both the cookie file and the cookie jar to the filename of the `CookieFile`. If `nothing` is provided as the `CookieFile`, 
the function does not modify the curl handle.

# Arguments
- `curl::Ptr{Cvoid}`: A pointer to the curl handle to which the cookie settings will be applied.
- `cookie::CookieFile`: The `CookieFile` settings to be applied. If `nothing`, no settings are applied.

# Example
```julia
apply_cookie(curl_handle, my_cookie)
```
"""
function apply_cookie(curl::CurlHandle, cookie::CookieFile)
    if cookie !== nothing
        # Set the cookie file
        curl_easy_setopt(curl, CURLOPT_COOKIEFILE, cookie.filename)

        # Set the cookie jar
        curl_easy_setopt(curl, CURLOPT_COOKIEJAR, cookie.filename)
    end
end

export apply_cookie

end