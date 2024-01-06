local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Shared")

local ChunkSettings = require(Modules.ChunkSettings)
local DebugHandler = require(Modules.DebugHandler)
local ResourceIDs = require(Modules.ResourceIDs)
local SurfaceGeneration = require(Modules.SurfaceGeneration)

local ReplicatedBlocks = ReplicatedStorage:WaitForChild("Blocks")
local DebugUtils = ReplicatedStorage:WaitForChild("DebugUtils")

local RenderStepped = RunService.Heartbeat


module.EditedBlocks = {} -- TODO
module.LoadedChunks = {}




--
local ChunkWidth = ChunkSettings.BLOCK_SIZE * ChunkSettings.CHUNK_SIZE
local ChunkHeight = (ChunkSettings.MAX_HEIGHT + math.abs(ChunkSettings.MIN_HEIGHT)) * ChunkSettings.BLOCK_SIZE
local Chunks = workspace:WaitForChild("Chunks")
local RENDER_DISTANCE = ChunkSettings.RENDER_DISTANCE
local CHUNK_SIZE = ChunkSettings.CHUNK_SIZE
local BLOCK_SIZE = ChunkSettings.BLOCK_SIZE
local ChunkNumber = DebugUtils:WaitForChild("ChunkNumber")
local ChunkOutline = DebugUtils:WaitForChild("ChunkOutline")
local ChunkOutline = DebugUtils:WaitForChild("ChunkOutline")
local EndPositionXVisualizer = DebugUtils:WaitForChild("EndPositionXVisualizer")
local StartPositionXVisualizer = DebugUtils:WaitForChild("StartPositionXVisualizer")
local JoinedPositionXVisualizer = DebugUtils:WaitForChild("JoinedPositionXVisualizer")
local isServer = RunService:IsServer()


local SEED = 10


--[[ Fundamental ]]--


module.wait = function(amount) -- Wait for shorter amount of time than normal
	if math.random(1, 1000) <= amount then
		task.wait()
	end
end

module.quickWait = function(waitTime) -- Malte0621, untested method
    --[[
        **Minimum possible wait times (rounded)**
        quickWait: 0.00001 seconds (and lower)
        task.wait: 0.01 seconds
        wait: 0.03 seconds
    ]]
	local startTime = os.clock()

	local currentTime = os.clock()
	while os.clock() - startTime <= waitTime do
		if os.clock() - currentTime >= 0.01 then
			RenderStepped:Wait()
			currentTime = os.clock()
		end
	end
	return os.clock() - startTime
end



--[[ Chunk Handling ]]--

module.InitializeChunk = function(x, z)
	if not module.LoadedChunks[x] then
		module.LoadedChunks[x] = {}
	end

    module.LoadedChunks[x][z] = {}
    module.LoadedChunks[x][z].SurfaceBlocks = {}
    module.LoadedChunks[x][z].Blocks = {}
    module.LoadedChunks[x][z].ChunkBoundaries = nil
    module.LoadedChunks[x][z].Rendered = false
    module.LoadedChunks[x][z].Active = false
    module.LoadedChunks[x][z].Finished = false
end

module.GetChunkState = function(x, z) -- Determine if chunk exists, is being loaded, currently being manipulated, and if rendered
    if module.LoadedChunks[x] == nil then return false, false, false end

    if module.LoadedChunks[x][z] then
        return true, module.LoadedChunks[x][z].Finished, module.LoadedChunks[x][z].Active, module.LoadedChunks[x][z].Rendered
    end

	return false, false, false, false
end

module.UpdateSurfaceBlockInfoInChunk = function(x, z, relativeBlockX, relativeBlockZ, relativeBlockY, info)
    local CurrentChunkSurfaceBlocks = module.LoadedChunks[x][z].SurfaceBlocks

    if not CurrentChunkSurfaceBlocks[relativeBlockX] then
        CurrentChunkSurfaceBlocks[relativeBlockX] = {}
    end

    if not CurrentChunkSurfaceBlocks[relativeBlockX][relativeBlockZ] then
        CurrentChunkSurfaceBlocks[relativeBlockX][relativeBlockZ] = {}
    end

    if not CurrentChunkSurfaceBlocks[relativeBlockX][relativeBlockZ][relativeBlockY] then
        CurrentChunkSurfaceBlocks[relativeBlockX][relativeBlockZ][relativeBlockY] = {}
    end

    -- Assign block information to relative coordinates
	CurrentChunkSurfaceBlocks[relativeBlockX][relativeBlockZ][relativeBlockY] = info
end

--[[ Chunk Loader ]]--

