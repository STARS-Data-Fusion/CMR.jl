module NetCred

import Base: show, getpass, write, read

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

const DEFAULT_NETRC = NetRCFile()

export DEFAULT_NETRC

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
    # if netrcfile.path does not exist, create it
    if !isfile(netrcfile.path)
        open(netrcfile.path, "w") do io
            write(io, "")
        end
    end

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

"""
    enter_cred(machine::String; need_account::Bool = false)::NetRCCredentials

Prompt the user to enter their login credentials for a given machine. If `need_account` is true, 
the user will also be prompted to enter their account name.

# Arguments
- `machine::String`: The name of the machine for which the credentials are being entered.
- `need_account::Bool`: A flag indicating whether an account name is required. Default is false.

# Returns
- `NetRCCredentials`: A `NetRCCredentials` object containing the entered credentials.

# Examples
```julia
creds = enter_cred("my_machine", need_account=true)
```
"""
function enter(machine::String; need_account::Bool = false)::NetRCCredentials
    print("login: ")
    login = string(chomp(readline()))
    password = string(getpass("password"))
    println("")
    
    if need_account
        account = string(getpass("account"))
        println("")
    else
        account = ""
    end

    NetRCCredentials(machine, login, password, account)
end 

export enter

function get_cred(machine::String)::NetRCCredentials
    netrc = NetRCFile()
    try
        cred = read(netrc, machine)
        @info "credentials read from .netrc: $machine"
        return cred
    catch e
        println("enter credentials for $machine")
        cred = enter(machine)
        @info "writing credentials to .netrc: $machine"
        write(netrc, cred)

        return cred
    end
end

export get_cred

end