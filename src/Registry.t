local Pkg = require("Pkg")
local Example = Pkg.require("Example")

local S = {}

Example.helloterra()

function S.helloterra()
  print("hello terra!")
end

return S