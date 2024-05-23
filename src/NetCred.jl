module NetCred

import Base: show

struct NetRCFileNotFoundError <: Exception
    msg::String
end

export NetRCFileNotFoundError

struct NetRCFileEmptyError <: Exception
    msg::String
end

export NetRCFileEmptyError

struct NetRCCredentialsNotFoundError <: Exception
    msg::String
end

export NetRCCredentialsNotFoundError

struct NetRCCredentials
    machine::String
    login::String
    password::String
    account::String

    NetRCCredentials(machine::String, login::String, password::String, account::String="") = new(machine, login, password, account)
end

function show(io::IO, creds::NetRCCredentials)
    println(io, "NetRCCredentials(")
    println(io, "  machine: ", creds.machine)
    println(io, "  login: ", creds.login)
    println(io, "  password: ", "*" ^ length(creds.password))
    if creds.account != ""
        println(io, "  account: ", "*" ^ length(creds.account))
    end
    print(io, ")")
end

export NetRCCredentials

struct NetRCFile
    path::String

    NetRCFile(path::String=joinpath(homedir(), ".netrc")) = new(path)
end

export NetRCFile

"""
    read(netrcfile::NetRCFile, machine::String) -> NetRCCredentials

Reads the .netrc file and returns the credentials for the specified machine as a `NetRCCredentials` struct.

# Arguments
- `netrcfile::NetRCFile`: The .netrc file to read from.
- `machine::String`: The name of the machine for which to retrieve the credentials.

# Returns
- `NetRCCredentials`: A struct containing the machine name, login, password, and account for the specified machine.

# Throws
- `NetRCFileNotFoundError`: If the .netrc file does not exist.
- `NetRCFileEmptyError`: If the .netrc file is empty.
- `NetRCCredentialsNotFoundError`: If the .netrc file does not contain the desired credentials.
"""
function read(netrcfile::NetRCFile, machine::String) :: NetRCCredentials
    if !isfile(netrcfile.path)
        throw(NetRCFileNotFoundError(".netrc file does not exist."))
    end

    lines = readlines(netrcfile.path)

    if isempty(lines)
        throw(NetRCFileEmptyError(".netrc file is empty."))
    end

    login = password = account = ""

    for i in eachindex(lines)
        if lines[i] == "machine $machine" || lines[i] == "default"
            login = String(split(lines[i+1])[2])
            password = String(split(lines[i+2])[2])
            
            if i+3 <= length(lines) && lines[i+3] == "account"
                account = String(split(lines[i+4])[2])
            end

            return NetRCCredentials(machine, login, password, account)
        end
    end

    throw(NetRCCredentialsNotFoundError("No credentials found for machine $machine."))
end

export read

"""
    write(netrcfile::NetRCFile, credentials::NetRCCredentials)

Writes the provided credentials to the .netrc file for the specified machine. If the .netrc file does not exist, it is created. If the machine is already listed in the .netrc file, the existing credentials are updated.

# Arguments
- `netrcfile::NetRCFile`: The .netrc file to write to.
- `credentials::NetRCCredentials`: The credentials to store, including the machine name, login, password, and account.
"""
function write(netrcfile::NetRCFile, credentials::NetRCCredentials)
    lines = isfile(netrcfile.path) ? readlines(netrcfile.path) : String[]
    machine_line = findfirst(x -> x == "machine $(credentials.machine)", lines)

    if machine_line !== nothing
        lines[machine_line+1] = "login $(credentials.login)"
        lines[machine_line+2] = "password $(credentials.password)"

        if credentials.account != ""
            lines[machine_line+3] = "account $(credentials.account)"
        end
    else
        append!(lines, ["machine $(credentials.machine)", "login $(credentials.login)", "password $(credentials.password)"])

        if credentials.account != ""
            append!(lines, ["account $(credentials.account)"])
        end
    end

    open(netrcfile.path, "w") do io
        write(io, join(lines, "\n"))
    end
end

export write

end # module
