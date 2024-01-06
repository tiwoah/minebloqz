
--[[
    Block Structure:
    {
        Name = "",                      -- Name of the block
        Hardness = 0,                   -- Hardness of the block
        Tool = "",                      -- Tool required to break this block
        Tool_Material = "",             -- Material of the tool needed
        Tool_Material_Needed = false,   -- Whether a specific tool material is required
        Tool_Needed = false,            -- Whether a tool is needed to break this block
        Solid = false,                  -- Whether the block is solid (prevents movement through it)
        Transparent = false,            -- Whether the block is transparent
        Opaque = false,                 -- Whether the block is opaque (does not allow light to pass through)
    }
]]

return {
	grass_block = {
		Name = "Grass",
		Hardness = 0.6,
		Tool = "shovel",
		Tool_Material = "wood",
		Tool_Material_Needed = false,
		Tool_Needed = false,
		Solid = true,
		Transparent = false,
		Opaque = false,
	},
	dirt = {
		Name = "Dirt",
		Hardness = 0.5,
		Tool = "shovel",
		Tool_Material = "wood",
		Tool_Material_Needed = false,
		Tool_Needed = false,
		Solid = true,
		Transparent = false,
		Opaque = false,
	},
}