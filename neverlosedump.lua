-- NEVERLOSE.RAGE v2.1 with Improved Ragebot, Highlights & Fast KillWait

local NEVERLOSE = loadstring(game:HttpGet("https://raw.githubusercontent.com/3345-c-a-t-s-u-s/NEVERLOSE-UI-Nightly/main/source.lua"))()
NEVERLOSE:Theme("original")

local Window = NEVERLOSE:AddWindow("NEVERLOSE", "dev:zxcsavaq")
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

-- UNINJECT SYSTEM
local uninjected = false
local function UninjectAll()
    if mainConn then mainConn:Disconnect() mainConn=nil end
    if ghostPeekConn then ghostPeekConn:Disconnect() ghostPeekConn=nil end
    Notification:Notify("warning", "neverlose.lua", "Script Uninjected!")
    Window:Close()
    for i,v in pairs(getconnections(RS.Heartbeat)) do
        if v.Function and debug.getinfo(v.Function).source:find("neverlose.lua") then
            v:Disconnect()
        end
    end
    uninjected = true
end
local UninjectSection = MainTab:AddSection('Uninject', "right")
UninjectSection:AddButton("Uninject Script", function()
    UninjectAll()
end)

-- Ragebot settings
local RageSettings = {
    Enabled = false,
    AutoFire = true,
    TeamCheck = true,
    WallCheck = true,
    NoAirShot = true,
    SmartAim = true,
    AirShoot = false,
    Hitbox = "Head",
    MaxDist = 1200,
    BodyAimHP = 35,
    -- Параметр 'MinVisibleTime' теперь игнорируется, всегда минимальное время ожидания 0.025!
    MinVisibleTime = 0.04,
    WaitForKillShot = true,
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

-- CHAMS SETTINGS + улучшения
local matOpts = {"Flat","Glossy","Crystal","Glass","Metallic","Wireframe"}
local chamsTargets = {"None","All Enemies","Allies","Everyone"}
local ChamsSettings = {
    Enabled = false,
    Material = "Flat",
    Color = Color3.fromRGB(32, 212, 236),
    Transparency = 0.2,
    ForSelf = true,
    TargetMode = "All Enemies"
}
local allChams = {}

local function MaterialHighlightProps(material)
    local t = {
        ["Flat"] = {FillTransparency=0.22, OutlineTransparency=0.32},
        ["Glossy"] = {FillTransparency=0.09, OutlineTransparency=0, OutlineColor=Color3.fromRGB(255,255,255)},
        ["Crystal"] = {FillTransparency=0.72, OutlineTransparency=0.13, OutlineColor=Color3.fromRGB(180,255,255)},
        ["Glass"] = {FillTransparency=0.84, OutlineTransparency=0.1, OutlineColor=Color3.fromRGB(220,255,255)},
        ["Metallic"] = {FillTransparency=0.17, OutlineTransparency=0, OutlineColor=Color3.fromRGB(180,180,200)},
        ["Wireframe"] = {FillTransparency=0.98, OutlineTransparency=0, OutlineColor=Color3.fromRGB(20,245,245)},
    }
    return t[material] or t["Flat"]
end

local function ShouldShowChams(plr)
    if ChamsSettings.TargetMode == "None" then
        return false
    elseif ChamsSettings.TargetMode == "Everyone" then
        return true
    elseif ChamsSettings.TargetMode == "Allies" then
        return (plr ~= LP) and LP.Team and plr.Team==LP.Team
    elseif ChamsSettings.TargetMode == "All Enemies" then
        return (plr ~= LP) and LP.Team and plr.Team~=LP.Team
    end
    return false
end

local function ClearChams()
    for _,high in ipairs(allChams) do
        if high and high.Parent then high:Destroy() end
    end
    allChams = {}
end

local function UpdateChams()
    ClearChams()
    if not ChamsSettings.Enabled then return end
    for _,plr in ipairs(Plrs:GetPlayers()) do
        if (ChamsSettings.ForSelf or plr ~= LP) and plr.Character and ShouldShowChams(plr) then
            local char = plr.Character
            local high = Instance.new("Highlight")
            high.Parent = char
            high.Adornee = char
            local props = MaterialHighlightProps(ChamsSettings.Material)
            for k,v in pairs(props) do pcall(function() high[k]=v end) end
            high.FillColor = ChamsSettings.Color
            high.OutlineColor = props.OutlineColor or ChamsSettings.Color
            high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            table.insert(allChams, high)
        end
    end
end

game:GetService("RunService").RenderStepped:Connect(UpdateChams)
game:GetService("Players").PlayerAdded:Connect(function() task.wait(1) UpdateChams() end)
game:GetService("Players").PlayerRemoving:Connect(function() task.wait(1) UpdateChams() end)

----------------------------------------------------------
-- ======= ПРОКАЧАННЫЙ RAGEBOT =======
----------------------------------------------------------
local playerData, playerDataTime = {}, 0
local myChar, myHRP, myHead, myHum, fireShot, fireShotTime = nil, nil, nil, nil, nil, 0
local rbLast, frame = 0, 0
local RayP = RaycastParams.new(); RayP.FilterType = Enum.RaycastFilterType.Exclude
local minKillWait = 0.025 -- примерно 1.5 тика, почти мгновенно, всегда такое, даже если setting
local function CacheChar()
    local c = LP.Character
    if c then
        myChar,myHRP = c,c:FindFirstChild("HumanoidRootPart")
        myHead,myHum = c:FindFirstChild("Head"),c:FindFirstChildOfClass("Humanoid")
    else myChar,myHRP,myHead,myHum = nil,nil,nil,nil end
end

local function IsVisible(from, target, ignore)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = ignore or {myChar}
    local dir = (target.Position-from).Unit * ((target.Position-from).Magnitude)
    local hit = WS:Raycast(from, dir, rayParams)
    return (not hit or hit.Instance:IsDescendantOf(target.Parent)), tick()
end

local function UpdatePlayerData()
    local myTeam = LP.Team
    playerData = {}
    for _,plr in ipairs(Plrs:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local char = plr.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 2 then
                local dist = (myHRP and hrp and (myHRP.Position - hrp.Position).Magnitude) or 9999
                local isEnemy = true
                if RageSettings.TeamCheck and myTeam and plr.Team == myTeam then
                    isEnemy = false
                end
                table.insert(playerData, {
                    plr = plr,
                    char = char,
                    hrp = hrp,
                    hum = hum,
                    isEnemy = isEnemy,
                    dist = dist,
                    lastVis = 0,
                })
            end
        end
    end
    table.sort(playerData, function(a,b) return a.dist < b.dist end)
end

local function GetTarget()
    if #playerData == 0 then return nil end
    local myPos = myHRP.Position
    for _,enemy in ipairs(playerData) do
        if not enemy.isEnemy then continue end
        local head = enemy.char:FindFirstChild("Head")
        if not head then continue end
        local velocity = (enemy.hrp.AssemblyLinearVelocity or Vector3.new())
        local distance = (myPos - enemy.hrp.Position).Magnitude
        local ping = 0.12 + math.clamp(distance/900,0,0.22)
        local predictedPos = head.Position + velocity * ping
        local tgtCheck = (distance < 20) and head.Position or predictedPos
        local canSee, seenTick = IsVisible(myPos + Vector3.new(0,1.1,0), head, {myChar, enemy.char})
        if not canSee then continue end
        local isGrounded = true
        if RageSettings.NoAirShot then
            local ground = WS:Raycast(enemy.hrp.Position, Vector3.new(0,-7,0), RaycastParams.new())
            if not ground or math.abs(velocity.Y) > 9 then isGrounded = false end
        end
        if not isGrounded then continue end
        -- микро-задержка на видимость (anti-miss)
        if enemy._lastSeenTick and (tick() - enemy._lastSeenTick) < minKillWait then continue end
        enemy._lastSeenTick = seenTick
        return enemy, tgtCheck
    end
    return nil
end

local function GetFireShot()
    local now = tick()
    if fireShot and fireShot.Parent and now-fireShotTime < 5 then return fireShot end
    CacheChar()
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

local function MainLoop()
    if uninjected or not RageSettings.Enabled then return end
    frame = frame + 1
    if frame%12==0 then CacheChar() end
    if not myChar or not myHRP then return end
    UpdatePlayerData()
    local myPos = myHRP.Position+Vector3.new(0,1.15,0)
    if RageSettings.AutoFire then
        local now = tick()
        if now - rbLast >= 0.035 then
            local target, shootPos = GetTarget()
            if target and shootPos then
                local fire = GetFireShot()
                if fire then
                    local dir = (shootPos - myPos).Unit
                    pcall(function()
                        fire:FireServer(myPos, dir, target.hrp)
                    end)
                    rbLast = now
                    Notification:Notify("info","Ragebot","Shot at "..(target.plr.Name or "Enemy"))
                end
            end
        end
    end
    if frame>900 then frame=0 end
end

local mainConn
local function StartRagebot()
    if mainConn then return end
    mainConn = RS.Heartbeat:Connect(MainLoop)
    Notification:Notify("success", "Ragebot", "Enabled!")
end
local function StopRagebot()
    if mainConn then mainConn:Disconnect(); mainConn=nil
        Notification:Notify("warning", "Ragebot", "Disabled!") end
end

----------------------------------------------------------
-- ========== GHOST, ANTIAIM, MENU ================
----------------------------------------------------------
local GhostSettings = {
    Enabled = false,
    TeleportDistance = 8,
    AttemptInterval = 0.18,
    TpDuration = 0.07,
    OnlyShootIfCanSee = true,
}
local ghostActive = false
local ghostPeekConn

local function GhostPeekLoop()
    if uninjected or not GhostSettings.Enabled then return end
    CacheChar(); UpdatePlayerData()
    local hrp = myHRP or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not hrp then return end
    local bulletOrigin = hrp.Position + Vector3.new(0,1.5,0)
    for i=1,#playerData do
        local d=playerData[i]
        if not d or d.team or d.dist>140 or not d.hrp then continue end
        local dir = (d.hrp.Position-bulletOrigin).Unit
        local tpPos = bulletOrigin + dir*GhostSettings.TeleportDistance
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {LP.Character, d.char}
        local canShoot = WS:Raycast(tpPos, (d.hrp.Position-tpPos), params) == nil
        if not canShoot and GhostSettings.OnlyShootIfCanSee then continue end
        local oldCF = hrp.CFrame
        hrp.CFrame = CFrame.new(tpPos, tpPos+dir)
        task.wait(GhostSettings.TpDuration)
        local fs = GetFireShot()
        if fs then
            pcall(function() fs:FireServer(tpPos, dir, d.hrp) end)
        end
        hrp.CFrame = oldCF
        Notification:Notify("info","Ghost Peek","Ghost shot at "..(d.plr.Name or "Target"))
        break
    end
end

local function StartGhostPeek()
    if ghostPeekConn then return end
    ghostActive = true
    ghostPeekConn = RS.Heartbeat:Connect(function()
        if not ghostActive then return end
        GhostPeekLoop()
        task.wait(GhostSettings.AttemptInterval)
    end)
    Notification:Notify("success", "Ghost Peek", "Enabled!")
end

local function StopGhostPeek()
    if ghostPeekConn then ghostPeekConn:Disconnect(); ghostPeekConn=nil end
    ghostActive = false
    Notification:Notify("warning", "Ghost Peek", "Disabled!")
end

local modes = {"Off", "Desync", "Jitter", "Spin", "Defensive"}
local AASettings = {
    Mode = "Off", Speed = 18, JitterAmount = 16, SpinSpeed = 14, Pitch = -60, Yaw = 180, RandStrength = 13
}
local lastAAStage, spinAngle, lastServerCF, lastSwitch = 0, 0, nil, tick()
local function setHeadDown(char, deg)
    local head = char:FindFirstChild("Head")
    if head then
        local pos = head.Position
        head.CFrame = CFrame.new(pos) * CFrame.Angles(math.rad(deg),0,0)
    end
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if torso then
        torso.CFrame = torso.CFrame * CFrame.Angles(math.rad(deg * 0.15), 0, 0)
    end
end
RS.Heartbeat:Connect(function()
    if AASettings.Mode == "Off" then return end
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    setHeadDown(char, AASettings.Pitch)
    if AASettings.Mode == "Desync" then
        local t = tick()
        if lastAAStage == 0 then
            lastServerCF = hrp.CFrame
            local offset = Vector3.new(
                math.random(-AASettings.Speed, AASettings.Speed),
                0,
                math.random(-AASettings.Speed, AASettings.Speed)
            )
            local randomYaw = math.rad(math.random(-AASettings.Yaw, AASettings.Yaw))
            hrp.CFrame = hrp.CFrame * CFrame.new(offset) * CFrame.Angles(0, randomYaw, 0)
            lastSwitch = t
            lastAAStage = 1
        elseif lastAAStage == 1 and t - lastSwitch > 0.08 then
            if lastServerCF then hrp.CFrame = lastServerCF end
            lastSwitch = t
            lastAAStage = 2
        elseif lastAAStage == 2 and t - lastSwitch > 0.12 then
            lastAAStage = 0
        end
    elseif AASettings.Mode == "Jitter" then
        local offset = Vector3.new(
            math.random(-AASettings.JitterAmount, AASettings.JitterAmount),
            math.random(-AASettings.JitterAmount//2, AASettings.JitterAmount//2),
            math.random(-AASettings.JitterAmount, AASettings.JitterAmount)
        )
        local jitterYaw = math.rad(math.random(-AASettings.Yaw, AASettings.Yaw))
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, jitterYaw, 0) * CFrame.new(offset)
        lastServerCF = hrp.CFrame
    elseif AASettings.Mode == "Spin" then
        spinAngle = (spinAngle + AASettings.SpinSpeed)%360
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0)
        lastServerCF = hrp.CFrame
    elseif AASettings.Mode == "Defensive" then
        local jumpOffset = Vector3.new(
            math.random(-AASettings.RandStrength, AASettings.RandStrength),
            math.random(2,7),
            math.random(-AASettings.RandStrength, AASettings.RandStrength)
        )
        local randomYaw = math.rad(math.random(-AASettings.Yaw, AASettings.Yaw))
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, randomYaw, 0) * CFrame.new(jumpOffset)
        lastServerCF = hrp.CFrame
    end
end)

