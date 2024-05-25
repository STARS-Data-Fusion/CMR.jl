module ProgressDownloader

using LibCURL
using Downloads
using ProgressMeter

import ..NetCred: NetRCFile

export NetRCFile

import ..Cookies: Cookie

export Cookie

const DESC = "Downloading:"

function get_file_size_for_URL(URL::String; cookie::Cookie=nothing)
    # Initialize a curl easy handle
    curl_handle = curl_easy_init()

    if curl_handle != C_NULL
        # Set the URL
        curl_easy_setopt(curl_handle, CURLOPT_URL, URL)

        # We want the headers
        curl_easy_setopt(curl_handle, CURLOPT_HEADER, 1)

        # But we do not want the body
        curl_easy_setopt(curl_handle, CURLOPT_NOBODY, 1)

        # Make LibCURL silent
        curl_easy_setopt(curl_handle, CURLOPT_VERBOSE, 0)

        if cookie !== nothing
            # Set the cookie file
            curl_easy_setopt(curl_handle, CURLOPT_COOKIEFILE, cookie.filename)

            # Set the cookie jar
            curl_easy_setopt(curl_handle, CURLOPT_COOKIEJAR, cookie.filename)
        end

        # Follow redirects
        curl_easy_setopt(curl_handle, CURLOPT_FOLLOWLOCATION, 1)

        # Enable Netrc
        curl_easy_setopt(curl_handle, CURLOPT_NETRC, CURL_NETRC_OPTIONAL)

        # Perform the request
        curl_easy_perform(curl_handle)

        # Get the content length
        file_size = Array{Clong}(undef, 1)
        curl_easy_getinfo(curl_handle, CURLINFO_CONTENT_LENGTH_DOWNLOAD, file_size)

        # Clean up
        curl_easy_cleanup(curl_handle)

        return file_size[1]
    else
        error("Failed to initialize curl handle")
    end
end

function download_file_with_progress(
        URL::String, 
        destination::String;
        netrc::NetRCFile=NetRCFile(), 
        cookie::Cookie=nothing,
        desc::String=DESC)
    println("$URL -> $destination")

    # Set the environment variables for netrc
    ENV["CURL_NETRC_FILE"] = netrc.path

    # Set the environment variables for cookies if provided
    if cookie !== nothing
        ENV["CURL_COOKIE_FILE"] = cookie.filename
    end

    file_size = get_file_size_for_URL(URL, cookie=cookie)
    println("size: $file_size")

    # Check if the file already exists with the correct size
    if isfile(destination) && filesize(destination) == file_size
        println("File already exists with the correct size. Skipping download.")
        return
    end

    # Define the progress bar
    progress_bar = Progress(100, desc)

    # Define the progress function
    last_percent = Ref(0)
    function progress(dl_total, dl_now, ul_total, ul_now)
        if dl_total != 0
            percent = round(Int, dl_now / dl_total * 100)
            if percent != last_percent[]
                ProgressMeter.update!(progress_bar, percent)
                last_percent[] = percent
            end
        end
    end

    # Download the file with a progress bar
    Downloads.download(URL, destination; progress = progress)
end

end