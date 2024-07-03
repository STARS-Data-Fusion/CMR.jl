using Downloads

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

# Download the file
Downloads.download(URL, destination)
