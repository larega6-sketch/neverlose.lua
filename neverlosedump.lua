local NEVERLOSE = loadstring(game:HttpGet("https://raw.githubusercontent.com/3345-c-a-t-s-u-s/NEVERLOSE-UI-Nightly/main/source.lua"))()

-- Use Night Mode
NEVERLOSE:Theme("nightly") -- night mode

local Window = NEVERLOSE:AddWindow("NEVERLOSE", "Arcanum Ragebot")
local Notification = NEVERLOSE:Notification()
Notification.MaxNotifications = 6
Window:AddTabLabel('Home')

local MainTab = Window:AddTab('Ragebot', 'mouse')
local VisualsTab = Window:AddTab('Visuals', 'earth')

-- ========== SYSTEM VARIABLES ==========
local Plrs = game:GetService("Players")
local WS = game:GetService("Workspace")
local RS = game:GetService("RunService")
local LP = Plrs.LocalPlayer

-- Ragebot settings, no ping dependence
local RageSettings = {
    Enabled = false,
    AutoFire = true,
    TeamCheck = true,
    WallCheck = true,
    NoAirShot = true,
    SmartAim = true,
    AirShoot = false,
    Hitbox = "Head",
    MaxDist = 500,
    BodyAimHP = 50,
    
    Prediction = true,
    PredMode = "Default",
    AIConfThreshold = 60,
    AIHistorySize = 30,
    AIPeekDetect = true,
    AIStrafeDetect = true,
    AIVisualBox = false,
    AIVisualTrace = false,
    
    DTEnabled = false,
    DTKey = Enum.KeyCode.E,
    DTDistance = 6,
    DTMode = "Defensive",
    DTAuto = false,
    DTAutoDelay = 200,
}

local VisualSettings = {
    HitLogger = true,
    MaxLogs = 8,
    Hitmarker = true,
    HitmarkerColor = "Green",
    KillEffect = true,
    KillEffectColor = "White",
    TimeDisplay = true,
    HotkeyList = true,
}

local playerData = {}
local playerDataTime = 0
local PLAYER_CACHE_INTERVAL = 0.2
local myChar, myHRP, myHead, myHum
local fireShot, fireShotTime = nil, 0
local rbLast = 0
local frame = 0
local RayP = RaycastParams.new()
RayP.FilterType = Enum.RaycastFilterType.Exclude

local function CacheChar()
    local c = LP.Character
    if c then
        myChar, myHRP = c, c:FindFirstChild("HumanoidRootPart")
        myHead, myHum = c:FindFirstChild("Head"), c:FindFirstChildOfClass("Humanoid")
    else
        myChar, myHRP, myHead, myHum = nil, nil, nil, nil
    end
end

local function UpdatePlayerData()
    local now = tick()
    if now - playerDataTime < PLAYER_CACHE_INTERVAL then return end
    playerDataTime = now
    if not myHRP then return end
    local myPos = myHRP.Position
    local myTeam, myColor = LP.Team, LP.TeamColor
    
    for i = 1, 16 do
        playerData[i] = nil
    end
    
    local count = 0
    for _, p in ipairs(Plrs:GetPlayers()) do
        if p ~= LP then
            local c = p.Character
            if c then
                local h = c:FindFirstChild("Humanoid")
                local r = c:FindFirstChild("HumanoidRootPart")
                if h and h.Health > 0 and r then
                    local dist = (myPos - r.Position).Magnitude
                    if dist < 600 then
                        count = count + 1
                        local isTeam = myTeam and (p.Team == myTeam or p.TeamColor == myColor)
                        playerData[count] = {
                            p = p, c = c, h = h, r = r,
                            head = c:FindFirstChild("Head"),
                            torso = c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"),
                            dist = dist, team = isTeam,
                            vel = r.AssemblyLinearVelocity
                        }
                    end
                end
            end
        end
    end
    
    -- Sorting by distance
    for i = 2, count do
        local key = playerData[i]
        local j = i - 1
        while j >= 1 and playerData[j] and playerData[j].dist > key.dist do
            playerData[j + 1] = playerData[j]
            j = j - 1
        end
        playerData[j + 1] = key
    end
end

local function GetFireShot()
    local now = tick()
    if fireShot and fireShot.Parent and now - fireShotTime < 5 then return fireShot end
    if not myChar then CacheChar() end
    if not myChar then return nil end
    for _, child in ipairs(myChar:GetChildren()) do
        if child:IsA("Tool") then
            local remotes = child:FindFirstChild("Remotes")
            if remotes then
                local fs = remotes:FindFirstChild("FireShot") or remotes:FindFirstChild("fireShot")
                if fs then 
                    fireShot, fireShotTime = fs, now 
                    return fs 
                end
            end
        end
    end
    return nil
end