module.LoadChunk = function(x, z) -- Loads all block information for a chunk
    local Exists, IsLoaded, IsActive = module.GetChunkState(x, z)
    if Exists then warn("Attempt to load already-loaded chunk.") return end

    module.InitializeChunk(x, z)


	local ChunkFolder = Instance.new("Folder")
	ChunkFolder.Name = tostring(x) .. " " .. tostring(z)
	ChunkFolder.Parent = Chunks

	local Boundary = Instance.new("Part")
	Boundary.Size = Vector3.new(ChunkWidth, ChunkHeight, ChunkWidth)
	Boundary.Anchored = true
	Boundary.CFrame = CFrame.new((ChunkWidth / 2) + x * ChunkWidth, 0, (ChunkWidth / 2) + z * ChunkWidth)
	Boundary.Name = tostring(x) .. " " .. tostring(z)
	Boundary.Transparency = 1
    Boundary.CanCollide = (RENDER_DISTANCE ~= 0) and (not isServer)

    local Outline = ChunkOutline:Clone()
    Outline.Adornee = Boundary
    Outline.Visible = DebugHandler.Enabled
    Outline.Parent = Boundary

	Boundary.Parent = ChunkFolder


    local CurrentChunk =  module.LoadedChunks[x][z]

	for relativeBlockX = 1, CHUNK_SIZE do
        CurrentChunk.Blocks[relativeBlockX] = CurrentChunk.Blocks[relativeBlockX] or {}
        CurrentChunk.SurfaceBlocks[relativeBlockX] = CurrentChunk.SurfaceBlocks[relativeBlockX] or {}

		for relativeBlockZ = 1, CHUNK_SIZE do
            CurrentChunk.Blocks[relativeBlockX][relativeBlockZ] = CurrentChunk.Blocks[relativeBlockX][relativeBlockZ] or {}
            CurrentChunk.SurfaceBlocks[relativeBlockX][relativeBlockZ] = CurrentChunk.SurfaceBlocks[relativeBlockX][relativeBlockZ] or {}

            -- local block = math.random(1, 4) <= 3 and "grass_block" or "dirt"

            -- TODO: check for edited block first
            local height = SurfaceGeneration.GetSurfaceHeight(x, z, relativeBlockX, relativeBlockZ, SEED)
            module.UpdateSurfaceBlockInfoInChunk(x, z, relativeBlockX, relativeBlockZ, height, "grass_block")
			module.wait(ChunkSettings.LOAD_DELAY)
		end
	end

	module.LoadedChunks[x][z].ChunkBoundaries = Boundary
	module.LoadedChunks[x][z].Container = ChunkFolder
	module.LoadedChunks[x][z].Finished = true
end




--[[ Block Handling ]]--

module.GetReplicatedBlock = function(BlockID)
    local ReplicatedBlock = ReplicatedBlocks:FindFirstChild(BlockID)
    if ReplicatedBlock then
        return ReplicatedBlock
    else
        warn("Replicated block could not be found.")
        return nil
    end
end

module.GetBlockPositionFromCoords = function(chunk_x, chunk_z, relativeBlockX, relativeBlockZ, relativeBlockY) 
	local x = BLOCK_SIZE * (relativeBlockX - 1) + (BLOCK_SIZE/2) + (chunk_x * BLOCK_SIZE * CHUNK_SIZE)
	local y = relativeBlockY * 3 + (BLOCK_SIZE/2)
	local z = BLOCK_SIZE * (relativeBlockZ - 1) + (BLOCK_SIZE/2) + (chunk_z * BLOCK_SIZE * CHUNK_SIZE)
	
	return Vector3.new(x, y, z)
end

module.GetSurfaceBlockFromCoordinates = function(x, z, relativeBlockX, relativeBlockZ, relativeBlockY)
    local Exists, IsLoaded, IsActive = module.GetChunkState(x, z)
    if not Exists then warn("Attempt to get surface block from unloaded chunk.") return end
    
    local block = nil
    local success, result = pcall(function()
        block = module.LoadedChunks[x][z].SurfaceBlocks[relativeBlockX][relativeBlockZ][relativeBlockY]
    end)

    return block
end

module.PlaceBlock = function(x, z, relativeBlockX, relativeBlockZ, relativeBlockY, id)
    local block = module.GetReplicatedBlock(id)
    if block == nil then warn("Could not place block. ID not found in Replicated Blocks.") return end
	
	local newBlock = block:Clone()
    local position = module.GetBlockPositionFromCoords(x, z, relativeBlockX, relativeBlockZ, relativeBlockY)
	if newBlock:IsA("Model") then
		newBlock:PivotTo(
			CFrame.new(position)
		)
	else
        newBlock.CFrame = CFrame.new(position)
	end

	-- module.OptimizeBlock(x, z, relativeX, relativeZ, relativeY, newBlock)
	newBlock.Parent = module.LoadedChunks[x][z].Container
	
	return newBlock
end

