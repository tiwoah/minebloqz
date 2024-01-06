module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Shared")

local ChunkSettings = require(Modules.ChunkSettings)

--
local CHUNK_SIZE = ChunkSettings.CHUNK_SIZE



module.GetSurfaceHeight = function(x, z, relativeBlockX, relativeBlockZ, SEED)
    local noiseLayer1_X_SCALE = 2
    local noiseLayer1_Z_SCALE = 2
    local noiseLayer1_AMP = 12
    local noiseLayer1 = math.noise(
        ((relativeBlockX / CHUNK_SIZE / noiseLayer1_X_SCALE)) + x / noiseLayer1_X_SCALE,
        ((relativeBlockZ / CHUNK_SIZE / noiseLayer1_Z_SCALE)) + z / noiseLayer1_Z_SCALE,
        SEED
    )

    local noiseLayerHills_SCALE = 5
    local noiseLayerHills_AMP = 16
    local noiseLayerHills = math.noise(
        ((relativeBlockX / CHUNK_SIZE / noiseLayerHills_SCALE)) + x / noiseLayerHills_SCALE,
        ((relativeBlockZ / CHUNK_SIZE / noiseLayerHills_SCALE)) + z / noiseLayerHills_SCALE,
        SEED + 2
    )

    local layers = noiseLayer1 * noiseLayer1_AMP

    if noiseLayerHills > 0 then
        layers += noiseLayerHills * noiseLayerHills_AMP
    end

    local height = math.floor(layers)

    return height
end

return module