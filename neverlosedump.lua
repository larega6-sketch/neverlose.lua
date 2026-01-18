-- NEVERLOSE LUA CUSTOM v2 by zxcsavaq
local DEV_NICK = "zxcsavaq"

-- Проверка поддержки Drawing
local canDraw = false
pcall(function()
    if Drawing and Drawing.new then
        local t = Drawing.new("Text")
        t.Visible = false
        t:Remove()
        canDraw = true
    end
end)

-- UI библиотека
local succ, NEVERLOSE = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/3345-c-a-t-s-u-s/NEVERLOSE-UI-Nightly/main/source.lua"))()
end)
if not succ then
    warn("Невозможно загрузить библиотеку интерфейса! [neverlose.lua]")
    return
end
NEVERLOSE:Theme("original")
local Window = NEVERLOSE:AddWindow("NEVERLOSE", "dev:"..DEV_NICK)
local Notification = NEVERLOSE:Notification()
Notification.MaxNotifications = 6
Window:AddTabLabel('Home')

local MainTab = Window:AddTab('Ragebot', 'mouse')
local VisualsTab = Window:AddTab('Visuals', 'earth')

local Plrs = game:GetService("Players")
local RS = game:GetService("RunService")
local LP = Plrs.LocalPlayer

-- ----------- WATERMARK --------------
local wm
local function setupWatermark()
    if not canDraw then return end
    if wm and wm.Remove then wm:Remove() end
    wm = Drawing.new("Text")
    wm.Font = Drawing.Fonts.Plex
    wm.Size = 17
    wm.Outline = true
    wm.Color = Color3.fromRGB(0,255,185)
    wm.Position = Vector2.new(24, 24)
    wm.Visible = true
end
local lastfps, lastfpsupd, framecnt = 60, 0, 0
local function getFPS()
    framecnt = framecnt + 1
    if tick()-lastfpsupd>=1 then
        lastfps, lastfpsupd = framecnt, tick()
        framecnt = 0
    end
    return lastfps
end
local function getPing()
    local stats = LP:GetNetworkPing and LP:GetNetworkPing() or 0.042
    return math.floor(stats*1000)
end
if canDraw then setupWatermark() end
RS.RenderStepped:Connect(function()
    if canDraw and wm then
        wm.Text = string.format("neverlose | dev: %s | fps: %d | ping: %dms", DEV_NICK, getFPS(), getPing())
        wm.Visible = true
    end
end)

-- ----------- HITLOG (Drawing) -----------
local hitlogs = {}
local function AddHitLog(name, resultStr, hit)
    table.insert(hitlogs, {text = name.." ["..resultStr.."]", hit = hit, time = tick(), obj = nil})
end
local function DrawHitLogs()
    if not canDraw then return end
    -- Удалять старые, обновлять позицию
    for i=#hitlogs,1,-1 do
        if tick()-hitlogs[i].time > 180 then
            if hitlogs[i].obj then pcall(function() hitlogs[i].obj:Remove() end) end
            table.remove(hitlogs, i)
        end
    end
    local y = 52
    for i,log in ipairs(hitlogs) do
        if not log.obj or not log.obj.Remove then
            log.obj = Drawing.new("Text")
            log.obj.Font = Drawing.Fonts.Plex
            log.obj.Size = 17
            log.obj.Outline = true
            log.obj.Center = false
        end
        log.obj.Text = log.text
        log.obj.Position = Vector2.new(24, y)
        log.obj.Color = log.hit and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,45,50)
        log.obj.Visible = true
        y = y + 23
    end
end
if canDraw then
    RS.RenderStepped:Connect(DrawHitLogs)
end

