-- Cheat Menu -  Cheat menu for Grand Theft Auto SanAndreas
-- Copyright (C) 2019-2020 Grinch_

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

script_name('Cheat Menu')
script_author("Grinch_")
script_description("Cheat Menu for Grand Theft Auto San Andreas")
script_url("https://forum.mixmods.com.br/f5-scripts-codigos/t1777-moon-cheat-menu")
script_dependencies("ffi","lfs","memory","mimgui","MoonAdditions")
script_properties('work-in-pause')
script_version("2.1-beta")
script_version_number(2020090203) -- YYYYMMDDNN

print(string.format("Loading v%s (%d)",script.this.version,script.this.version_num)) -- For debugging purposes

resX, resY = getScreenResolution()

tcheatmenu =
{   
    dir                    = string.format( "%s%s",getWorkingDirectory(),"/lib/cheat-menu/"),
    temp_data              = {
        draw_entries_func   = {},
    },
    window                 = 
    {
        fail_loading_json  = false,
        missing_components = false,
    }
}

--------------------------------------------------
-- Libraries
casts         = require 'cheat-menu.libraries.casts'
copas         = require 'copas'
ffi           = require 'ffi'
glob          = require 'game.globals'
http          = require 'copas.http'
imgui         = require 'mimgui'
lfs           = require 'lfs'
mad           = require 'MoonAdditions'
memory        = require 'cheat-menu.libraries.memory'
os            = require 'os'
vkeys         = require 'vkeys'
ziplib        = ffi.load(string.format( "%s/lib/ziplib.dll",getWorkingDirectory()))

--------------------------------------------------
-- Menu modules
fcommon       = require 'cheat-menu.modules.common'
fconfig       = require 'cheat-menu.modules.config'
fconst        = require 'cheat-menu.modules.const'

fanimation    = require 'cheat-menu.modules.animation'
fgame         = require 'cheat-menu.modules.game'
fmemory       = require 'cheat-menu.modules.memory'
fmenu         = require 'cheat-menu.modules.menu'
fmission      = require 'cheat-menu.modules.mission'
fped          = require 'cheat-menu.modules.ped'
fplayer       = require 'cheat-menu.modules.player'
fstat         = require 'cheat-menu.modules.stat'
fstyle        = require 'cheat-menu.modules.style'
fteleport     = require 'cheat-menu.modules.teleport'
fvehicle      = require 'cheat-menu.modules.vehicle'
fvisual       = require 'cheat-menu.modules.visual'
fweapon       = require 'cheat-menu.modules.weapon'

--------------------------------------------------

ffi.cdef[[
    int zip_extract(const char *zipname, const char *dir,int *func, void *arg);
]]

tcheatmenu       =
{   
    dir          = tcheatmenu.dir,
    current_menu = fconfig.Get('tcheatmenu.current_menu',0),
    hot_keys     =
    {
        asc_key               = fconfig.Get('tcheatmenu.hot_keys.asc',{vkeys.VK_RETURN,vkeys.VK_RETURN}),
        camera_mode           = fconfig.Get('tcheatmenu.hot_keys.camera_mode',{vkeys.VK_LMENU,vkeys.VK_C}),
        camera_mode_forward   = fconfig.Get('tcheatmenu.hot_keys.camera_mode_forward',{vkeys.VK_I,vkeys.VK_I}),
        camera_mode_backward  = fconfig.Get('tcheatmenu.hot_keys.camera_mode_backward',{vkeys.VK_K,vkeys.VK_K}),
        camera_mode_left      = fconfig.Get('tcheatmenu.hot_keys.camera_mode_left',{vkeys.VK_J,vkeys.VK_J}),
        camera_mode_right     = fconfig.Get('tcheatmenu.hot_keys.camera_mode_right',{vkeys.VK_L,vkeys.VK_L}),
        camera_mode_slow      = fconfig.Get('tcheatmenu.hot_keys.camera_mode_slow',{vkeys.VK_RCONTROL,vkeys.VK_RCONTROL}),
        camera_mode_fast      = fconfig.Get('tcheatmenu.hot_keys.camera_mode_fast',{vkeys.VK_RSHIFT,vkeys.VK_RSHIFT}),
        camera_mode_up        = fconfig.Get('tcheatmenu.hot_keys.camera_mode_up',{vkeys.VK_O,vkeys.VK_O}),
        camera_mode_down      = fconfig.Get('tcheatmenu.hot_keys.camera_mode_down',{vkeys.VK_P,vkeys.VK_P}),
        command_window        = fconfig.Get('tcheatmenu.hot_keys.command_window',{vkeys.VK_LMENU,vkeys.VK_M}),
        currently_active      = nil,
        mc_paste              = fconfig.Get('tcheatmenu.hot_keys.mc_paste',{vkeys.VK_LCONTROL,vkeys.VK_V}),
        menu_open             = fconfig.Get('tcheatmenu.hot_keys.menu_open',{vkeys.VK_LCONTROL,vkeys.VK_M}),
        quick_screenshot      = fconfig.Get('tcheatmenu.hot_keys.quick_screenshot',{vkeys.VK_LCONTROL,vkeys.VK_S}),
        quick_teleport        = fconfig.Get('tcheatmenu.hot_keys.quick_teleport',{vkeys.VK_X,vkeys.VK_Y}),
        script_manager_temp   = {vkeys.VK_LCONTROL,vkeys.VK_1}
    },
    read_key_press = false,
    temp_data    = tcheatmenu.temp_data,
    tab_data     = fconfig.Get('tcheatmenu.tab_data',{}),
    thread_locks = {},
    window       =
    {
        coord    = 
        {
            X    = fconfig.Get('tcheatmenu.window.coord.X',50),
            Y    = fconfig.Get('tcheatmenu.window.coord.Y',50),
        },
        fail_loading_json = tcheatmenu.window.fail_loading_json,
        missing_components = tcheatmenu.window.missing_components,
        panel_func = nil,
        restart_required = false,
        show     = imgui.new.bool(false),
        size     =
        {
            X    = fconfig.Get('tcheatmenu.window.size.X',resX/4),
            Y    = fconfig.Get('tcheatmenu.window.size.Y',resY/1.2),
        },
        title    = string.format("%s v%s",script.this.name,script.this.version),
    },
}

