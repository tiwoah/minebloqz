local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Shared")



module.BuildQueue = {}
module.DeleteQueue = {}



return module