using CMR

URL = URI("https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/VNP09GA.002/VNP09GA.A2024045.h08v05.002.2024046104455/VNP09GA.A2024045.h08v05.002.2024046104455.cmr.xml")
cookie = CookieFile("~/.urs_cookies")
println(curl(URL, cookie=cookie))