module.PlaceGreedBlock = function(x, z, relativeBlockX, relativeBlockZ, relativeBlockY, endPositionX, endPositionZ, endPositionY, id)
    local block = module.GetReplicatedBlock(id)
    if block == nil then warn("Could not place block. ID not found in Replicated Blocks.") return end
	
	local newBlock = block:Clone()
	if newBlock:IsA("Model") then
        warn("Attempt to combine model.")
        -- ? Cannot expand a model. This should not occur.
	else
        newBlock.Size = newBlock.Size + Vector3.new(BLOCK_SIZE * (endPositionX - 1), BLOCK_SIZE * (endPositionY - 1), BLOCK_SIZE * (endPositionZ - 1))

        local OriginalPosition = module.GetBlockPositionFromCoords(x, z, relativeBlockX, relativeBlockZ, relativeBlockY)
        local NewPosition = OriginalPosition + Vector3.new((endPositionX - 1) * BLOCK_SIZE / 2, (endPositionY - 1) * BLOCK_SIZE / 2, (endPositionZ - 1) * BLOCK_SIZE / 2)
        newBlock.CFrame = CFrame.new(NewPosition)
	end

	-- module.OptimizeBlock(x, z, relativeX, relativeZ, relativeY, newBlock)
	newBlock.Parent = module.LoadedChunks[x][z].Container
	
	return newBlock
end

local AddToSkip = function(ToSkip, x, z, y)
    ToSkip[x] = ToSkip[x] or {}
    ToSkip[x][z] = ToSkip[x][z] or {}
    ToSkip[x][z][y] = true

    return ToSkip
end

local IsInToSkip = function(ToSkip, x, z, y)
    local InToSkip = false
    local success, result = pcall(function()
        InToSkip = ToSkip[x][z][y]
    end)
    if not success then return false end
    return InToSkip
end

-- setup visualisation of greedy algorithm if needed
local visualStartX = StartPositionXVisualizer:Clone()
visualStartX.Parent = workspace
visualStartX.CFrame = CFrame.new(0,-400, 0)

local visualX = EndPositionXVisualizer:Clone()
visualX.Parent = workspace
visualX.CFrame = CFrame.new(0,-400, 0)

module.GreedyBlockPlace = function(x, z, relativeBlockX, relativeBlockZ, relativeBlockY, id, ToSkip)
    local endPositionX, endPositionZ, endPositionY = 0, 0, 1
    local FoundUnsimilarZ = false
    for i = 1, CHUNK_SIZE do
        local AdjacentSurfaceBlockInPositiveX = module.GetSurfaceBlockFromCoordinates(x, z, relativeBlockX + i - 1, relativeBlockZ, relativeBlockY)
        
        if not AdjacentSurfaceBlockInPositiveX then break end
        if AdjacentSurfaceBlockInPositiveX ~= id then break end
        if IsInToSkip(ToSkip, relativeBlockX + i - 1, relativeBlockZ, relativeBlockY) then break end

        if i == 1 then
            endPositionX += 1
        end

        if i ~= 1 and endPositionZ == 1 then
            endPositionX += 1
            AddToSkip(ToSkip, relativeBlockX + i - 1, relativeBlockZ, relativeBlockY)
        end

        -- local visualXCFrame = CFrame.new(module.GetBlockPositionFromCoords(x, z, relativeBlockX + endPositionX - 1, relativeBlockZ + endPositionZ - 1, relativeBlockY))
        -- visualX.CFrame = visualXCFrame
        -- wait(0.1)

        for j = 1, CHUNK_SIZE do
            if FoundUnsimilarZ then break end
            if i ~= 1 and j > endPositionZ then
                break
            end
            local AdjacentSurfaceBlock = module.GetSurfaceBlockFromCoordinates(x, z, relativeBlockX + i - 1, relativeBlockZ + j - 1, relativeBlockY)
            if not AdjacentSurfaceBlock then if i ~= 1 then FoundUnsimilarZ = true end break end
            if AdjacentSurfaceBlock ~= id then if i ~= 1 then FoundUnsimilarZ = true end  break end
            if IsInToSkip(ToSkip, relativeBlockX + i - 1, relativeBlockZ + j - 1, relativeBlockY) then if i ~= 1 then FoundUnsimilarZ = true end  break end

            if i == 1 then
                endPositionZ += 1
                AddToSkip(ToSkip, relativeBlockX + i - 1, relativeBlockZ + j - 1, relativeBlockY)
            end

            -- completed another full Z axis row of eligible blocks to combine
            if j == endPositionZ and i ~= 1 then
                endPositionX += 1

                -- add all of the new X to the current Z
                -- connect puzzle pieces
                for zStart = 1, j do
                    AddToSkip(ToSkip, relativeBlockX + i - 1, relativeBlockZ + zStart - 1, relativeBlockY)
                end
            end

            -- TODO: Y LEVEL
            -- local visualXCFrame = CFrame.new(module.GetBlockPositionFromCoords(x, z, relativeBlockX + endPositionX - 1, relativeBlockZ + endPositionZ - 1, relativeBlockY))
            -- visualX.CFrame = visualXCFrame
            -- for h = 1, CHUNK_SIZE do
            --     if i ~= 1 or j ~= 1 then
            --         if h > endPositionY then break end
            --     end
            --     local AdjacentSurfaceBlock = module.GetSurfaceBlockFromCoordinates(x, z, relativeBlockX + i - 1, relativeBlockZ + j - 1, relativeBlockY + h - 1)
            --     if not AdjacentSurfaceBlock then break end
            --     if AdjacentSurfaceBlock ~= id then break end
            --     if IsInToSkip(ToSkip, relativeBlockX + i - 1, relativeBlockZ + j - 1, relativeBlockY + h - 1) then break end
                
                
            --     if i == 1 and j == 1 then
            --         endPositionY += 1
            --     end
    
            --     AddToSkip(ToSkip, relativeBlockX + i - 1, relativeBlockZ + j - 1, relativeBlockY + h - 1)
            -- end
        end
    end

    module.PlaceGreedBlock(x, z, relativeBlockX, relativeBlockZ, relativeBlockY, endPositionX, endPositionZ, endPositionY, id)
    
    return ToSkip