imgui.OnInitialize(function() -- Called once

    local io = imgui.GetIO()
    -- Load fonts
    if fmenu.tmenu.font.size[0] < 12 then fmenu.tmenu.font.size[0] = 12 end
    local mask = tcheatmenu.dir .. "fonts//*.ttf"

    local handle, name = findFirstFile(mask)
    while handle and name do
        fmenu.tmenu.font.list[name] = io.Fonts:AddFontFromFileTTF(string.format( "%sfonts//%s",tcheatmenu.dir,name), fmenu.tmenu.font.size[0])
        name = findNextFile(handle)
    end

    io.FontDefault = fmenu.tmenu.font.list[fmenu.tmenu.font.selected]
    io.IniFilename = nil
    io.WantSaveIniSettings = false

    if not doesFileExist(tcheatmenu.dir .. "json//styles.json") then 
        fstyle.saveStyles(imgui.GetStyle(), "Default") 
    end
    
    fstyle.tstyle.status = fstyle.loadStyles() 

    if fstyle.tstyle.status then
        fstyle.tstyle.list  = fstyle.getStyles()
        fstyle.tstyle.array = imgui.new['const char*'][#fstyle.tstyle.list](fstyle.tstyle.list)

        for i=1,#fstyle.tstyle.list,1 do
            if fstyle.tstyle.list[i] == fstyle.tstyle.selected_name then
                fstyle.tstyle.selected[0] = i - 1
            end
        end

        fstyle.applyStyle(imgui.GetStyle(), fstyle.tstyle.list[fstyle.tstyle.selected[0] + 1])
    else 
        print("Can't load styles")
    end

    -- Indexing images
    lua_thread.create(
    function() 
        fcommon.IndexFiles(fvehicle.tvehicle.path,fvehicle.tvehicle.images,fconst.VEHICLE.IMAGE_EXT)
        fcommon.IndexFiles(fweapon.tweapon.path,fweapon.tweapon.images,fconst.WEAPON.IMAGE_EXT)
        fcommon.IndexFiles(fped.tped.path,fped.tped.images,fconst.PED.IMAGE_EXT)
        fcommon.IndexFiles(fplayer.tplayer.clothes.path,fplayer.tplayer.clothes.images,fconst.CLOTH.IMAGE_EXT)
        fcommon.IndexFiles(fvehicle.tvehicle.components.path,fvehicle.tvehicle.components.images,fconst.COMPONENT.IMAGE_EXT)
        fcommon.IndexFiles(fvehicle.tvehicle.paintjobs.path,fvehicle.tvehicle.paintjobs.images,fconst.PAINTJOB.IMAGE_EXT)
    end)
end)

imgui.OnFrame(
function() -- condition
    return tcheatmenu.window.show[0] and not isGamePaused() 
end,
function(self) -- render frame
    
    self.LockPlayer = fmenu.tmenu.lock_player[0] 
    imgui.SetNextWindowSize(imgui.ImVec2(tcheatmenu.window.size.X,tcheatmenu.window.size.Y),imgui.Cond.Once)
    imgui.SetNextWindowPos(imgui.ImVec2(tcheatmenu.window.coord.X,tcheatmenu.window.coord.Y),imgui.Cond.Once)

    imgui.PushStyleVarVec2(imgui.StyleVar.WindowMinSize,imgui.ImVec2(250,350))
    imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding,imgui.ImVec2(math.floor(tcheatmenu.window.size.X/85),math.floor(tcheatmenu.window.size.Y/200)))

    imgui.Begin(tcheatmenu.window.title, tcheatmenu.window.show,imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoSavedSettings )

    --------------------------------------------------
    -- Warnings 

    if tcheatmenu.window.fail_loading_json then
        imgui.Button("Failed to load some json files!",imgui.ImVec2(fcommon.GetSize(1)))
        if imgui.Button("Reinstall latest",imgui.ImVec2(fcommon.GetSize(2))) then
            DownloadUpdate()
            tcheatmenu.window.fail_loading_json = false
        end
        imgui.SameLine()
        if imgui.Button("Hide message",imgui.ImVec2(fcommon.GetSize(2))) then
            tcheatmenu.window.fail_loading_json = false
        end
        imgui.Spacing()
    end

    if tcheatmenu.window.missing_components then
        imgui.Button("Some components of Cheat Menu are missing!",imgui.ImVec2(fcommon.GetSize(1)))
        if imgui.Button("Reinstall latest",imgui.ImVec2(fcommon.GetSize(2))) then
            DownloadUpdate()
            tcheatmenu.window.missing_components = false
        end
        imgui.SameLine()
        if imgui.Button("Hide message",imgui.ImVec2(fcommon.GetSize(2))) then
            tcheatmenu.window.missing_components = false
        end
        imgui.Spacing()
    end

    if tcheatmenu.window.restart_required then
        imgui.Button("Restart is required to apply some changes",imgui.ImVec2(fcommon.GetSize(1)))
        if imgui.Button("Restart menu",imgui.ImVec2(fcommon.GetSize(2))) then
            fmenu.tmenu.crash_text = "Cheat Menu ~g~reloaded"
			thisScript():reload()
        end
        imgui.SameLine()
        if imgui.Button("Hide message",imgui.ImVec2(fcommon.GetSize(2))) then
            tcheatmenu.window.restart_required = false
        end
        imgui.Spacing()
    end

    --------------------------------------------------
    -- Updater code
    if fmenu.tmenu.update_status == fconst.UPDATE_STATUS.NEW_UPDATE then
        imgui.Button("An updated version is available",imgui.ImVec2(fcommon.GetSize(1)))
        if imgui.Button("Download now",imgui.ImVec2(fcommon.GetSize(3))) then
            DownloadUpdate()
        end
        imgui.SameLine()
        if imgui.Button("Hide message",imgui.ImVec2(fcommon.GetSize(3))) then
            fmenu.tmenu.update_status =fconst.UPDATE_STATUS.HIDE_MSG
        end
        imgui.SameLine()
        if imgui.Button("View changelog",imgui.ImVec2(fcommon.GetSize(3))) then
            if string.find( script.this.version,"beta") then
                os.execute('explorer "https://github.com/user-grinch/Cheat-Menu/commits/master"')
            else
                os.execute('explorer "https://github.com/user-grinch/Cheat-Menu/releases/tag/' .. fmenu.tmenu.repo_version ..'"')
            end
        end
        imgui.Spacing()
    end

    if fmenu.tmenu.update_status == fconst.UPDATE_STATUS.DOWNLOADING then
        imgui.Button("Downloading update...",imgui.ImVec2(fcommon.GetSize(1)))
        imgui.Spacing()
    end

    if fmenu.tmenu.update_status == fconst.UPDATE_STATUS.INSTALL then
        if imgui.Button("Install update. This might take a while.",imgui.ImVec2(fcommon.GetSize(1))) then
            fmenu.tmenu.update_status = fconst.UPDATE_STATUS.HIDE_MSG
            fgame.tgame.script_manager.skip_auto_reload = true
            ziplib.zip_extract(tcheatmenu.dir .. "update.zip",tcheatmenu.dir,nil,nil)
            
            if string.find( script.this.version,"beta") then
                fcommon.MoveFiles(getWorkingDirectory() .. "\\lib\\cheat-menu\\Cheat-Menu-master\\",getGameDirectory())
            else
                print(fmenu.tmenu.repo_version)
                fcommon.MoveFiles(getWorkingDirectory() .. "\\lib\\cheat-menu\\Cheat-Menu-" .. fmenu.tmenu.repo_version .. "\\",getGameDirectory())
            end
            
            os.remove(tcheatmenu.dir .. "update.zip")
            printHelpString("Update ~g~Installed")
            print("Update installed. Reloading script.")
            thisScript():reload()
        end
        imgui.Spacing()
    end
    --------------------------------------------------
    -- Main code
    fcommon.CreateMenus({"Teleport","Memory","Player","Ped","Animation","Vehicle","Weapon","Mission","Stat","Game","Visual","Menu"},
    {fteleport.TeleportMain,fmemory.MemoryMain,fplayer.PlayerMain,fped.PedMain,fanimation.AnimationMain,fvehicle.VehicleMain,
    fweapon.WeaponMain,fmission.MissionMain,fstat.StatMain,fgame.GameMain,fvisual.VisualMain,fmenu.MenuMain})

    --------------------------------------------------
    -- First startup page
    if tcheatmenu.current_menu == 0 then

        if imgui.BeginChild("Welcome") then
            imgui.Dummy(imgui.ImVec2(0,10))
            imgui.TextWrapped("Welcome to " .. tcheatmenu.window.title .. " by Grinch_")
            imgui.Dummy(imgui.ImVec2(0,10))
            imgui.TextWrapped("Please configure the settings below,\n(Recommanded settings are already applied)")
            imgui.Dummy(imgui.ImVec2(0,20))

            if fstyle.tstyle.status then	
                if imgui.Combo('Select style', fstyle.tstyle.selected, fstyle.tstyle.array, #fstyle.tstyle.list) then
                    fstyle.applyStyle(imgui.GetStyle(), fstyle.tstyle.list[fstyle.tstyle.selected[0] + 1])
                    fstyle.tstyle.selected_name = fstyle.tstyle.list[fstyle.tstyle.selected[0] + 1]
                end
            end
            imgui.Spacing()
            fcommon.HotKey(tcheatmenu.hot_keys.menu_open,"Cheat Menu open/close hotkey")

            imgui.Dummy(imgui.ImVec2(0,10))

            imgui.Columns(2,nil,false)
            fcommon.CheckBoxVar("Auto reload",fmenu.tmenu.auto_reload,"Reload cheat menu automatically\nin case of a crash.\n\nMight cause crash loop sometimes.")
            fcommon.CheckBoxVar("Check for updates",fmenu.tmenu.auto_update_check,"Cheat Menu will automatically check for updates\nonline. This requires an internet connection and\
will download files from github repository.")
            imgui.NextColumn()
            fcommon.CheckBoxVar("Show tooltips",fmenu.tmenu.show_tooltips,"Shows usage tips beside options.")
            imgui.Columns(1)
            imgui.Spacing()
            imgui.TextWrapped("You can configure everything here anytime from the 'Menu' section.")
            imgui.Spacing()
            imgui.TextWrapped("This modification is licensed under the terms of GPLv3. For more details see <http://www.gnu.org/licenses/>")
            imgui.EndChild()
        end
    end
    
    --------------------------------------------------
    -- Update the menu size & positon variables so they can be saved later
    tcheatmenu.window.size.X  = imgui.GetWindowWidth()
    tcheatmenu.window.size.Y  = imgui.GetWindowHeight()
    tcheatmenu.window.coord.X = imgui.GetWindowPos().x 
    tcheatmenu.window.coord.Y = imgui.GetWindowPos().y

    --------------------------------------------------
    imgui.End()
    imgui.PopStyleVar(2)
end)

--------------------------------------------------
-- Overlay window
imgui.OnFrame(function() 

    -- return true if any overlay element needs to be displayed
    return not isGamePaused() and fmenu.tmenu.overlay.show[0] and (fmenu.tmenu.overlay.fps[0] or fmenu.tmenu.overlay.coordinates[0] or fmenu.tmenu.overlay.location[0]
    or ((fmenu.tmenu.overlay.speed[0] or fmenu.tmenu.overlay.health[0]) and isCharInAnyCar(PLAYER_PED)))
end,
function()
    local io = imgui.GetIO()
    local overlay = fmenu.tmenu.overlay
    local pos = overlay.position_index[0]

    if pos > 0 then
        x = (pos == 1 or pos == 3) and overlay.offset[0] or io.DisplaySize.x - overlay.offset[0]
        y = (pos == 1 or pos == 2) and overlay.offset[0] or io.DisplaySize.y - overlay.offset[0]
        local window_pos_pivot = imgui.ImVec2((pos == 1 or pos == 3) and 0 or 1, (pos == 1 or pos == 2) and 0 or 1)
        imgui.SetNextWindowPos(imgui.ImVec2(x, y), imgui.Cond.Always, window_pos_pivot)
    end

    local flags = imgui.WindowFlags.NoDecoration + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoSavedSettings
    if pos ~= 0 then
        flags = flags + imgui.WindowFlags.NoMove
    end

    if pos == 0 then
        imgui.SetNextWindowPos(imgui.ImVec2(fmenu.tmenu.overlay.pos_x[0], fmenu.tmenu.overlay.pos_y[0]), imgui.Cond.Once , window_pos_pivot)
    end

    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha,0.65)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowMinSize,imgui.ImVec2(0,0))
    imgui.Begin("Overlay", nil, flags)
    
    if fmenu.tmenu.overlay.fps[0] then
        imgui.Text("Frames: " .. tostring(math.floor(imgui.GetIO().Framerate)))
    end
    if isCharInAnyCar(PLAYER_PED) then
        car = getCarCharIsUsing(PLAYER_PED)
        if  fmenu.tmenu.overlay.speed[0] then
            speed = getCarSpeed(car)
            total_gears = getCarNumberOfGears(car)
            current_gear = getCarCurrentGear(car)
            imgui.Text(string.format("Speed: %d %d/%d",math.floor(speed),current_gear,total_gears))
        end

        if fmenu.tmenu.overlay.health[0] then
            imgui.Text(string.format("Health: %.0f%%",getCarHealth(car)/10))
        end
    end

    if fmenu.tmenu.overlay.location[0] then
        imgui.Text("Location: " .. fcommon.GetLocationInfo(getCharCoordinates(PLAYER_PED)))
    end

    if fmenu.tmenu.overlay.coordinates[0] then
        x,y,z = getCharCoordinates(PLAYER_PED)
        imgui.Text(string.format("Coordinates: %d %d %d", math.floor(x) , math.floor(y) , math.floor(z)),1000)
    end

    imgui.PopStyleVar(2)

    --------------------------------------------------
    -- Overlay right click menu
    if imgui.BeginPopupContextWindow() then
        imgui.Text("Position")
        imgui.Separator()

        if imgui.MenuItemBool("Custom",nil,fmenu.tmenu.overlay.position_index[0] == 0) then 
            fmenu.tmenu.overlay.position_index[0] = 0 
        end
        if imgui.MenuItemBool("Top Left",nil,fmenu.tmenu.overlay.position_index[0] == 1) then 
            fmenu.tmenu.overlay.position_index[0] = 1 
        end
        if imgui.MenuItemBool("Top Right",nil,fmenu.tmenu.overlay.position_index[0] == 2) then 
            fmenu.tmenu.overlay.position_index[0] = 2 
        end
        if imgui.MenuItemBool("Bottom Left",nil,fmenu.tmenu.overlay.position_index[0] == 3) then 
            fmenu.tmenu.overlay.position_index[0] = 3 
        end
        if imgui.MenuItemBool("Bottom Right",nil,fmenu.tmenu.overlay.position_index[0] == 4) then 
            fmenu.tmenu.overlay.position_index[0] = 4 
        end
        if imgui.MenuItemBool("Close") then
            fmenu.tmenu.overlay.fps[0] = false
            fmenu.tmenu.overlay.speed[0] = false
            fmenu.tmenu.overlay.health[0] = false
            fmenu.tmenu.overlay.coordinates[0] = false
            fmenu.tmenu.overlay.location[0] = false
        end
        imgui.EndPopup()        
    end

    --------------------------------------------------
    -- Update overlay position variables so they can updated later
    if pos == 0 then
        fmenu.tmenu.overlay.pos_x[0] = imgui.GetWindowPos().x
        fmenu.tmenu.overlay.pos_y[0] = imgui.GetWindowPos().y
    end

    --------------------------------------------------

    imgui.End()

