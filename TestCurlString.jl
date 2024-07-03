include("CurlDevelopment4.jl")

URL = "https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/VNP09GA.002/VNP09GA.A2024045.h08v05.002.2024046104455/VNP09GA.A2024045.h08v05.002.2024046104455.cmr.xml"
println("calling download_text")
result = download_text(URL)
# println(result)
