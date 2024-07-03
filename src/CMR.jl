module CMR

using URIs
using Crayons.Box
using Logging
using Dates
using HTTP
using JSON
using DataFrames
using GeometryBasics

export URI

include("CurlTypes.jl")
include("NetCred.jl")
include("Cookies.jl")
include("CurlOptions.jl")
include("CurlBuffers.jl")
include("CurlStatus.jl")
include("CurlHead.jl")
include("AuthenticatedCurl.jl")
include("ProgressDownloader.jl")

import .NetCred: NetRCFile, get_cred

export NetRCFile, get_cred

import .Cookies: CookieFile, apply_cookie

export CookieFile

# import .AuthenticatedCurl: head, get_size, curl, curl_binary
using .AuthenticatedCurl

export head, get_size, curl, curl_binary

using .ProgressDownloader

logger = ConsoleLogger()
global_logger(logger)

DEFAULT_CMR_URL = "https://cmr.earthdata.nasa.gov"
URL_FORMAT = merge(BLUE_FG, UNDERLINE)
VALUE_FORMAT = YELLOW_FG
TILE_FORMAT = YELLOW_FG
CONCEPT_ID_FORMAT = YELLOW_FG
DATE_FORMAT = BLUE_FG
PAGE_SIZE = 2000

"""
    get_JSON_response(URL::String)::Dict{String, Any}

Sends a GET request to the specified URL and returns the JSON response.

# Arguments
- `URL::String`: The URL to which the GET request is sent.

# Returns
- `Dict{String, Any}`: A dictionary representing the JSON response. The keys are the JSON field names, and the values are the corresponding field values.

# Exceptions
- Throws an `IOError` if the HTTP status code of the response is not 200.

# Example
```julia
data = get_JSON_response("https://api.example.com/data")
```
"""
function get_JSON_response(URL::String)::Dict{String, Any}
    # Make a GET request to the URL
    response = HTTP.get(URL)

    # If the status is not 200, throw an error
    if response.status != 200
        throw(IOError("status $(response.status) for URL: $URL"))
    end

    # Parse the response body to JSON and return
    JSON.parse(String(response.body))
end

"""
    generate_product_concept_ID_search_URL(product_name::String; CMR_URL::String = DEFAULT_CMR_URL)::String

Generates a URL for searching a product concept ID in the CMR (Common Metadata Repository).

# Arguments
- `product_name::String`: The name of the product for which the concept ID is to be searched.
- `CMR_URL::String`: The base URL of the CMR. Defaults to `DEFAULT_CMR_URL`.

# Returns
- `String`: The generated URL for searching the product concept ID.

# Example
```julia
generate_product_concept_ID_search_URL("MODIS")
```
"""
function generate_product_concept_ID_search_URL(
        product_name::String; 
        CMR_URL::String = DEFAULT_CMR_URL)::String
    "$CMR_URL/search/collections.json?short_name=$product_name"
end

export generate_product_concept_ID_search_URL

"""
    search_product_concept_ID(product_name::String; CMR_URL::String = DEFAULT_CMR_URL)::DataFrame

Search for a product's concept ID in the CMR database.

# Arguments
- `product_name::String`: The name of the product to search for.
- `CMR_URL::String`: The base URL of the CMR database. Defaults to `DEFAULT_CMR_URL`.

# Returns
- `DataFrame`: A DataFrame containing the product name, collection number, and concept ID for each matching product collection.

# Example
```julia
df = search_product_concept_ID("VNP09GA")
```
"""
function CMR_search_product_concept_ID(
        product_name::String;
        CMR_URL::String = DEFAULT_CMR_URL)::DataFrame
    # Generate the URL for searching product concept ID
    product_concept_ID_search_URL = generate_product_concept_ID_search_URL(product_name, CMR_URL=CMR_URL)
    # Get the JSON response from the URL
    response_dict = get_JSON_response(product_concept_ID_search_URL)
    
    # Initialize an empty DataFrame
    df = DataFrame(product_name = String[], collection = Int[], concept_ID = String[])

    # Loop through each item in the response
    for item in response_dict["feed"]["entry"]
        # Get the product name, collection, and concept ID
        product_name = item["short_name"]
        collection = parse(Int, String(item["version_id"]))
        concept_id = item["id"]
        # Add the data to the DataFrame
        push!(df, (product_name, collection, concept_id))
    end

    df
end

export CMR_search_product_concept_ID

"""
    get_product_concept_ID(
        product_name::String, 
        collection::Int,
        CMR_URL::String = DEFAULT_CMR_URL)::String

This function retrieves the product concept ID from the CMR (Common Metadata Repository).

# Arguments
- `product_name::String`: The name of the product for which the concept ID is to be retrieved.
- `collection::Int`: The collection number to be searched in the product's concept IDs.
- `CMR_URL::String`: The URL of the CMR. By default, it uses the value of `DEFAULT_CMR_URL`.

# Returns
- `String`: The concept ID of the specified product collection. If the concept is not found, it returns `nothing`.

# Examples
```julia
get_product_concept_ID("VNP09GA", 2)
```
"""
function get_CMR_product_concept_ID(
        product_name::String, 
        collection::Int,
        CMR_URL::String = DEFAULT_CMR_URL)::String
    # Search for the product concept ID
    df = CMR_search_product_concept_ID(product_name, CMR_URL=CMR_URL)
    # Return the concept ID of the specified collection
    get(df[df.collection .== collection, :concept_ID], 1, nothing)