end).HideCursor = true

--------------------------------------------------
-- Command window
imgui.OnFrame(function() 
    return not isGamePaused() and fmenu.tmenu.command.show[0]
end,
function()


    imgui.SetNextWindowPos(imgui.ImVec2(0, resY-fmenu.tmenu.command.height), imgui.Cond.Always)
    imgui.SetNextWindowSize(imgui.ImVec2(resX,fmenu.tmenu.command.height))

    local frame_padding  = {imgui.GetStyle().FramePadding.x,imgui.GetStyle().FramePadding.y}
    local window_padding = {imgui.GetStyle().WindowPadding.x,imgui.GetStyle().WindowPadding.y}
    imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(frame_padding[1],resY/130))
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(3,3))


    imgui.Begin("Command Window", nil, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.AlwaysAutoResize 
    + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoMove)

    imgui.SetNextItemWidth(resX)
    imgui.SetKeyboardFocusHere(-1)
    if imgui.InputText("##TEXTFIELD",fmenu.tmenu.command.input_field,ffi.sizeof(fmenu.tmenu.command.input_field),imgui.InputTextFlags.EnterReturnsTrue 
    or imgui.InputTextFlags.CallbackCompletion or imgui.InputTextFlags.CallbackHistory) then
        if imgui.IsKeyPressed(vkeys.VK_RETURN,false) then
            fmenu.tmenu.command.show[0] = not fmenu.tmenu.command.show[0]
            fmenu.ExecuteCommand()
            imgui.StrCopy(fmenu.tmenu.command.input_field, "", 1)
        end
    end
    imgui.End()

    imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(frame_padding[1],frame_padding[2]))
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(window_padding[1],window_padding[2]))