------------------ МЕНЮ ---------------------
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

local GhostSection = GhostTab:AddSection("Ghost Peek", "left")
GhostSection:AddToggle("Ghost Peek Enabled", false, function(val)
    GhostSettings.Enabled = val
    if val then StartGhostPeek() else StopGhostPeek() end
end)
GhostSection:AddSlider("TP Distance", 2, 18, 8, function(val)
    GhostSettings.TeleportDistance = val
end)
GhostSection:AddSlider("TP Duration", 0.02, 0.25, 0.07, function(val)
    GhostSettings.TpDuration = val
end)
GhostSection:AddSlider("Attempt Interval", 0.07, 0.7, 0.18, function(val)
    GhostSettings.AttemptInterval = val
end)
GhostSection:AddToggle("Only Shoot If LOS", true, function(val)
    GhostSettings.OnlyShootIfCanSee = val
end)

local VisualsSection = VisualsTab:AddSection('Visual Settings', "left")
VisualsSection:AddDropdown("Player Chams Target", chamsTargets, "All Enemies", function(val)
    ChamsSettings.TargetMode = val
    UpdateChams()
end)
VisualsSection:AddToggle('Enable Chams', false, function(val)
    ChamsSettings.Enabled = val
    UpdateChams()
end)
VisualsSection:AddDropdown('Chams Material', matOpts, "Flat", function(val)
    ChamsSettings.Material = val
    UpdateChams()
end)
VisualsSection:AddColorpicker("Chams Color", ChamsSettings.Color, function(val)
    ChamsSettings.Color = val
    UpdateChams()
end)
VisualsSection:AddSlider('Chams Transparency', 0, 1, 0.2, function(val)
    ChamsSettings.Transparency = val
    UpdateChams()
end)
VisualsSection:AddToggle("Chams For Self", true, function(val)
    ChamsSettings.ForSelf = val
    UpdateChams()
end)
VisualsSection:AddToggle('Hotkey List', true, function(val) VisualSettings.HotkeyList = val end)
VisualsSection:AddToggle('Time Display', true, function(val) VisualSettings.TimeDisplay = val end)
VisualsSection:AddToggle('Hit Logger', true, function(val) VisualSettings.HitLogger = val end)
VisualsSection:AddSlider('Max Logs', 4, 15, 8, function(val) VisualSettings.MaxLogs = val end)
VisualsSection:AddToggle('Hitmarker', true, function(val) VisualSettings.Hitmarker = val end)
VisualsSection:AddDropdown('HM Color', {"Green", "Red", "Blue", "White", "Yellow", "Purple", "Cyan"}, "Green", function(val) VisualSettings.HitmarkerColor = val end)
VisualsSection:AddToggle('Kill Effect', true, function(val) VisualSettings.KillEffect = val end)
VisualsSection:AddDropdown('KE Color', {"White", "Red", "Blue", "Green", "Yellow", "Purple", "Cyan"}, "White", function(val) VisualSettings.KillEffectColor = val end)

CacheChar()
Notification:Notify("info", "neverlose.lua", "Loaded! (Rage, Chams, Ghost Peek, Uninject)")
print("neverlose.lua (rage v2.1, fast killwait, full chams, ghost peek, uninject, anti-aim)")
