------------------------------------------
--  CHECK CONV AND DISABLE DEFAULT HUD  --
------------------------------------------

-- Check Convars
local drawHUD = tobool( GetConVarNumber( "cl_drawhud" ) )
function cl_bHUD.setDrawHUD( ply, cmd, args )
	drawHUD = tobool( GetConVarNumber( "cl_drawhud" ) )
end
concommand.Add( "cl_drawhud", cl_bHUD.setDrawHUD )

-- Disable Default-HUD
function cl_bHUD.drawHUD( HUDName )
	if HUDName == "CHudHealth" or HUDName == "CHudBattery" or HUDName == "CHudAmmo" or HUDName == "CHudSecondaryAmmo" then return false end
end
hook.Add( "HUDShouldDraw", "bhud_drawHUD", cl_bHUD.drawHUD )



----------------------
--  SQL - SETTINGS  --
----------------------

cl_bHUD_sqldata = {}

sql.Query( "CREATE TABLE IF NOT EXISTS bhud_settings( 'setting' TEXT, value INTEGER );" )

local check_sql = { "drawHUD", "drawPlayerHUD", "drawTimeHUD", "drawMapHUD" }
table.foreach( check_sql, function( index, setting )

	if !sql.Query( "SELECT value FROM bhud_settings WHERE setting = '" .. setting .. "'" ) then
		sql.Query( "INSERT INTO bhud_settings ( setting, value ) VALUES( '" .. setting .. "', 1 )" )
		cl_bHUD_sqldata[setting] = tobool( sql.QueryValue( "SELECT value FROM bhud_settings WHERE setting = '" .. setting .. "'" ) )
	else
		cl_bHUD_sqldata[setting] = tobool( sql.QueryValue( "SELECT value FROM bhud_settings WHERE setting = '" .. setting .. "'" ) )
	end

end )

function cl_bHUD_SettingsPanel()

	local pw = ScrW() / 4
	local ph = ScrH() / 4
	local px = ScrW() / 2 - ( pw / 2 )
	local py = ScrH() / 2 - ( ph / 2 )

	local frm = cl_bHUD.addfrm( px, py, pw, ph )
	cl_bHUD.addlbl( frm, "Enable/Disable Features:", 10, 35 )

	local ch = 61
	table.foreach( cl_bHUD_sqldata, function( setting, value )

		cl_bHUD.addchk( frm, setting, 10, ch, setting )
		ch = ch + 20

	end )

	cl_bHUD.addlbl( frm, "Minimap Settings:", 10, ch + 7 )
	cl_bHUD.addsld( frm, "Minimap-Radius", 10, ch + 20, 300, 50, 150, bhud_map_radius, "radius" )

end

-- CHANGE SQL SETTINGS
function cl_bHUD.chat( ply, text, team, dead )

	-- Open the Panel if requested
	if text == "!bhud_settings" then
		cl_bHUD_SettingsPanel()
		return true
	end

end
hook.Add( "OnPlayerChat", "cl_bHUD_OnPlayerChat", cl_bHUD.chat )



-----------------------
--  PLAYER INFO HUD  --
-----------------------

bhud_hp_bar = 0
bhud_ar_bar = 0

