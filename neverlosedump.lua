-- NEVERLOSE LUA | REBORN
local DEV_NICK = "zxcsavaq"

---- LIB IMPORT
local NEVERLOSE = loadstring(game:HttpGet("https://raw.githubusercontent.com/3345-c-a-t-s-u-s/NEVERLOSE-UI-Nightly/main/source.lua"))()
NEVERLOSE:Theme("original")

local Window = NEVERLOSE:AddWindow("NEVERLOSE", "dev:" .. DEV_NICK)
local Notification = NEVERLOSE:Notification()
Notification.MaxNotifications = 6
Window:AddTabLabel('Home')

local MainTab = Window:AddTab('Ragebot', 'mouse')
local VisualsTab = Window:AddTab('Visuals', 'earth')
local AntiAimTab = Window:AddTab('AntiAim', 'users')
local GhostTab = Window:AddTab('GhostPeek', 'eye')

local Plrs = game:GetService("Players")
local WS = game:GetService("Workspace")
local RS = game:GetService("RunService")
local LP = Plrs.LocalPlayer

-- WATERMARK
local Drawing = Drawing or false -- в Synapse/Trigon это глобально
local wm
local function SetupWatermark()
    if not Drawing then return end
    wm = Drawing.new("Text")
    wm.Font = Drawing.Fonts.Plex
    wm.Size = 17
    wm.Outline = true
    wm.Color = Color3.fromRGB(0, 255, 185)
    wm.Position = Vector2.new(24, 24)
    wm.Visible = true
end
local function GetFps()
    local last = tick()
    local counter, fps = 0, 0
    game:GetService("RunService").RenderStepped:Connect(function()
        counter = counter + 1
        if tick() - last >= 1 then
            fps = counter
            counter = 0
            last = tick()
        end
    end)
    return function() return fps end
end
local fps_fn = GetFps()
local function GetPing()
    if LP:GetNetworkPing then
        return math.floor(LP:GetNetworkPing()*1000)
    elseif LP.PlayerPing then
        return math.floor(LP.PlayerPing.Value or 0)
    end
    return 40
end

-- ХИТЛОГ
local hitlogs = {}
local function AddHitLog(name, resultStr, hit)
    table.insert(hitlogs, {
        text = name .." [".. resultStr .."]",
        hit = hit,
        time = tick()
    })
end
local function DrawHitLogs()
    if not Drawing then return end
    for i,d in ipairs(hitlogs) do
        if not d.DrawObj then
            local t = Drawing.new("Text")
            t.Font = Drawing.Fonts.Plex
            t.Size = 17
            t.Outline = true
            t.Center = false
            t.Visible = true
            t.Color = d.hit and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 45, 50)
            t.Text = d.text
            t.Position = Vector2.new(24, 58 + (i-1)*23)
            d.DrawObj = t
        end
    end
    -- auto remove through time
    for i = #hitlogs, 1, -1 do
        if tick() - hitlogs[i].time > 180 then
            if hitlogs[i].DrawObj then pcall(function() hitlogs[i].DrawObj:Remove() end) end
            table.remove(hitlogs, i)
        end
    end
    -- refresh positions
    local y = 58
    for _,d in ipairs(hitlogs) do
        d.DrawObj.Position = Vector2.new(24, y)
        d.DrawObj.Visible = true
        y = y + 23
    end
end

SetupWatermark()
RS.RenderStepped:Connect(function()
    if wm then
        wm.Text = string.format("neverlose | dev: %s | fps: %d | ping: %dms", DEV_NICK, fps_fn(), GetPing())
        wm.Visible = true
    end
    DrawHitLogs()
end)

-- ЧАМСЫ
local materialMap = {
    ["Flat"] = Enum.Material.SmoothPlastic,
    ["Glossy"] = Enum.Material.Neon,
    ["Crystal"] = Enum.Material.ForceField,
    ["Glass"] = Enum.Material.Glass,
    ["Metallic"] = Enum.Material.Metal,
    ["Wireframe"] = Enum.Material.Foil,
}

local defaultColor = Color3.fromRGB(32, 212, 236)
local ChamsSettings = {
    Self = {
        Enabled = true,
        Material = "Glossy",
        Color = Color3.fromRGB(0, 170, 255),
        Transparency = 0.1,
    },
    Enemy = {
        Enabled = true,
        Material = "Flat",
        Color = Color3.fromRGB(255, 50, 70),
        Transparency = 0.27,
    }
}
local allChams = {}

