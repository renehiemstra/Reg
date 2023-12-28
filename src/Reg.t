import "terratest"

local Pkg = require("Pkg")

local Reg = {}

--terra directories
local terradir = Pkg.capturestdout("echo $TERRA_PKG_ROOT")
local regdir = terradir.."/registries"

local function esc(string)
  return "\""..string.."\""
end

local function save(reg, root)
    if type(reg) == "table" then
        --open Registry.t and set to stdout
        local file = io.open(root.."/Registry.t", "w")
        io.output(file)
        
        --write main project data to file
        io.write("Registry = {\n")
        io.write(string.format("    name = %q,\n", reg.name))
        io.write(string.format("    uuid = %q,\n", reg.uuid))
        io.write(string.format("    url  = %q,\n", reg.url))
        io.write(string.format("    description  = %q,\n", reg.description))
	--write hosted packages
        io.write("    ", "packages = {\n")
        for k,v in pairs(reg.packages) do
            io.write("        ", k, string.format(" = %q,\n", v))
        end
        io.write("    }\n")
        io.write("}\n")
	io.write("return Registry")
        
        --close file
        io.close(file)
    else
        error("provide a table")
    end 
end 

--register a package using {name="RegistryName", url="git url"}
function Reg.register(args)
    --check keyword arguments
    if args.name==nil or args.url==nil then
        error("provide registry `name` and package git `url`.\n")
    end 
    if type(args.name)~="string" then
	error("provide registry `name`")
    elseif type(args.url)~="string" then 
  	error("provide git `url`")
    end

    --find registry
    local root = regdir.."/"..args.name
    if not Pkg.isfolder(root) then
	error("provide a valid registry `name`")
    end

    --clone terra pkg in temporary directory
    Pkg.clone{root=terradir.."/clones/tmp", url=args.url}

    --open pkg project file
    local pkgname = Pkg.namefromgiturl(args.url)
    local project = require("clones/tmp/"..pkgname.."/Project")

    --update pkg list and save
    local registry = require("registries/"..args.name.."/Registry")
    registry.packages[pkgname] = project.uuid            
    save(registry, root)

    --cleanup
    os.execute("rm -rf "..terradir.."/clones/tmp")
end

function Reg.create(args)
    --check args table
    if type(args.name)~="string" then
	error("provide registry `name`")
    elseif type(args.url)~="string" then
	error("provide git `url`")
    end

    --Throw an error if url is not valid
    if not Pkg.validemptygitrepo(args.url) then
	error("Provide an empty git repository\n")
    end  

    --path to registry root
    local root = regdir.."/"..args.name
    
    --generate registry folder 
    os.execute("mkdir "..root)

    --generate Registry.toml
    local file = io.open(root.."/Registry.t", "w")
    file:write("Registry = {\n")  
    file:write("    name = \""..args.name.."\",\n")
    file:write("    uuid = \""..Pkg.uuid().."\",\n")
    file:write("    url  = \""..args.url.."\",\n")
    file:write("    description = \""..args.name.." local package registry\",\n")
    file:write("    packages = {}\n")
    file:write("}\n")
    file:write("return Registry")
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

testenv "Unit test Registry.t" do

testset "save Registry.t" do
    local table1 = require("registries/MyRegistry/Registry")
    Reg.save(table1, ".")
    local table2 = require("Reg/src/Registry")
    
    local t1 = table1.name == "MyRegistry" and table2.name=="MyRegistry"
    test t1
    
    local t2 = table1.uuid == table2.uuid
    test t2
    os.execute("rm Registry.t")
end

end



return Reg 
