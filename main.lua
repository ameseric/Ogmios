--[[

	Author: Eric Ames
	Last Updated: September 23rd, 2014
	Purpose: main lua file for Ogmios game project.

	General rule of thumb: all dimensions are in pixels or tiles.
	Tiles are 32 x 32 pixels, stored in the TS variable.
	display is a table that holds the dimensions of the PORTION of the TOTAL WORLD currently being shown in TILES
	pc is player character, which is treated as an npc by the manager.
	window is the actual size of the game window, in pixels. It's only used to build a scale factor, so the game will
		run the same regardless of the player's choice of window size.

	at some point, need to seperate Map, to keep main.lua clean.

--]]

--============ Globals =================

local window_height, window_width			--dimensions of the window in pixels as chosen by player
local TS = 32
local chosen_world_height = 360; local chosen_world_width = 640
local build = false
local disp_height = 11; local disp_width = 19;
local img_dir = "images/"
local start_coord = {x=10, y=6}

--======================================

function love.load()							--initial values and files to load for gameplay
	window_height = love.window.getHeight();			window_width = love.window.getWidth();	--window size

	load_libraries()
	love.graphics.setNewFont( 25 )

	scale = window_height / ( display.height * TS )

	math.randomseed( os.time() )				--set random seed value for map generation

	load_images()

	tile_names = tile.all_names
	map.get_type( tile_names )		--Grab generation probabilities for map tiles
	map.load_map_tiles( map_tileset:getWidth(), map_tileset:getHeight(), TS, tile_names )

	map:create_world( chosen_world_width, chosen_world_height )
	map:build_tileset_batch( display, TS )
	manager:load_npcs( "std_npc_load", pc )



end


function love.draw()
	display:draw( TS, map.tileset_batch, scale )	--first draw the ground...
	manager:draw( TS, scale, display, pc, map )		--then the characters, starting with the furthest back...
	--display:draw_high_layer()			--add later, for passable tiles that are "sticking up", must be drawn over characters; e.g. walls, fog, etc.
	display:draw_text()								--and finally draw the message window

	debug()

end


function love.keypressed(key, isrepeat)
	if key == "e" then interact() end	--move interact as player.lua function
	if key == 'f' then pc:attacking( true ) end
	if key == 'v' then pc:add_to_party( map, display, manager ) end
end


function love.update( dt )
	build, move = manager:update( dt, TS, map, display )--pc:move( map, display )

	if move or build then display:show_text() end	--Clear text box if player moves

	if build then
		map:build_tileset_batch( display, TS )
		build = false
	end

	display:update_pixel( dt, TS, pc )

end

function interact()						--move as player.lua function
	if map:get_ocpied( pc ) then
		display:show_text( map:get_tile_text( pc ) )
	end
end









--========== Utility Functions ================

function load_libraries()
	map = require( "map" );				tile = require( "tile" )
	aal = require( "AnAL" );			template = require( "area_template" )
	district = require( "district" );	player = require( "player" )
	npc = require( "npc" );				manager = require( "manager" )
	display = require( "disp" ):new( disp_height, disp_width, window_height, window_width )
end

function load_images()
	pc_image = love.graphics.newImage( img_dir.."fox.png" )
	pc_image:setFilter( "nearest" )
	pc_icon = love.graphics.newQuad( 0, 0, TS, TS, pc_image:getWidth(), pc_image:getHeight() )
	local offset = { x = ((display.width/2)+0.5), y = ((display.height/2)+0.5) }
	pc = player:new( pc_icon, pc_image, offset, TS )

	map_tileset = love.graphics.newImage( img_dir.."map_tile_placeholders2.png" )
	map_tileset:setFilter( "nearest" )
	map.tileset_batch = love.graphics.newSpriteBatch( map_tileset, (display.height + 2) * (display.width + 2) )

end

function get_tile_at_ori( char )
	if char.ori == 'n' then
		return 0, -1
	elseif char.ori == 's' then
		return 0, 1
	elseif char.ori == 'e' then
		return 1, 0
	elseif char.ori == 'w' then
		return -1, 0
	end
end


function debug()
	love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
  	love.graphics.print("Pos: "..display.world_x.." "..display.world_y, 10, 40)
  	love.graphics.print("Self Pos: "..pc.from_center_x.." "..pc.from_center_y, 10, 60)
  	love.graphics.print("Self World: "..pc.world_x.." "..pc.world_y, 10, 80)
end