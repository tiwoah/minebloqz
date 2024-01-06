local module = {}


module.BLOCK_SIZE = 3
module.CHUNK_SIZE = 16
module.MAX_CHUNK = 100
module.MAX_HEIGHT = 32 -- ** must be equal for chunk boundaries being properly placed
module.MIN_HEIGHT = -32

-- Modifiable User Settings
module.RENDER_DISTANCE = 4
module.LOAD_DELAY = 1
module.BUILD_DELAY = 1
module.DESTROY_DELAY = 1


module.UpdateDelays = function()
    local RENDER_DISTANCE = module.Settings.RENDER_DISTANCE
    
    module.LOAD_DELAY = RENDER_DISTANCE == 0 and 0 or RENDER_DISTANCE * 2
    module.BUILD_DELAY = RENDER_DISTANCE == 0 and 0 or RENDER_DISTANCE * 8
end

return module