end).HideCursor = true

function main()

    --------------------------------------------------
    -- Functions that need to lunch only once at startup
    if isSampLoaded() then
        fgame.tgame.script_manager.skip_auto_reload = true
        print("SAMP detected, unloading script.")
        thisScript():unload()
    end

    math.randomseed(getGameTimer())

    if fmenu.tmenu.auto_update_check[0] then
        fmenu.CheckUpdates()
    end

    fplayer.CustomSkinsSetup()

    for x=1,10,1 do          
        setGangWeapons(x-1,fweapon.tweapon.gang.used_weapons[x][1],fweapon.tweapon.gang.used_weapons[x][2],fweapon.tweapon.gang.used_weapons[x][3])
    end

    if fplayer.tplayer.invisible[0] then
        fplayer.tplayer.model_val = readMemory((getCharPointer(PLAYER_PED)+1140),4,false)
        writeMemory(getCharPointer(PLAYER_PED)+1140,4,2,false)
    end

    if fgame.tgame.freeze_mission_timer[0] then
        freezeOnscreenTimer(true)
    end

    if fvehicle.tvehicle.no_vehicles[0] then
        writeMemory(0x434237,1,0x73,false) 
        writeMemory(0x434224,1,0,false)
        writeMemory(0x484D19,1,0x83,false) 
        writeMemory(0x484D17,1,0,false)
    end

    if fgame.tgame.disable_help_popups[0] == true then
        setGameGlobal(glob.Help_Wasted_Shown,1)
        setGameGlobal(glob.Help_Busted_Shown,1)
        removePickup(glob.Pickup_Info_Hospital)
        removePickup(glob.Pickup_Info_Hospital_2)
        removePickup(glob.Pickup_Info_Police)
    end

    setGameGlobal(glob.STAT_Unlocked_Cities_Number,4)

    if fgame.tgame.disable_cheats[0] == true then
        writeMemory(0x4384D0,1,0xE9,false)
        writeMemory(0x4384D1,4,0xD0,false)
        writeMemory(0x4384D5,4,0x90909090,false)
    end

    if not fgame.tgame.forbidden_area_wanted_level[0] then
        writeMemory(0x441770,1,0xC3,false)
    end

    switchArrestPenalties(not(fgame.tgame.keep_stuff[0]))
    switchDeathPenalties(not(fgame.tgame.keep_stuff[0]))

    if fped.tped.gang.wars[0] then
        setGangWarsActive(fped.tped.gang.wars[0])
    end
    
    setPlayerFastReload(PLAYER_HANDLE,fweapon.tweapon.fast_reload[0])

    if  fgame.tgame.ghost_cop_cars[0] then
        for key,value in pairs(fgame.tgame.cop) do
            writeMemory(tonumber(key),4,math.random(400,611),false)
        end
    end

    if fgame.tgame.disable_replay[0] then
        writeMemory(0x460500,4,0xC3,false)
    end

    -- Vehicle gxt names
    for gxt_name,veh_name in pairs(fvehicle.tvehicle.gxt_name_table) do
        setGxtEntry(gxt_name,veh_name)
    end

    -- Command window
    fmenu.RegisterAllCommands()

    -- Set saved values of addresses
    fconfig.SetConfigData()

    if fvisual.tvisual.disable_motion_blur[0] then
        writeMemory(0x7030A0,4,0xC3,false)
    end

    if not fvisual.tvisual.radio_channel_names[0] then
       writeMemory(0x507035,4,0x90,false)
    end

    fvehicle.ParseCarcols()
    fvehicle.ParseVehiclesIDE()

    fcommon.SingletonThread(fplayer.KeepPosition,"KeepPosition")
    fcommon.SingletonThread(fplayer.RegenerateHealth,"RegenerateHealth")
    fcommon.SingletonThread(fped.PedHealthDisplay,"PedHealthDisplay")
    fcommon.SingletonThread(fgame.FreezeTime,"FreezeTime")
    fcommon.SingletonThread(fgame.LoadScriptsOnKeyPress,"LoadScriptsOnKeyPress")
    fcommon.SingletonThread(fgame.RandomCheatsActivate,"RandomCheatsActivate")
    fcommon.SingletonThread(fgame.RandomCheatsDeactivate,"RandomCheatsDeactivate")
    fcommon.SingletonThread(fgame.SolidWater,"SolidWater")
    fcommon.SingletonThread(fgame.SyncSystemTime,"SyncSystemTime")
    fcommon.SingletonThread(fvehicle.OnEnterVehicle,"OnEnterVehicle")
    fcommon.SingletonThread(fvehicle.RainbowColors,"RainbowColors")
    fcommon.SingletonThread(fvehicle.TrafficNeons,"TrafficNeons")
    fcommon.SingletonThread(fvisual.LockWeather,"LockWeather")
    fcommon.SingletonThread(fweapon.AutoAim,"AutoAim")

    ------------------------------------------------

    while true do

        --------------------------------------------------
        -- Functions that neeed to run constantly

        --------------------------------------------------
        -- Weapons
        local pPed = getCharPointer(PLAYER_PED)
        local CurWeapon = getCurrentCharWeapon(PLAYER_PED)
        local skill = callMethod(0x5E3B60,pPed,1,0,CurWeapon)
        local pWeaponInfo = callFunction(0x743C60,2,2,CurWeapon,skill)

        if fweapon.tweapon.huge_damage[0] then
            writeMemory(pWeaponInfo+0x22,2,1000,false)
        end
        if fweapon.tweapon.long_range[0] then
            memory.setfloat(pWeaponInfo+0x04,1000.0)
            memory.setfloat(pWeaponInfo+0x08,1000.0)
        end
        if fweapon.tweapon.max_accuracy[0] then
            memory.setfloat(pWeaponInfo+0x38,1.0)
        end
        if fweapon.tweapon.max_ammo_clip[0] then
            writeMemory(pWeaponInfo+0x20,2,9999,false)
        end
        if fweapon.tweapon.max_move_speed[0] then
            memory.setfloat(pWeaponInfo+0x3C,1.0)
        end
        --------------------------------------------------

        if fanimation.tanimation.ped[0] == true or fweapon.tweapon.ped[0] == true then
            bool, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)
            if bool == true then
                fped.tped.selected = ped
            end
        end

        if fped.tped.selected ~= nil then
            if not doesCharExist(fped.tped.selected) or isCharDead(fped.tped.selected) then
                fped.tped.selected = nil
            end
        end

        -- Camera mode
        fcommon.OnHotKeyPress(tcheatmenu.hot_keys.camera_mode,function()
            fgame.tgame.camera.bool[0] = not fgame.tgame.camera.bool[0]
            if fgame.tgame.camera.bool[0] then
                fcommon.SingletonThread(fgame.CameraMode,"CameraMode")
                printHelpString("Camera mode enabled")
            else
                printHelpString("Camera mode disabled")
            end
        end)

        -- Quick screenshot
        fcommon.OnHotKeyPress(tcheatmenu.hot_keys.quick_screenshot,function()
            if fgame.tgame.ss_shortcut[0] then
                takePhoto(true)
                printHelpString("Screenshot ~g~taken")
            end
        end)

        -- Qucik teleport
        fcommon.OnHotKeyPress(tcheatmenu.hot_keys.quick_teleport,function()
            if fteleport.tteleport.shortcut[0] then
                fteleport.Teleport()
            end
        end)
        
        -- God mode
        setCharProofs(PLAYER_PED,fplayer.tplayer.god[0],fplayer.tplayer.god[0],fplayer.tplayer.god[0],fplayer.tplayer.god[0],fplayer.tplayer.god[0])

        -- Aim skin changer
        
        fcommon.OnHotKeyPress(tcheatmenu.hot_keys.asc_key,function()
            
            if fplayer.tplayer.aimSkinChanger[0] then
                
                local bool,char = getCharPlayerIsTargeting(PLAYER_HANDLE)
                if bool == true then
                    local model = getCharModel(char)
                    fplayer.ChangePlayerModel(tostring(model))
                end
            end
        end)

        --  Vehicle functions
        if isCharInAnyCar(PLAYER_PED) then
            local car = getCarCharIsUsing(PLAYER_PED)

            if fvehicle.tvehicle.car_engine[0] == fconst.CHECKBOX_STATE.ON then
                setCarEngineOn(car,true)
            end
            if fvehicle.tvehicle.car_engine[0] == fconst.CHECKBOX_STATE.OFF then
                setCarEngineOn(car,false)
            end

            -- Reset car colors if player changed color in tune shop
            if fvehicle.tvehicle.color.default ~= -1 then
                if fvehicle.tvehicle.color.default ~= getCarColours(car) then
                    fvehicle.ForEachCarComponent(function(mat,comp,car)
                        mat:reset_color()
                    end)
                end
            end

            if fvehicle.tvehicle.lock_speed[0] then
                if fvehicle.tvehicle.speed[0] > 500 then
                    fvehicle.tvehicle.speed[0] = 500
                end
                setCarForwardSpeed(car,fvehicle.tvehicle.speed[0])
            end

            if getCarDoorLockStatus(car) == 4 then
                fvehicle.tvehicle.lock_doors[0] = true
            else
                fvehicle.tvehicle.lock_doors[0] = false
            end

            setCarVisible(car,not(fvehicle.tvehicle.invisible_car[0]))
            setCarWatertight(car,fvehicle.tvehicle.watertight_car[0])
            setCarCanBeDamaged(car,not(fvehicle.tvehicle.no_damage[0]))
            setCarCanBeVisiblyDamaged(car,not(fvehicle.tvehicle.visual_damage[0]))
            setCharCanBeKnockedOffBike(PLAYER_PED,fvehicle.tvehicle.stay_on_bike[0])
            setCarHeavy(car,fvehicle.tvehicle.heavy[0])

        else
            fvehicle.tvehicle.lock_doors[0] = false
            fvehicle.tvehicle.lights[0] = false
        end

        ------------------------------------------------
        -- Menu open close
        fcommon.OnHotKeyPress(tcheatmenu.hot_keys.menu_open,function()
            tcheatmenu.window.show[0] = not tcheatmenu.window.show[0]
        end)

        fcommon.OnHotKeyPress(tcheatmenu.hot_keys.command_window,function()
            fmenu.tmenu.command.show[0] = not fmenu.tmenu.command.show[0]
        end)

        wait(0)
    end