end

export get_CMR_product_concept_ID

"""
    format_date(date::Union{Date,String})::String

Convert a date, which can be either a `Date` object or a `String`, into a string in the "yyyy-mm-dd" format.

# Arguments
- `date::Union{Date,String}`: The date to format. If a string, it should be in the "yyyy-mm-dd" format.

# Returns
- `String`: The date formatted as a string in the "yyyy-mm-dd" format.

# Examples
```julia
julia> format_date(Date(2022, 12, 31))
"2022-12-31"

julia> format_date("2022-12-31")
"2022-12-31"
```
"""
function format_date(date::Union{Date,String})::String
    if typeof(date) == String
        date = Dates.Date(date, "yyyy-mm-dd")
    end

    Dates.format(date, "yyyy-mm-dd")
end

"""
    generate_CMR_date_range(start_date::Union{Date,String}, end_date::Union{Date,String})::String

Generate a date-range query string for CMR (Common Metadata Repository) in ISO 8601 format.

# Arguments
- `start_date`: The start date of the range. Can be a `Date` object or a `String` in "yyyy-mm-dd" format.
- `end_date`: The end date of the range. Can be a `Date` object or a `String` in "yyyy-mm-dd" format.

# Returns
- A `String` representing the date range in the format "yyyy-mm-ddT00:00:00Z/yyyy-mm-ddT23:59:59Z".

# Example
```julia
generate_CMR_date_range(Date(2022, 1, 1), Date(2022, 12, 31))
```

"""
function generate_CMR_date_range(start_date::Union{Date,String}, end_date::Union{Date,String})::String
    "$(format_date(start_date))T00:00:00Z/$(format_date(end_date))T23:59:59Z"
end

function generate_CMR_granule_search_tile_URL(
        concept_ID::String,
        tile::String,
        start_date::Union{Date,String},
        end_date::Union{Date,String};
        page_size::Int = PAGE_SIZE,
        CMR_URL::String = DEFAULT_CMR_URL)::String
    datetime_range = generate_CMR_date_range(start_date, end_date)
    URL = "$CMR_URL/search/granules.json?concept_id=$(concept_ID)&temporal=$(datetime_range)&page_size=$(page_size)&producer_granule_id=*$(tile)*&options[producer_granule_id][pattern]=true"

    return URL
end

export generate_CMR_granule_search_tile_URL

function generate_CMR_granule_search_URL_polygon(
        concept_ID::String,
        polygon::GeometryBasics.Polygon,
        start_date::Union{Date,String},
        end_date::Union{Date,String};
        page_size::Int = PAGE_SIZE,
        CMR_URL::String = DEFAULT_CMR_URL)::String
    datetime_range = generate_CMR_date_range(start_date, end_date)
    polygon_coords = join(["$(coord[1]),$(coord[2])" for coord in coordinates(polygon)], ",")
    URL = "$CMR_URL/search/granules.json?concept_id=$(concept_ID)&temporal=$(datetime_range)&page_size=$(page_size)&polygon=$polygon_coords"

    return URL
end

export generate_CMR_granule_search_URL_polygon

function query_CMR_URL_as_JSON(URL::String)::Dict
    # send get request for the CMR query URL
    @info string("CMR API query for concept ID ", CONCEPT_ID_FORMAT(concept_ID), " at tile ", TILE_FORMAT(tile), " from ", DATE_FORMAT("$(start_date)"), " to ", DATE_FORMAT("$(end_date)"), " with URL: ", URL_FORMAT(URL))
    response = HTTP.get(URL)

    # check the status code of the response and make sure it's 200 before parsing JSON
    status = response.status

    if status != 200
        error("CMR API status $(status) for URL: $(query_URL)")
    end

    # parse JSON response from successful (200) CMR query
    JSON.parse(String(response.body))
end

export query_CMR_URL_as_JSON

function CMR_granule_search_tile_JSON(
        concept_ID::String,
        tile::String,
        start_date::Union{Date,String},
        end_date::Union{Date,String};
        page_size::Int = PAGE_SIZE,
        CMR_URL::String = DEFAULT_CMR_URL)::Dict
    query_CMR_URL_as_JSON(generate_CMR_granule_search_tile_URL(
        concept_ID,
        tile,
        start_date,
        end_date,
        page_size = page_size,
        CMR_URL = CMR_URL
    ))
end

export CMR_granule_search_tile_JSON

function CMR_granule_search_polygon(
        concept_ID::String,
        polygon::GeometryBasics.Polygon,
        start_date::Union{Date,String},
        end_date::Union{Date,String};
        page_size::Int = PAGE_SIZE,
        CMR_URL::String = DEFAULT_CMR_URL)::Dict
    query_CMR_URL_as_JSON(generate_CMR_granule_search_URL_polygon(
        concept_ID,
        polygon,
        start_date,
        end_date,
        page_size = page_size,
        CMR_URL = CMR_URL
    ))
end

export CMR_granule_search_polygon

end
