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
    MinVisibleTime = 0.03,
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

-- CHAMS SETTINGS
local ChamsSettings = {
    Enabled = false,
    Material = "Flat",
    Color = Color3.fromRGB(32, 212, 236),
    Transparency = 0.2,
    ForSelf = true,
}
local allChams = {}
local materialMap = {
    ["Flat"] = Enum.Material.SmoothPlastic,
    ["Glossy"] = Enum.Material.Neon,
    ["Crystal"] = Enum.Material.ForceField,
    ["Glass"] = Enum.Material.Glass,
    ["Metallic"] = Enum.Material.Metal,
    ["Wireframe"] = Enum.Material.Foil,
}

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

local function UpdateChams()
    ClearChams()
    if not ChamsSettings.Enabled then return end
    for _,plr in ipairs(game:GetService("Players"):GetPlayers()) do
        if (ChamsSettings.ForSelf or plr ~= LP) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local chamsList = {}
            for _,part in ipairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Transparency < 0.99 and part.Name ~= "HumanoidRootPart" then
                    local adorn = Instance.new("BoxHandleAdornment")
                    adorn.Adornee = part
                    adorn.AlwaysOnTop = true
                    adorn.ZIndex = 10
                    adorn.Size = part.Size + Vector3.new(0.08,0.08,0.08)
                    adorn.Color3 = ChamsSettings.Color
                    adorn.Transparency = ChamsSettings.Transparency
                    adorn.Parent = part
                    adorn.Name = "__Chams"
                    table.insert(chamsList, adorn)
                    part.Material = materialMap[ChamsSettings.Material] or Enum.Material.SmoothPlastic
                end
            end
            allChams[plr.Character] = chamsList
        end
    end
end

game:GetService("RunService").RenderStepped:Connect(UpdateChams)
game:GetService("Players").PlayerAdded:Connect(function() task.wait(1) UpdateChams() end)
game:GetService("Players").PlayerRemoving:Connect(function() task.wait(1) UpdateChams() end)

-- GHOST PEEK
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
        if not d or d.team or d.dist>140 or not d.r then continue end
        local dir = (d.r.Position-bulletOrigin).Unit
        local tpPos = bulletOrigin + dir*GhostSettings.TeleportDistance
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {LP.Character, d.c}
        local canShoot = WS:Raycast(tpPos, (d.r.Position-tpPos), params) == nil
        if not canShoot and GhostSettings.OnlyShootIfCanSee then continue end
        local oldCF = hrp.CFrame
        hrp.CFrame = CFrame.new(tpPos, tpPos+dir)
        wait(GhostSettings.TpDuration)
        local fs = GetFireShot()
        if fs then
            pcall(function() fs:FireServer(tpPos, dir, d.r) end)
        end
        hrp.CFrame = oldCF
        Notification:Notify("info","Ghost Peek","Ghost shot at "..(d.p.Name or "Target"))
        break
    end
end
local function StartGhostPeek()
    if ghostPeekConn then return end
    ghostActive = true
    ghostPeekConn = RS.Heartbeat:Connect(function()
        if not ghostActive then return end
        GhostPeekLoop()
        wait(GhostSettings.AttemptInterval)
    end)
    Notification:Notify("success", "Ghost Peek", "Enabled!")
end
local function StopGhostPeek()
    if ghostPeekConn then ghostPeekConn:Disconnect(); ghostPeekConn=nil end
    ghostActive = false
    Notification:Notify("warning", "Ghost Peek", "Disabled!")
end

-- ANTIAIM (как раньше, не вносилось)
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

-- RAGEBOT (смарт логика и prediction, улучшено)
local playerData, playerDataTime = {}, 0
local myChar, myHRP, myHead, myHum, fireShot, fireShotTime = nil, nil, nil, nil, nil, 0
local rbLast, frame = 0, 0
local RayP = RaycastParams.new(); RayP.FilterType = Enum.RaycastFilterType.Exclude
local function CacheChar()
    local c = LP.Character
    if c then
        myChar,myHRP = c,c:FindFirstChild("HumanoidRootPart")
        myHead,myHum = c:FindFirstChild("Head"),c:FindFirstChildOfClass("Humanoid")
    else myChar,myHRP,myHead,myHum = nil,nil,nil,nil end
end

