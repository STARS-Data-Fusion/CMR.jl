module ProgressDownloader

using LibCURL
using Downloads
using ProgressMeter

import ..NetCred: NetRCFile

export NetRCFile

import ..Cookies: CookieFile

export CookieFile

import ..AuthenticatedCurl: get_size

const DESC = "Downloading:"

function download_file_with_progress(
        URL::String, 
        destination::String;
        netrc::NetRCFile=NetRCFile(), 
        cookie::CookieFile=nothing,
        desc::String=DESC)
    println("$URL -> $destination")

    # Set the environment variables for netrc
    ENV["CURL_NETRC_FILE"] = netrc.path

    # Set the environment variables for CookieFiles if provided
    if cookie !== nothing
        ENV["CURL_CookieFile_FILE"] = cookie.filename
    end

    file_size = get_size(URL, CookieFile=cookie)
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