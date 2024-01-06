print("Hello world, from server!")

local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Modules = ReplicatedStorage:WaitForChild("Shared")

local ChunkSettings = require(Modules.ChunkSettings)
local ChunkRenderer = require(Modules.ChunkRenderer)

local RENDER_DISTANCE = ChunkSettings.RENDER_DISTANCE

-- temp render for demo
local chunk_x = 0
local chunk_z = 0

for x = chunk_x - RENDER_DISTANCE, chunk_x + RENDER_DISTANCE do
    for z = chunk_z - RENDER_DISTANCE, chunk_z + RENDER_DISTANCE do 
        ChunkRenderer.LoadChunk(x, z)
    end
end

for x = chunk_x - RENDER_DISTANCE, chunk_x + RENDER_DISTANCE do
    for z = chunk_z - RENDER_DISTANCE, chunk_z + RENDER_DISTANCE do 
        ChunkRenderer.CreateChunk(x, z)
    end
end