local function UpdatePlayerData()
    local now = tick()
    if now-playerDataTime < 0.2 then return end
    playerDataTime = now
    if not myHRP then return end
    local myPos = myHRP.Position
    local myTeam,myColor = LP.Team,LP.TeamColor
    for i=1,16 do playerData[i]=nil end
    local count = 0
    for _,p in ipairs(Plrs:GetPlayers()) do
        if p~=LP and p.Character then
            local c,h,r = p.Character, p.Character:FindFirstChild("Humanoid"), p.Character:FindFirstChild("HumanoidRootPart")
            if h and h.Health > 0 and r then
                local dist = (myPos-r.Position).Magnitude
                if dist < 2000 then
                    count = count + 1
                    local isTeam = myTeam and (p.Team==myTeam or p.TeamColor==myColor)
                    playerData[count] = {
                        p=p, c=c, h=h, r=r,
                        head=c:FindFirstChild("Head"),
                        torso=c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"),
                        dist=dist, team=isTeam,
                        vel=r.AssemblyLinearVelocity,
                        visibleTick=nil,
                        canWallShot=nil,
                    }
                end
            end
        end
    end
    for i=2,count do
        local key = playerData[i]; local j = i-1
        while j >= 1 and playerData[j] and playerData[j].dist > key.dist do
            playerData[j+1]=playerData[j]; j=j-1
        end
        playerData[j+1]=key
    end
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
                    fireShot,fireShotTime = fs,now; return fs
                end
            end
        end
    end
    return nil
end

local function MainLoop()
    if uninjected or not RageSettings.Enabled then return end
    frame = frame + 1
    if frame%15==0 then CacheChar() end
    if not myChar or not myHRP then return end
    UpdatePlayerData()
    local now, hrp, head = tick(), myHRP, myHead

    if RageSettings.AutoFire and head then
        local isGrounded = true
        if myHum and hrp then
            if myHum.FloorMaterial == Enum.Material.Air then isGrounded = false end
            local vel = hrp.AssemblyLinearVelocity or hrp.Velocity
            if math.abs(vel.Y)>2 then isGrounded=false end
        end
        if isGrounded and now-rbLast >= 0.035 then
            RayP.FilterDescendantsInstances={myChar}
            local best, bestScore = nil, -9999
            local bulletOrigin = hrp.Position + Vector3.new(0,1.5,0)
            for i=1,#playerData do
                local d = playerData[i]
                if not d or d.team or d.dist>RageSettings.MaxDist then continue end
                if RageSettings.NoAirShot then
                    RayP.FilterDescendantsInstances={d.c}
                    local groundRay=WS:Raycast(d.r.Position,Vector3.new(0,-5,0),RayP)
                    RayP.FilterDescendantsInstances={myChar}
                    if not groundRay or (d.vel and math.abs(d.vel.Y)>8) then continue end
                end
                local targets={}
                if RageSettings.SmartAim or RageSettings.AirShoot then
                    if d.head then table.insert(targets,{part=d.head,priority=3}) end
                    if d.torso then table.insert(targets,{part=d.torso,priority=2}) end
                    if d.r then table.insert(targets,{part=d.r,priority=1}) end
                else
                    local tgt = RageSettings.Hitbox=="Head" and d.head or d.torso or d.r
                    if tgt then table.insert(targets,{part=tgt,priority=1}) end
                end
                for _,tgtData in ipairs(targets) do
                    local tgt = tgtData.part
                    if not tgt then continue end
                    local vel = d.vel or d.r.AssemblyLinearVelocity
                    local basePred = 0.11 + math.clamp(d.dist/500,0,0.19)
                    local targetPos = tgt.Position + vel * basePred
                    if d.dist<44 then targetPos=tgt.Position end
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = {myChar, d.c}
                    local directionVec = (targetPos-bulletOrigin)
                    local res = WS:Raycast(bulletOrigin, directionVec, params)
                    local canSee = (res==nil)
                    if RageSettings.WallCheck and not canSee and d.dist>32 then continue end
                    if d.visibleTick and now-d.visibleTick < RageSettings.MinVisibleTime then continue end
                    d.visibleTick = canSee and now or nil
                    local hpBonus = (d.h and d.h.Health and d.h.Health<RageSettings.BodyAimHP) and 50 or 0
                    local score = (RageSettings.MaxDist-d.dist) + tgtData.priority*120 + hpBonus
                    if score>bestScore then
                        bestScore=score; best={d=d,tgt=tgt,predictedPos=targetPos}
                    end
                end
            end
            if best then
                if not RageSettings.WaitForKillShot or best.d.visibleTick and now-best.d.visibleTick>=RageSettings.MinVisibleTime then
                    local fs = GetFireShot()
                    if fs then
                        local pos = best.predictedPos or best.tgt.Position
                        local direction = (pos-bulletOrigin).Unit
                        pcall(function() fs:FireServer(bulletOrigin,direction,best.tgt) end)
                        rbLast = now
                        local targetName = best.d.p and best.d.p.Name or "Unknown"
                        Notification:Notify("info", "Ragebot", "Shot at "..targetName)
                    end
                end
            end
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
    if mainConn then mainConn:Disconnect(); mainConn=nil
        Notification:Notify("warning", "Ragebot", "Disabled!") end
end

-- MENU
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

local matOpts = {"Flat","Glossy","Crystal","Glass","Metallic","Wireframe"}
local VisualsSection = VisualsTab:AddSection('Visual Settings', "left")
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
print("neverlose.lua (rage v2, full chams, ghost peek, uninject, anti-aim)")
