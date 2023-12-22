local Pkg = require("Pkg")

local Reg = {}

--terra directories
local terradir = Pkg.capturestdout("echo $TERRA_PKG_ROOT")
local regdir = terradir.."/registries"

function Reg.create(args)

    --check args table
    if type(args.name)~="string" then
	error("provide registry `name`")
    elseif type(args.url)~="string" then
	error("provide git `url`")
    end

    --Throw an error if url is not valid
    Pkg.validategiturl(args.url)

    --path to registry root
    local root = regdir.."/"..args.name
    
    --generate registry folder 
    os.execute("mkdir "..root)

    --generate Registry.toml
    local file = io.open(root.."/Registry.toml", "w")  
    file:write("name = \""..args.name.."\"\n")
    file:write("uuid = \""..Pkg.uuid().."\"\n")
    file:write("description = \""..args.name.." local package registry\"\n\n")
    file:write("[packages]\n")
    file:close()

    --create git repo and push to origin
    os.execute(
        "cd "..root.."; "..
        "git init;"..
        "git add .;"..
        "git commit -m \"new registry initialized.\";"..
        "git remote add origin "..args.url..";"..
        "git push -u origin main")
end



return Reg 