function cl_bHUD.showHUD()

	-- Don't draw the HUD if the cvar cl_drawhud is set to 0
	if !drawHUD then return end
	-- If BHUD was deactivated with the sql-settings
	if cl_bHUD_sqldata["drawHUD"] == false then return end
	-- If BHUD was deactivated with the sql-settings
	if cl_bHUD_sqldata["drawPlayerHUD"] == false then return end

	local ply = LocalPlayer()
	if !ply:Alive() or !ply:IsValid() or !ply:GetActiveWeapon():IsValid() then return end
	if ply:GetActiveWeapon():GetPrintName() == "Camera" then return end

	local player = {

		name = ply:Nick(),
		team = team.GetName( ply:Team() ),
		weapon = ply:GetActiveWeapon(),
		health = ply:Health(),
		armor = ply:Armor(),

		wep = ply:GetActiveWeapon(),
		wep_name = ply:GetActiveWeapon():GetPrintName(),
		wep_ammo_1 = ply:GetActiveWeapon():Clip1(),
		wep_ammo_2 = ply:GetActiveWeapon():Clip2(),
		wep_ammo_1_max = ply:GetAmmoCount( ply:GetActiveWeapon():GetPrimaryAmmoType() ),
		wep_ammo_2_max = ply:GetAmmoCount( ply:GetActiveWeapon():GetSecondaryAmmoType() )

	}
	
	-- Check the player's Team
	if player["team"] != "" and player["team"] != "Unassigned" then
		player["name"] = "[" .. player["team"] .. "] " .. ply:Nick()
	end

	-- PLAYER PANEL SIZES
	local width = 195
	local height
	if player["armor"] > 0 then height = 90 else height = 65 end
	local left = 20
	local top = ScrH() - height - 20

	local wep_width = 200
	local wep_height
	if player["wep_ammo_2_max"] != 0 then wep_height = 90 else wep_height = 65 end
	local wep_top = ScrH() - wep_height - 20
	local wep_left = left + width + 10

	-- BACKGROUND
	draw.RoundedBox( 4, left, top, width, height, Color( 50, 50, 50, 230 ) )

	-- PLAYER NAME
	surface.SetFont( "bhud_roboto_18" )
	if surface.GetTextSize( player["name"] ) > ( width - 38 - 10 ) then
		while surface.GetTextSize( player["name"] ) > ( width - 38 - 15 ) do
			player["name"] = string.Left( player["name"], string.len( player["name"] ) -1 )
		end
		player["name"] = player["name"] .. "..."
	end

	surface.SetMaterial( Material( "materials/bhud/player.png" ) )
	surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
	surface.DrawTexturedRect( left + 10, top + 12, 16, 16 )

	draw.SimpleText( player["name"], "bhud_roboto_20", left + 38, top + 10, team.GetColor( ply:Team() ), 0, 0 )

	-- PLAYER HEALTH
	surface.SetFont( "bhud_roboto_18" )

	if bhud_hp_bar < player["health"] then
		bhud_hp_bar = bhud_hp_bar + 0.5
	elseif bhud_hp_bar > player["health"] then
		bhud_hp_bar = bhud_hp_bar - 0.5
	end

	surface.SetMaterial( Material( "materials/bhud/heart.png" ) )
	surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
	surface.DrawTexturedRect( left + 10, top + 37, 16, 16 )

	draw.RoundedBox( 1, left + 35, top + 35, bhud_hp_bar * 1.5, 20, Color( 255, 50, 0, 230 ) )

	if 10 + surface.GetTextSize( tostring( player["health"] ) ) < bhud_hp_bar * 1.5 then
		draw.SimpleText( tostring( math.Round( bhud_hp_bar, 0 ) ), "bhud_roboto_18", left + 30 + ( bhud_hp_bar * 1.5 ) - surface.GetTextSize( tostring( player["health"] ) ), top + 37, Color( 255, 255, 255 ), 0 , 0 )
	else
		draw.SimpleText( tostring( math.Round( bhud_hp_bar, 0 ) ), "bhud_roboto_18", left + 40 + ( bhud_hp_bar * 1.5 ), top + 37, Color( 255, 255, 255 ), 0 , 0 )
	end

	-- PLAYER ARMOR
	if player["armor"] > 0 then

		if bhud_ar_bar < player["armor"] then
			bhud_ar_bar = bhud_ar_bar + 0.5
		elseif bhud_ar_bar > player["armor"] then
			bhud_ar_bar = bhud_ar_bar - 0.5
		end

		surface.SetMaterial( Material( "materials/bhud/shield.png" ) )
		surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
		surface.DrawTexturedRect( left + 10, top + 62, 16, 16 )

		draw.RoundedBox( 1, left + 35, top + 60, bhud_ar_bar * 1.5, 20, Color( 0, 161, 222, 230 ) )

		if 10 + surface.GetTextSize( tostring( player["armor"] ) ) < bhud_ar_bar * 1.5 then
			draw.SimpleText( tostring( math.Round( bhud_ar_bar, 0 ) ), "bhud_roboto_18", left + 30 + ( bhud_ar_bar * 1.5 ) - surface.GetTextSize( tostring( player["armor"] ) ), top + 62, Color( 255, 255, 255 ), 0 , 0 )
		else
			draw.SimpleText( tostring( math.Round( bhud_ar_bar, 0 ) ), "bhud_roboto_18", left + 40 + ( bhud_ar_bar * 1.5 ), top + 62, Color( 255, 255, 255 ), 0 , 0 )
		end

	end



	-- WEAPONS

	if player["wep_ammo_1"] == -1 and player["wep_ammo_1_max"] <= 0 then return end
	if player["wep_ammo_1"] == -1 then player["wep_ammo_1"] = "1" end

	-- BACKGROUND
	draw.RoundedBox( 4, wep_left, wep_top, wep_width, wep_height, Color( 50, 50, 50, 230 ) )

	-- WEAPON NAME
	surface.SetMaterial( Material( "materials/bhud/pistol.png" ) )
	surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
	surface.DrawTexturedRect( wep_left + 10, wep_top + 12, 16, 16 )

	draw.SimpleText( player["wep_name"], "bhud_roboto_20", wep_left + 38, wep_top + 10, Color( 255, 255, 255 ), 0 , 0 )

	-- AMMO 1
	surface.SetMaterial( Material( "materials/bhud/ammo_1.png" ) )
	surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
	surface.DrawTexturedRect( wep_left + 10, wep_top + 37, 16, 16 )

	surface.SetFont( "bhud_roboto_20" )

	draw.SimpleText( player["wep_ammo_1"], "bhud_roboto_20", wep_left + 38, wep_top + 35, Color( 255, 255, 255 ), 0 , 0 )
	draw.SimpleText( "/ " .. player["wep_ammo_1_max"], "bhud_roboto_20", wep_left + 38 + surface.GetTextSize( player["wep_ammo_1"] ) + 6, wep_top + 35, Color( 200, 200, 200 ), 0 , 0 )

	if wep_height != 90 then return end

	-- AMMO 2
	surface.SetMaterial( Material( "materials/bhud/ammo_2.png" ) )
	surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
	surface.DrawTexturedRect( wep_left + 10, wep_top + 62, 16, 16 )

	draw.SimpleText( player["wep_ammo_2_max"], "bhud_roboto_20", wep_left + 38, wep_top + 60, Color( 255, 255, 255 ), 0 , 0 )