end

--[[ Chunk Renderer ]]--

module.CreateChunk = function(x, z)
	module.LoadedChunks[x][z].ChunkBoundaries.Parent = workspace.CurrentCamera
	module.LoadedChunks[x][z].Container.Parent = nil
	module.LoadedChunks[x][z].Built = false
	
	if module.LoadedChunks[x][z].ChunkBoundaries:FindFirstChild("ChunkOutline") then
		local Outline = module.LoadedChunks[x][z].ChunkBoundaries.ChunkOutline
		Outline.Color3 = Color3.fromRGB(0, 255, 0)
		Outline.LineThickness = 0.3
	end
	
    local ToSkip = {}
    local amt_placed = 0
	for relativeBlockX, xList in module.LoadedChunks[x][z].SurfaceBlocks do
		for relativeBlockZ, zList in xList do
			for relativeBlockY, id in zList do
                local ShouldSkip = false
                local s, e = pcall(function()
                    local location = ToSkip[relativeBlockX][relativeBlockZ][relativeBlockY]
                    if location then
                        ShouldSkip = true
                    end
                end)
                if ShouldSkip then break end

                -- module.PlaceBlock(x, z, relativeBlockX, relativeBlockZ, relativeBlockY, id)

                -- Greedy Meshing
                ToSkip = module.GreedyBlockPlace(x, z, relativeBlockX, relativeBlockZ, relativeBlockY, id, ToSkip)
                amt_placed += 1


                -- TODO: TEXTURE FACE CULLING
				-- local infront, behind, right, left, top, under = module.CheckBlockSurroundings(x, z, relativeX, relativeZ, relativeY)
                -- local infront, behind, right, left, top, under = true, false, true, false, true, false
				
				-- if not (infront or behind or right or left or top or under) then -- no blocks adjacent
                --     -- local id = yList
				-- 	-- module.PlaceBlock(x, z, relativeBlockX, relativeBlockZ, relativeBlockY, id)
				-- elseif (infront and behind and right and left and top and under) then -- all blocks adjacent
				-- else
				-- 	-- module.PlaceBlock(x, z, relativeBlockX, relativeBlockZ, relativeBlockY, id)

                --     -- Greedy Meshing
                --     ToSkip = module.GreedyBlockPlace(x, z, relativeBlockX, relativeBlockZ, relativeBlockY, id, ToSkip)
                --     amt_placed += 1
				-- end
                
				module.wait(ChunkSettings.BUILD_DELAY)
			end
		end
	end
	
    if DebugHandler.Enabled then
        warn("Blocks placed:", amt_placed)
    end
	module.LoadedChunks[x][z].ChunkBoundaries.Parent = module.LoadedChunks[x][z].Container
	module.LoadedChunks[x][z].Container.Parent = Chunks

	if module.LoadedChunks[x][z].ChunkBoundaries then
		module.LoadedChunks[x][z].ChunkBoundaries.CanCollide = false
	end
	
	
	module.LoadedChunks[x][z].Built = true
	
	if module.LoadedChunks[x][z].ChunkBoundaries:FindFirstChild("ChunkOutline") then
		local Outline = module.LoadedChunks[x][z].ChunkBoundaries.ChunkOutline
		Outline.Color3 = Color3.fromRGB(255, 255, 255)
		Outline.LineThickness = 0.03
	end
end



return module