-- ---------- CHAMS -------------
local materialMap = {
    ["Flat"] = Enum.Material.SmoothPlastic,
    ["Glossy"] = Enum.Material.Neon,
    ["Crystal"] = Enum.Material.ForceField,
    ["Glass"] = Enum.Material.Glass,
    ["Metallic"] = Enum.Material.Metal,
    ["Wireframe"] = Enum.Material.Foil,
}
local ChamsSettings = {
    Self = {
        Enabled = true, Material = "Glossy",
        Color = Color3.fromRGB(0,170,255), Transparency = 0.1
    },
    Enemy = {
        Enabled = true, Material = "Flat",
        Color = Color3.fromRGB(255,70,80), Transparency = 0.25
    }
}
local allChams = {}
local function ClearChams()
    for _,adorns in pairs(allChams) do
        if adorns then for _,a in ipairs(adorns) do pcall(function() a:Destroy() end) end end
    end
    allChams = {}
end
local function GetChamsSet(plr)
    return (plr==LP) and ChamsSettings.Self or ChamsSettings.Enemy
end
local function UpdateChams()
    ClearChams()
    for _,plr in ipairs(Plrs:GetPlayers()) do
        local set = GetChamsSet(plr)
        if set.Enabled and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local chamsList = {}
            for _,part in ipairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Transparency < 0.99 and part.Name ~= "HumanoidRootPart" then
                    local ok,adorn = pcall(function()
                        local ad = Instance.new("BoxHandleAdornment")
                        ad.Adornee = part
                        ad.AlwaysOnTop = true
                        ad.ZIndex = 9
                        ad.Size = part.Size + Vector3.new(0.08,0.08,0.08)
                        ad.Color3 = set.Color
                        ad.Transparency = set.Transparency
                        ad.Parent = part
                        ad.Name = "__Chams"
                        pcall(function() part.Material = materialMap[set.Material] or Enum.Material.SmoothPlastic end)
                        return ad
                    end)
                    if ok and adorn then table.insert(chamsList, adorn) end
                end
            end
            allChams[plr.Character] = chamsList
        end
    end
end
RS.RenderStepped:Connect(UpdateChams)
Plrs.PlayerAdded:Connect(function() task.wait(1) UpdateChams() end)
Plrs.PlayerRemoving:Connect(function() task.wait(1) UpdateChams() end)

local matOpts = {"Flat","Glossy","Crystal","Glass","Metallic","Wireframe"}
local VisualsSection1 = VisualsTab:AddSection('Chams: Self', "left")
VisualsSection1:AddToggle('Chams on Self', ChamsSettings.Self.Enabled, function(val)
    ChamsSettings.Self.Enabled = val; UpdateChams()
end)
VisualsSection1:AddDropdown('Self Material', matOpts, ChamsSettings.Self.Material, function(val)
    ChamsSettings.Self.Material = val; UpdateChams()
end)
VisualsSection1:AddColorpicker("Self Color", ChamsSettings.Self.Color, function(val)
    ChamsSettings.Self.Color = val; UpdateChams()
end)
VisualsSection1:AddSlider('Self Transp', 0, 1, ChamsSettings.Self.Transparency, function(val)
    ChamsSettings.Self.Transparency = val; UpdateChams()
end)
local VisualsSection2 = VisualsTab:AddSection('Chams: Enemy', "left")
VisualsSection2:AddToggle('Chams on Enemy', ChamsSettings.Enemy.Enabled, function(val)
    ChamsSettings.Enemy.Enabled = val; UpdateChams()
end)
VisualsSection2:AddDropdown('Enemy Material', matOpts, ChamsSettings.Enemy.Material, function(val)
    ChamsSettings.Enemy.Material = val; UpdateChams()
end)
VisualsSection2:AddColorpicker("Enemy Color", ChamsSettings.Enemy.Color, function(val)
    ChamsSettings.Enemy.Color = val; UpdateChams()
end)
VisualsSection2:AddSlider('Enemy Transp', 0, 1, ChamsSettings.Enemy.Transparency, function(val)
    ChamsSettings.Enemy.Transparency = val; UpdateChams()
end)