end
hook.Add( "HUDPaint", "bhud_showHUD", cl_bHUD.showHUD )



----------------
--  TIME HUD  --
----------------

local bigtimemenu = false
local jointime = os.time()
local td = {
	time = 0,
	addon = ""
}

function cl_bHUD.showTimeHUD()

	-- Don't draw the HUD if the cvar cl_drawhud is set to 0
	if !drawHUD then return end
	-- If BHUD was deactivated by sql-settings
	if cl_bHUD_sqldata["drawHUD"] == false then return end
	-- If BHUD-Time was deactivated by sql-settings
	if cl_bHUD_sqldata["drawTimeHUD"] == false then return end

	local width

	if bigtimemenu then
		width = 150
	else
		surface.SetFont( "bhud_roboto_15" )
		width = 11 + surface.GetTextSize( os.date( "%H:%M" ) )
	end

	local height = 67
	local left = ScrW() - width - 15
	local top

	if bigtimemenu then

		top = 45

		draw.RoundedBoxEx( 4, left, top, width, 25, Color( 50, 50, 50, 230 ), true, true, false, false )
		draw.SimpleText( "Time:", "bhud_roboto_15", left + 5, top + 5, Color( 255, 255, 255 ), 0 , 0 )
		draw.SimpleText( os.date( "%H:%M" ), "bhud_roboto_15", left + width - 6, top + 5, Color( 255, 255, 255 ), TEXT_ALIGN_RIGHT )

		draw.RoundedBoxEx( 4, left, top + 25, width, height, Color( 100, 100, 100, 230 ), false, false, true, true )

		-- Session
		surface.SetFont( "bhud_roboto_16" )
		draw.SimpleText( "Session:", "bhud_roboto_16", left + 6, top + 30, Color( 255, 255, 255 ), 0, 0 )
		draw.SimpleText( string.NiceTime( os.time() - jointime ), "bhud_roboto_16", left + 11 + surface.GetTextSize( "Session:" ), top + 30, Color( 255, 255, 255 ), 0, 0 )

		-- Total
		draw.SimpleText( "Total:", "bhud_roboto_16", left + 6, top + 50, Color( 255, 255, 255 ), 0, 0 )
		draw.SimpleText( string.NiceTime( td.time + ( os.time() - jointime ) ), "bhud_roboto_16", left + 11 + surface.GetTextSize( "Total:" ), top + 50, Color( 255, 255, 255 ), 0, 0 )
		
		-- Addon
		draw.SimpleText( "Addon:", "bhud_roboto_16", left + 6, top + 70, Color( 255, 255, 255 ), 0, 0 )
		draw.SimpleText( td.addon, "bhud_roboto_16", left + 11 + surface.GetTextSize( "Addon:" ), top + 70, Color( 255, 255, 255 ), 0, 0 )

	else

		top = 15

		draw.RoundedBoxEx( 4, left, top, width, 25, Color( 50, 50, 50, 230 ), true, true, true, true )
		draw.SimpleText( os.date( "%H:%M" ), "bhud_roboto_15", left + width - 6, top + 5, Color( 255, 255, 255 ), TEXT_ALIGN_RIGHT )

	end

end
hook.Add( "HUDPaint", "bhud_showTimeHUD", cl_bHUD.showTimeHUD )

