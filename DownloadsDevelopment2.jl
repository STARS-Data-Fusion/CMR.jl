using Downloads
using ProgressBars

# Define the URL of the file you want to download
URL = "https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/VNP09GA.002/VNP09GA.A2024045.h08v05.002.2024046104455/VNP09GA.A2024045.h08v05.002.2024046104455.cmr.xml"

# Define the path to your .netrc file
netrc = expanduser("~/.netrc")

# Define the path to your cookies file
cookies = expanduser("~/.urs_cookies")

# Define the destination where the file will be saved
destination = "VNP09GA.A2024045.h08v05.002.2024046104455.cmr.xml"

# Set the environment variables for netrc and cookies
ENV["CURL_NETRC_FILE"] = netrc
ENV["CURL_COOKIE_FILE"] = cookies

# Define the progress function
function progress(dl_total, dl_now, ul_total, ul_now)
    println("dl_total: $dl_total dl_now: $dl_now ul_total: $ul_total ul_now: $ul_now")
    percent = 100 * (dl_now / dl_total)
    println("$percent%")
end

# Download the file with a progress bar
Downloads.download(URL, destination; progress = progress)