-- --------- RAGEBOT (улучшенный) ---------
local RageSettings = {
    Enabled = false,
    AutoFire = true,
    TeamCheck = true,
    WallCheck = true,
    SmartAim = true,
    Hitbox = "Head",
    MaxDist = 1200,
    BodyAimHP = 35,
    MinVisibleTime = 0.03,
    WaitForKillShot = true,
    MissOnJump = true,
}
local playerData, playerDataTime = {}, 0
local myChar, myHRP, myHead, myHum, fireShot, fireShotTime = nil, nil, nil, nil, nil, 0
local rbLast, frame = 0, 0
local WS = game:GetService("Workspace")
local RayP = RaycastParams.new()
RayP.FilterType = Enum.RaycastFilterType.Exclude

local function CacheChar()
    local c = LP.Character
    if c then
        myChar, myHRP = c, c:FindFirstChild("HumanoidRootPart")
        myHead, myHum = c:FindFirstChild("Head"), c:FindFirstChildOfClass("Humanoid")
    else myChar, myHRP, myHead, myHum = nil,nil,nil,nil end
end
local function UpdatePlayerData()
    local now = tick()
    if now - playerDataTime < 0.16 then return end
    playerDataTime = now
    CacheChar()
    if not myHRP then return end
    local myPos, myTeam, myColor = myHRP.Position, LP.Team, LP.TeamColor
    table.clear(playerData)
    for _,p in ipairs(Plrs:GetPlayers()) do
        if p~=LP and p.Character then
            local c,h,r = p.Character, p.Character:FindFirstChild("Humanoid"), p.Character:FindFirstChild("HumanoidRootPart")
            if h and h.Health > 0 and r then
                local dist = (myPos - r.Position).Magnitude
                if dist < 2000 then
                    local isTeam = RageSettings.TeamCheck and myTeam and (p.Team==myTeam or p.TeamColor==myColor)
                    table.insert(playerData, {
                        p=p, c=c, h=h, r=r, head=c:FindFirstChild("Head"),
                        torso=c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"),
                        dist=dist, team=isTeam, vel=r.AssemblyLinearVelocity,
                    })
                end
            end
        end
    end
    table.sort(playerData, function(a,b) return a.dist<b.dist end)
end
local function GetFireShot()
    local now = tick()
    if fireShot and fireShot.Parent and now-fireShotTime < 5 then return fireShot end
    if not myChar then CacheChar() end
    if not myChar then return nil end
    for _,child in ipairs(myChar:GetChildren()) do
        if child:IsA("Tool") then
            local remotes = child:FindFirstChild("Remotes")
            if remotes then
                local fs = remotes:FindFirstChild("FireShot") or remotes:FindFirstChild("fireShot")
                if fs then
                    fireShot,fireShotTime = fs,now
                    return fs
                end
            end
        end
    end
    return nil
end
local function CanTarget(d)
    if not d or d.team or d.dist > RageSettings.MaxDist then return false end
    if RageSettings.MissOnJump and d.vel and math.abs(d.vel.Y) > 9.5 then return false end
    return true