-- ===== MAIN RAGEBOT LOOP (ping independent prediction) ====
local function MainLoop()
    if not RageSettings.Enabled then return end
    frame = frame + 1
    if frame % 15 == 0 then CacheChar() end
    if not myChar or not myHRP then return end
    UpdatePlayerData()
    local now = tick()
    local hrp = myHRP
    local head = myHead
    
    if RageSettings.AutoFire and head then
        local isGrounded = true
        if myHum and hrp then
            if myHum.FloorMaterial == Enum.Material.Air then isGrounded = false end
            local vel = hrp.AssemblyLinearVelocity or hrp.Velocity
            if math.abs(vel.Y) > 2 then isGrounded = false end
        end
        if isGrounded and now - rbLast >= 2.5 then
            RayP.FilterDescendantsInstances = {myChar}
            local best = nil
            local bestScore = -9999
            local bulletOrigin = hrp.Position + Vector3.new(0, 1.5, 0)
            for i = 1, 8 do
                local d = playerData[i]
                if d and not d.team and d.dist < RageSettings.MaxDist then
                    -- No Air Check
                    if RageSettings.NoAirShot then
                        local enemyPos = d.r.Position
                        RayP.FilterDescendantsInstances = {d.c}
                        local groundRay = WS:Raycast(enemyPos, Vector3.new(0, -4, 0), RayP)
                        local isInAir = groundRay == nil
                        local enemyVelY = d.vel and d.vel.Y or 0
                        if isInAir or math.abs(enemyVelY) > 8 then continue end
                        RayP.FilterDescendantsInstances = {myChar}
                    end
                    local targets = {}
                    if RageSettings.AirShoot or RageSettings.SmartAim then
                        if d.head then table.insert(targets, {part = d.head, priority = 3}) end
                        if d.torso then table.insert(targets, {part = d.torso, priority = 2}) end
                        table.insert(targets, {part = d.r, priority = 1})
                    else
                        local tgt = RageSettings.Hitbox == "Head" and d.head or d.torso or d.r
                        if tgt then table.insert(targets, {part = tgt, priority = 1}) end
                    end
                    for _, tgtData in ipairs(targets) do
                        local tgt = tgtData.part
                        if not tgt then continue end
                        local vel = d.vel or d.r.AssemblyLinearVelocity
                        local playerName = d.p and d.p.Name or "Unknown"
                        local realPos = tgt.Position
                        local targetPos = realPos + vel * 0.15 -- ping-independent prediction (~150ms forward, static value)
                        local params = RaycastParams.new()
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        params.FilterDescendantsInstances = {myChar, d.c}
                        local directionVec = targetPos - bulletOrigin
                        local res = WS:Raycast(bulletOrigin, directionVec, params)
                        local canSee = (res == nil)
                        if RageSettings.WallCheck and not canSee then continue end
                        if canSee then
                            local score = (RageSettings.MaxDist - d.dist) + tgtData.priority * 100
                            if score > bestScore then
                                bestScore = score
                                best = {d = d, tgt = tgt, predictedPos = targetPos}
                            end
                            break
                        end
                    end
                end
            end
            if best then
                local fs = GetFireShot()
                if fs then
                    local pos = best.predictedPos or best.tgt.Position
                    local direction = (pos - bulletOrigin).Unit
                    pcall(function()
                        fs:FireServer(bulletOrigin, direction, best.tgt)
                    end)
                    rbLast = now
                    local targetName = best.d.p and best.d.p.Name or "Unknown"
                    Notification:Notify("info", "Ragebot", "Shot at " .. targetName)
                end
            end
        end
    end
    if frame > 1000 then frame = 0 end
end

-- ===== ENABLE & DISABLE RAGEBOT ====
local mainConn
local function StartRagebot()
    if mainConn then return end
    mainConn = RS.Heartbeat:Connect(MainLoop)
    Notification:Notify("success", "Ragebot", "Enabled!")
end
local function StopRagebot()
    if mainConn then 
        mainConn:Disconnect() 
        mainConn = nil 
        Notification:Notify("warning", "Ragebot", "Disabled!")
    end
end

-- ========== MENU ==========
-- Ragebot Tab
local RageSection = MainTab:AddSection('Ragebot Settings', "left")
RageSection:AddToggle('Enable Ragebot', false, function(val)
    RageSettings.Enabled = val
    if val then
        StartRagebot()
    else
        StopRagebot()
    end
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
RageSection:AddToggle('No Air Shot', true, function(val)
    RageSettings.NoAirShot = val
end)
RageSection:AddToggle('Smart Aim', true, function(val)
    RageSettings.SmartAim = val
end)
RageSection:AddToggle('Air Shoot', false, function(val)
    RageSettings.AirShoot = val
end)
RageSection:AddDropdown('Hitbox', {"Head", "Torso", "Body"}, "Head", function(val)
    RageSettings.Hitbox = val
end)
RageSection:AddSlider('Max Distance', 50, 1000, 500, function(val)
    RageSettings.MaxDist = val
end)
RageSection:AddSlider('Body Aim HP', 10, 100, 50, function(val)
    RageSettings.BodyAimHP = val
end)

-- VisualTab
local VisualsSection = VisualsTab:AddSection('Visual Settings', "left")
VisualsSection:AddToggle('Hotkey List', true, function(val)
    VisualSettings.HotkeyList = val
end)
VisualsSection:AddToggle('Time Display', true, function(val)
    VisualSettings.TimeDisplay = val
end)
VisualsSection:AddToggle('Hit Logger', true, function(val)
    VisualSettings.HitLogger = val
end)
VisualsSection:AddSlider('Max Logs', 4, 15, 8, function(val)
    VisualSettings.MaxLogs = val
end)
VisualsSection:AddToggle('Hitmarker', true, function(val)
    VisualSettings.Hitmarker = val
end)
VisualsSection:AddDropdown('HM Color', {"Green", "Red", "Blue", "White", "Yellow", "Purple", "Cyan"}, "Green", function(val)
    VisualSettings.HitmarkerColor = val
end)
VisualsSection:AddToggle('Kill Effect', true, function(val)
    VisualSettings.KillEffect = val
end)
VisualsSection:AddDropdown('KE Color', {"White", "Red", "Blue", "Green", "Yellow", "Purple", "Cyan"}, "White", function(val)
    VisualSettings.KillEffectColor = val
end)

-- Initialization
CacheChar()
Notification:Notify("info", "Arcanum Ragebot", "Loaded successfully!")
print("Arcanum Ragebot (night mode, cleaned visual, no misc, watermark removed, ping-independent ragebot)")
