using JSON
using CMR

URL = URI("https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/VNP09GA.002/VNP09GA.A2024045.h08v05.002.2024046104455/VNP09GA.A2024045.h08v05.002.2024046104455.h5")
cookie = Cookie(expanduser("~/.urs_cookies"))
println(get_size(URL, cookie=cookie))