end
local function MainLoop()
    if not RageSettings.Enabled then return end
    frame = frame + 1
    if frame % 15 == 0 then CacheChar() end
    if not myChar or not myHRP then return end
    UpdatePlayerData()
    local now, hrp, head = tick(), myHRP, myHead
    if not RageSettings.AutoFire or not head then return end
    if myHum and hrp and (myHum.FloorMaterial == Enum.Material.Air or math.abs(hrp.AssemblyLinearVelocity.Y) > 2) then return end
    if now - rbLast < 0.035 then return end
    RayP.FilterDescendantsInstances = {myChar}
    local bulletOrigin = hrp.Position + Vector3.new(0,1.5,0)
    local best, bestScore = nil, -9999
    for _,d in ipairs(playerData) do
        if not CanTarget(d) then continue end
        -- WALL CHECK через Raycast
        local see = true
        if RageSettings.WallCheck then
            RayP.FilterDescendantsInstances = {myChar, d.c}
            local res = WS:Raycast(bulletOrigin, (d.r.Position - bulletOrigin).Unit * (d.dist+0.2), RayP)
            see = res == nil
        end
        if not see then continue end
        -- HITBOX AIM, либо Head либо Torso/Body
        local tgt = RageSettings.Hitbox=="Head" and d.head or d.torso or d.r
        if tgt then
            local pred = 0.14 + math.clamp(d.dist/450, 0, 0.24)
            local targetPos = tgt.Position + (d.vel or Vector3.zero) * pred
            local score = 255 - d.dist + (d.h and d.h.Health and d.h.Health<RageSettings.BodyAimHP and 35 or 0)
            if RageSettings.SmartAim and d.h and d.h.Health<(d.h.MaxHealth or 100)*.20 then score = score + 22 end
            if score > bestScore then
                bestScore = score
                best = {d=d, tgt=tgt, pos=targetPos}
            end
        end
    end
    if best and GetFireShot() then
        local fs = GetFireShot()
        if fs then
            local direction = (best.pos - bulletOrigin).Unit
            local result, msg = pcall(function() fs:FireServer(bulletOrigin, direction, best.tgt) end)
            rbLast = now
            if result then AddHitLog(best.d.p.Name, "HIT", true)
            else AddHitLog(best.d.p.Name, "MISS", false) end
        end
    end
    if frame>1000 then frame=0 end
end
local mainConn
local function StartRagebot()
    if mainConn then return end
    mainConn = RS.Heartbeat:Connect(MainLoop)
    Notification:Notify("success", "Ragebot", "Enabled!")
end
local function StopRagebot()
    if mainConn then mainConn:Disconnect(); mainConn=nil end
    Notification:Notify("warning", "Ragebot", "Disabled!")
end
local RageSection = MainTab:AddSection('Ragebot Settings', "left")
RageSection:AddToggle('Enable Ragebot', false, function(val)
    RageSettings.Enabled = val; if val then StartRagebot() else StopRagebot() end
end)
RageSection:AddToggle('Auto Fire', true, function(val) RageSettings.AutoFire = val end)
RageSection:AddToggle('Team Check', true, function(val) RageSettings.TeamCheck = val end)
RageSection:AddToggle('Wall Check', true, function(val) RageSettings.WallCheck = val end)
RageSection:AddToggle('Smart Aim', true, function(val) RageSettings.SmartAim = val end)
RageSection:AddDropdown('Hitbox', {"Head", "Torso", "Body"}, "Head", function(val)
    RageSettings.Hitbox = val
end)
RageSection:AddSlider('Max Distance', 50, 1800, 1200, function(val)
    RageSettings.MaxDist = val
end)
RageSection:AddSlider('Body Aim HP', 10, 100, 35, function(val)
    RageSettings.BodyAimHP = val
end)
RageSection:AddSlider('Min Visible Time', 0.01, 0.2, 0.04, function(val)
    RageSettings.MinVisibleTime = val
end)
RageSection:AddToggle('Wait Kill Shot', true, function(val)
    RageSettings.WaitForKillShot = val
end)

-- --------- UNINJECT -----------
local function UninjectAll()
    if mainConn then mainConn:Disconnect() mainConn = nil end
    Notification:Notify("warning", "neverlose.lua", "Script Uninjected!")
    Window:Close()
    for i,v in pairs(getconnections(RS.Heartbeat)) do
        if v.Function and debug.getinfo(v.Function).source:find("neverlose") then
            v:Disconnect()
        end
    end
    if wm then pcall(function() wm:Remove() end) end
    for _,h in ipairs(hitlogs) do
        if h.obj then pcall(function() h.obj:Remove() end) end
    end
    ClearChams()
end
local UninjectSection = MainTab:AddSection('Uninject', "right")
UninjectSection:AddButton("Uninject Script", function() UninjectAll() end)

Notification:Notify("info", "neverlose.lua", "Loaded! (Rage, Custom Chams, Watermark, Hitlog)")
print("neverlose.lua launched: zxcsavaq edition (drawing="..tostring(canDraw)..")")
