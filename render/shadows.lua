-- Put functions in this file to use them in several other scripts.
-- To get access to the functions, you need to put:
-- require "my_directory.my_file"
-- in any script using the functions.

local top = vmath.vector3(0, 1, 0)
local v0 = vmath.vector4(0, 0, 0, 0) -- zero vector4

local BUFFER_RESOLUTION = 2048 -- Size of shadow map. Select value from: 1024/2048/4096. More is better quality.

-- Projection resolution of shadow map to the game world. Smaller size is better shadow quality,
-- but shadows will cast only around the screen center (or a point that camera looks at).
-- This value also depends on camera zoom. Feel free to adjust it.
local PROJECTION_RESOLUTION = 400

