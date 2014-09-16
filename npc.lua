--[[
	Author: Eric Ames
	Last Updated: August 3rd
	Purpose: NPC object.
]]

default_anims = { 
   	down_static={	delay=0.6, x=0, y=0 }, down_move={	delay=0.2, x=2, y=0}
  	,left_static={	delay=0.6, x=0, y=1}, left_move={	delay=0.2, x=2, y=1}
	,up_static={		delay=0.6, x=0, y=2}, up_move={		delay=0.2, x=2, y=2}
 	,right_static={	delay=0.6, x=0, y=3}, right_move={	delay=0.2, x=2, y=3}

}

npc = {}
npc.name = "None"
npc.animations = {}

npc.mood = 'agressive' --passive
npc.faction = 'neutral'
npc.in_combat = false

npc.world_x = 0; npc.world_y = 0
npc.pixel_x = 0; npc.pixel_y = 0

npc.roams = false
npc.current_anim = 'down_static'
npc.ori = 's'

npc.dt = 1 --(math.random() * 4) + 1
npc.counter = 0
npc.move_slice_x = 0
npc.move_slice_y = 0

npc.in_party = false

function npc:new( param_table, TS )
	new_npc = param_table
	setmetatable( new_npc, self )
	self.__index = self

	new_npc.pixel_x = new_npc.world_x * TS
	new_npc.pixel_y = new_npc.world_y * TS

	new_npc.animations = {}

	for name,anim in pairs( default_anims ) do
		setup_animations( name, new_npc, TS )
	end

	map:set_tile_ocpied( new_npc )

	return new_npc
end


function npc:draw( TS, scale, display )
	self.animations[ self.current_anim ]:draw( (self.pixel_x - display.pixel_x)*scale,
							 (self.pixel_y - display.pixel_y - (TS/2))*scale, 0, scale, scale )
end

function npc:roam( map, time, dt )
	--need to update world tile location, clear last tile, mark new tile
	--need to set world_x and world_y

	chance = math.random() * 100
	self.counter = self.counter + dt

	if chance < 92 then 
		return
	elseif self.counter > self.dt then
		if chance < 94 then
			self.ori = 'n'
		elseif chance < 96 then
			self.ori = 's'
		elseif chance < 98 then
			self.ori = 'w'
		elseif chance < 100 then
			self.ori = 'e'
		end
		self:move( map )

		self.counter = 0

	end

end


function npc:move( map )
	if map:get_passable( self ) and map:in_bounds( self ) and not self:is_moving() then 
		map:set_tile_ocpied( self, true )

		x,y = get_tile_at_ori( self )
		self.world_y = self.world_y + y
		self.world_x = self.world_x + x

		self.move_slice_x = self.world_x  - self.pixel_x/32
		self.move_slice_y = self.world_y  - self.pixel_y/32		

		map:set_tile_ocpied( self )
	end
end


function npc:update_pixel( dt, TS )

	if self:is_moving() then
		self.pixel_x = self.pixel_x + self.move_slice_x
		self.pixel_y = self.pixel_y + self.move_slice_y
	end

	self:update_current_animation()

	self.animations[ self.current_anim ]:update( dt )

end

function npc:enter_player_party()
	self.roams = false
	self.in_party = true
end

function npc:follow_player( pc, map )
	local dx = pc.world_x - self.world_x; local dy = pc.world_y - self.world_y
	local abs_x = math.abs( dx ); local abs_y = math.abs( dy )
	local moving = false

	print( dx, dy )

	if abs_x >= 3 and abs_x > abs_y then
		if dx > 0 then self.ori = 'e'
		elseif dx < 0 then self.ori = 'w' end

		self:move( map )

	elseif abs_y >= 3 and not self:is_moving() then
		if dy > 0 then self.ori = 's'
		elseif dy < 0 then self.ori = 'n' end

		self:move( map )
	end

end



--======================== HELPERS ==========================
	
function setup_animations( name, npc, TS)
	npc.animations[ name ] = newAnimation( npc.image, TS, TS, default_anims[ name ].delay, 2, default_anims[ name ].x, default_anims[ name ].y )
	npc.animations[ name ]:setMode( "loop" )
end

function npc:is_moving()
	return math.abs( self.pixel_x - self.world_x*TS) > 1 or math.abs(self.pixel_y - self.world_y*TS) > 1
end

function npc:update_current_animation()
	if self.ori == 's' then
		new_anim = { 'down_move', 'down_static' }

	elseif self.ori == 'n' then
		new_anim = { 'up_move' , 'up_static' }

	elseif self.ori == 'w' then
		new_anim = { 'left_move' , 'left_static' }

	elseif self.ori == 'e' then
		new_anim = { 'right_move' , 'right_static' }
	end

	if self:is_moving() then self.current_anim = new_anim[ 1 ]
		else self.current_anim = new_anim[ 2 ] end

end
	


function npc:is_friendly( person ) return self.faction == person.faction end
function npc:is_neutral( person ) return self.faction == 'neutral' end
function npc:is_foe( person ) return ( not self:is_friendly( person ) and not self:is_neutral( person ) ) end
function npc:is_injured() return ( self.stats.hp < self.stats.lung*self.stats.blood ) end
function npc:is_critical() return ( self.stats.hp < (self.stats.lung*self.stats.str)/4 ) end
function npc:get_speech() return self.speech end	


 return npc