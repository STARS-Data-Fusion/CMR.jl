module CurlTypes

const CurlHandle = Ptr{Cvoid}

"""
    Response

A mutable struct that holds the response data.
"""
mutable struct CurlResponseContainer
    data::Vector{UInt8}
end

end