local function getTimes()

	if exsto then
		time = LocalPlayer():GetNWInt( "Time_Fixed" )
		td.addon = "Exsto"
	elseif sql.TableExists( "utime" ) then
		time = LocalPlayer():GetNWInt( "TotalUTime" )
		td.addon = "UTime"
	elseif evolve then
		time = LocalPlayer():GetNWInt( "EV_PlayTime" )
		td.addon = "Evolve"
	else
		time = 0
		td.addon = "Not found ..."
	end

end

hook.Add( "OnContextMenuOpen", "bhud_openedContextMenu", function()

	bigtimemenu = true
	getTimes()

end )

hook.Add( "OnContextMenuClose", "bhud_closedContextMenu", function()

	bigtimemenu = false
	getTimes()

end )



-------------------
--  MINIMAP HUD  --
-------------------

bhud_map_radius = 100
local map_qual = 60
local map_border = 5
local map_tolerance = 200

bhud_map_left = ScrW() - bhud_map_radius - 10 - map_border
bhud_map_top = ScrH() - bhud_map_radius - 10 - map_border

function cl_bHUD.showMinimapHUD()

	-- Don't draw the HUD if the cvar cl_drawhud is set to 0
	if !drawHUD then return end
	-- If BHUD was deactivated by sql-settings
	if cl_bHUD_sqldata["drawHUD"] == false then return end
	-- If BHUD-Time was deactivated by sql-settings
	if cl_bHUD_sqldata["drawMapHUD"] == false then return end

	local circle = {}
	local bcircle = {}
	
	local deg = 0
	local sin, cos, rad = math.sin, math.cos, math.rad

	for i = 1, map_qual do
		deg = rad( i * 360 ) / map_qual
		circle[i] = {
			x = bhud_map_left + cos( deg ) * bhud_map_radius,
			y = bhud_map_top + sin( deg ) * bhud_map_radius
		}
		bcircle[i] = {
			x = bhud_map_left + cos( deg ) * ( bhud_map_radius + map_border ),
			y = bhud_map_top + sin( deg ) * ( bhud_map_radius + map_border )
		}
	end

	surface.SetDrawColor( Color( 255, 150, 0 ) )
	draw.NoTexture()
	surface.DrawPoly( bcircle )

	surface.SetDrawColor( Color( 50, 50, 50 ) )
	draw.NoTexture()
	surface.DrawPoly( circle )

	surface.SetMaterial( Material( "materials/bhud/cursor.png" ) )
	surface.SetDrawColor( team.GetColor( LocalPlayer():Team() ) )
	surface.DrawTexturedRect( bhud_map_left - 8, bhud_map_top - 8, 16, 16 )

	table.foreach( player.GetAll(), function( id, pl )

		if pl == LocalPlayer() then return end

		local e = LocalPlayer():EyeAngles().y
		local a1 = LocalPlayer():GetPos() - pl:GetPos()
		local a2 = a1:Angle().y
		local lx, ly, px, py = LocalPlayer():GetPos().x, LocalPlayer():GetPos().y, pl:GetPos().x, pl:GetPos().y
		local dist = Vector( lx, ly, 0 ):Distance( Vector( px, py, 0 ) )
		local ang = math.AngleDifference( e - 180, a2 )

		local d = rad( ang + 180 )
		local posx = -sin( d ) * ( math.Clamp( dist, 0, 1000 ) / 10 )
		local posy = cos( d ) * ( math.Clamp( dist, 0, 1000 ) / 10 )

		if LocalPlayer():GetPos().z + map_tolerance < pl:GetPos().z then
			surface.SetMaterial( Material( "materials/bhud/cursor_up.png" ) )
		elseif LocalPlayer():GetPos().z - map_tolerance > pl:GetPos().z then
			surface.SetMaterial( Material( "materials/bhud/cursor_down.png" ) )
		else
			surface.SetMaterial( Material( "materials/bhud/cursor.png" ) )
		end

		surface.SetDrawColor( team.GetColor( pl:Team() ) )
		surface.DrawTexturedRectRotated( bhud_map_left + posx, bhud_map_top + posy, 16, 16, -math.AngleDifference( e, pl:EyeAngles().y ) )

		surface.SetFont( "bhud_roboto_14" )
		surface.SetTextColor( 255, 255, 255, 255 )
		surface.SetTextPos( bhud_map_left + posx - 8, bhud_map_top + posy + 10 )
		surface.DrawText( pl:Nick() )
		surface.SetTextPos( bhud_map_left + posx - 8, bhud_map_top + posy + 20 )
		surface.DrawText( math.floor( LocalPlayer():GetPos():Distance( pl:GetPos() ) / 50 ) .. " m" )

	end )

end
hook.Add( "HUDPaint", "bhud_showMinimapHUD", cl_bHUD.showMinimapHUD )