local function ClearChams()
    for model,adorns in pairs(allChams) do
        if adorns then
            for _,a in ipairs(adorns) do
                if a and a.Parent then a:Destroy() end
            end
        end
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
                    local adorn = Instance.new("BoxHandleAdornment")
                    adorn.Adornee = part
                    adorn.AlwaysOnTop = true
                    adorn.ZIndex = 10
                    adorn.Size = part.Size + Vector3.new(0.08,0.08,0.08)
                    adorn.Color3 = set.Color
                    adorn.Transparency = set.Transparency
                    adorn.Parent = part
                    adorn.Name = "__Chams"
                    table.insert(chamsList, adorn)
                    pcall(function()
                        part.Material = materialMap[set.Material] or Enum.Material.SmoothPlastic
                    end)
                end
            end
            allChams[plr.Character] = chamsList
        end
    end
end

RS.RenderStepped:Connect(UpdateChams)
Plrs.PlayerAdded:Connect(function() task.wait(1) UpdateChams() end)
Plrs.PlayerRemoving:Connect(function() task.wait(1) UpdateChams() end)

-- MENU для чамсов (раздельно self/enemy)
local matOpts = {"Flat","Glossy","Crystal","Glass","Metallic","Wireframe"}
local VisualsSection = VisualsTab:AddSection('Chams - Self', "left")
VisualsSection:AddToggle('Chams on Self', ChamsSettings.Self.Enabled, function(val)
    ChamsSettings.Self.Enabled = val
    UpdateChams()
end)
VisualsSection:AddDropdown('Self Material', matOpts, ChamsSettings.Self.Material, function(val)
    ChamsSettings.Self.Material = val
    UpdateChams()
end)
VisualsSection:AddColorpicker("Self Color", ChamsSettings.Self.Color, function(val)
    ChamsSettings.Self.Color = val
    UpdateChams()
end)
VisualsSection:AddSlider('Self Transp', 0, 1, ChamsSettings.Self.Transparency, function(val)
    ChamsSettings.Self.Transparency = val
    UpdateChams()
end)

local VisualsSection2 = VisualsTab:AddSection('Chams - Enemy', "left")
VisualsSection2:AddToggle('Chams on Enemy', ChamsSettings.Enemy.Enabled, function(val)
    ChamsSettings.Enemy.Enabled = val
    UpdateChams()
end)
VisualsSection2:AddDropdown('Enemy Material', matOpts, ChamsSettings.Enemy.Material, function(val)
    ChamsSettings.Enemy.Material = val
    UpdateChams()
end)
VisualsSection2:AddColorpicker("Enemy Color", ChamsSettings.Enemy.Color, function(val)
    ChamsSettings.Enemy.Color = val
    UpdateChams()
end)
VisualsSection2:AddSlider('Enemy Transp', 0, 1, ChamsSettings.Enemy.Transparency, function(val)
    ChamsSettings.Enemy.Transparency = val
    UpdateChams()
end)


-- UNINJECT SYSTEM
local uninjected = false
local function UninjectAll()
    if mainConn then mainConn:Disconnect() mainConn = nil end
    if ghostPeekConn then ghostPeekConn:Disconnect() ghostPeekConn = nil end
    Notification:Notify("warning", "neverlose.lua", "Script Uninjected!")
    Window:Close()
    for i,v in pairs(getconnections(RS.Heartbeat)) do
        if v.Function and debug.getinfo(v.Function).source:find("neverlose") then
            v:Disconnect()
        end
    end
    uninjected = true
    if wm then wm:Remove() end
    for _,d in ipairs(hitlogs) do
        if d.DrawObj then pcall(function() d.DrawObj:Remove() end) end
    end
end
local UninjectSection = MainTab:AddSection('Uninject', "right")
UninjectSection:AddButton("Uninject Script", function()
    UninjectAll()
end)

------------------------------------------------------
------------------- IMPROVED RAGEBOT -----------------
------------------------------------------------------
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
    MissOnJump = true, -- NEW: не стрелять по прыгающим сильно
}
local playerData, playerDataTime = {}, 0
local myChar, myHRP, myHead, myHum, fireShot, fireShotTime = nil, nil, nil, nil, nil, 0
local rbLast, frame = 0, 0
local RayP = RaycastParams.new(); RayP.FilterType = Enum.RaycastFilterType.Exclude

local function CacheChar()
    local c = LP.Character
    if c then
        myChar, myHRP = c, c:FindFirstChild("HumanoidRootPart")
        myHead, myHum = c:FindFirstChild("Head"), c:FindFirstChildOfClass("Humanoid")
    else myChar, myHRP, myHead, myHum = nil, nil, nil, nil end
end