end

function onScriptTerminate(script, quitGame)
    if script == thisScript() then

        fconfig.Write()
        fcommon.SaveJson("animation",fanimation.tanimation.list)
        fteleport.tteleport.coordinates["Radar"] = nil
        fcommon.SaveJson("coordinate",fteleport.tteleport.coordinates)
        fcommon.SaveJson("memory",fmemory.tmemory.list)

        if isCharInAnyCar(PLAYER_PED) then
            local model = getCarModel(getCarCharIsUsing(PLAYER_PED))
            fvehicle.tvehicle.first_person_camera.offsets[tostring(model)].x = fvehicle.tvehicle.first_person_camera.offset_x_var[0]
            fvehicle.tvehicle.first_person_camera.offsets[tostring(model)].y = fvehicle.tvehicle.first_person_camera.offset_y_var[0] 
            fvehicle.tvehicle.first_person_camera.offsets[tostring(model)].z = fvehicle.tvehicle.first_person_camera.offset_z_var[0] 
            fcommon.SaveJson("first person camera offsets",fvehicle.tvehicle.first_person_camera.offsets)
        end

        if fgame.tgame.camera.bool[0] then
            displayRadar(true)
            displayHud(true)
        end

        restoreCameraJumpcut()

        if doesObjectExist(fgame.tgame.solid_water_object) then
            deleteObject(fgame.tgame.solid_water_object)
        end

        fgame.RemoveAllObjects()
        fped.RemoveAllSpawnedPeds()   
        fweapon.RemoveAllWeaponDrops()
         
        fcommon.ReleaseImages(fvehicle.tvehicle.images)
        fcommon.ReleaseImages(fweapon.tweapon.images)
        fcommon.ReleaseImages(fvehicle.tvehicle.paintjobs.images)
        fcommon.ReleaseImages(fvehicle.tvehicle.components.images)
        fcommon.ReleaseImages(fped.tped.images)
        fcommon.ReleaseImages(fplayer.tplayer.clothes.images)

        if fconfig.tconfig.reset == false then
            if fmenu.tmenu.crash_text == "" then
                fmenu.tmenu.crash_text = "Cheat menu crashed unexpectedly"

                if fmenu.tmenu.auto_reload[0] and not fgame.tgame.script_manager.skip_auto_reload then
                    script:reload()
                    fmenu.tmenu.crash_text =  fmenu.tmenu.crash_text .. " but reloaded"
                end
            end
        end
        if fmenu.tmenu.show_crash_message[0] and not fgame.tgame.script_manager.skip_auto_reload then
            printHelpString(fmenu.tmenu.crash_text)
        end
    end
end

function onSaveGame()
    fgame.RemoveAllObjects()
    fped.RemoveAllSpawnedPeds()   
    fweapon.RemoveAllWeaponDrops()  
end