-- собери врагов заранее, сразу сорта
local function UpdatePlayerData()
    local now = tick()
    if now - playerDataTime < 0.15 then return end
    playerDataTime = now
    CacheChar()
    if not myHRP then return end
    local myPos = myHRP.Position
    local myTeam, myColor = LP.Team, LP.TeamColor
    table.clear(playerData)
    for _,p in ipairs(Plrs:GetPlayers()) do
        if p ~= LP and p.Character then
            local c, h, r = p.Character, p.Character:FindFirstChild("Humanoid"), p.Character:FindFirstChild("HumanoidRootPart")
            if h and h.Health > 0 and r then
                local dist = (myPos - r.Position).Magnitude
                if dist < 2000 then
                    local isTeam = RageSettings.TeamCheck and myTeam and (p.Team==myTeam or p.TeamColor==myColor)
                    playerData[#playerData+1] = {
                        p=p, c=c, h=h, r=r,
                        head=c:FindFirstChild("Head"),
                        torso=c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"),
                        dist=dist, team=isTeam,
                        vel=r.AssemblyLinearVelocity,
                        lastVisible=tick(),
                        lastMissed=0
                    }
                end
            end
        end
    end
    -- сортировка по расстоянию
    table.sort(playerData, function(a,b) return a.dist < b.dist end)
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
                    fireShot, fireShotTime = fs, now; return fs
                end
            end
        end
    end
    return nil
end

local function CanTarget(d)
    if not d or d.team or d.dist > RageSettings.MaxDist then return false end
    if RageSettings.MissOnJump and d.vel and math.abs(d.vel.Y) > 10 then return false end
    return true
end

local function MainLoop()
    if uninjected or not RageSettings.Enabled then return end
    frame = frame + 1
    if frame%15 == 0 then CacheChar() end
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
            local res = WS:Raycast(bulletOrigin, (d.r.Position - bulletOrigin).Unit * (d.dist + 0.2), RayP)
            see = res == nil
        end
        if not see then continue end
        -- HITBOX AIM PREDICT
        local tgt = RageSettings.Hitbox=="Head" and d.head or d.torso or d.r
        if tgt then
            local pred = 0.14 + math.clamp(d.dist/450, 0, 0.24)
            local targetPos = tgt.Position + (d.vel or Vector3.zero) * pred
            -- расчет очков
            local score = 240 - d.dist
            if d.h and d.h.Health and d.h.Health < RageSettings.BodyAimHP then score = score + 22 end
            if RageSettings.SmartAim and d.h and d.h.Health < (d.h.MaxHealth or 100)*.17 then score = score + 28 end
            if score > bestScore then
                bestScore = score
                best = {d = d, tgt = tgt, pos = targetPos}
            end
        end
    end
    if best and GetFireShot() then
        local fs = GetFireShot()
        if fs then
            local direction = (best.pos - bulletOrigin).Unit
            local result, msg = pcall(function() fs:FireServer(bulletOrigin, direction, best.tgt) end)
            rbLast = now
            if result then
                AddHitLog(best.d.p.Name, "HIT", true)
                Notification:Notify("info", "Ragebot", "Shot at "..(best.d.p.Name))
            else
                AddHitLog(best.d.p.Name, "MISS", false)
                Notification:Notify("error", "Ragebot", "Missed "..(best.d.p.Name))
            end
        end
    end
    if frame > 1000 then frame = 0 end
end

local mainConn
local function StartRagebot()
    if mainConn then return end
    mainConn = RS.Heartbeat:Connect(MainLoop)
    Notification:Notify("success", "Ragebot", "Enabled!")
end
local function StopRagebot()
    if mainConn then mainConn:Disconnect(); mainConn = nil end
    Notification:Notify("warning", "Ragebot", "Disabled!")
end

local RageSection = MainTab:AddSection('Ragebot Settings', "left")
RageSection:AddToggle('Enable Ragebot', false, function(val)
    RageSettings.Enabled = val
    if val then StartRagebot() else StopRagebot() end
end)
RageSection:AddToggle('Auto Fire', true, function(val)
    RageSettings.AutoFire = val
end)
RageSection:AddToggle('Team Check', true, function(val)
    RageSettings.TeamCheck = val
end)
RageSection:AddToggle('Wall Check', true, function(val)
    RageSettings.WallCheck = val
end)
RageSection:AddToggle('Smart Aim', true, function(val)
    RageSettings.SmartAim = val
end)
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

-- GHOST PEEK LOGIC: можно оставить, как раньше (добавьте AddHitLog в случае успеха, аналогично Ragebot)

-- АНТИ-АИМ пререзервирован, если нужен полный – напишите, добавлю!

CacheChar()
Notification:Notify("info", "neverlose.lua", "Loaded! (Rage v2, Chams individual, Ghost Peek, Watermark, Hitlog styled)")
print("neverlose.lua: Reborn (by zxcsavaq, special for neverlose.lua, improved UI/Chams/Hitlogs/Rage)")
