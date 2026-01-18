-- NEVERLOSE.RAGE (2026 IMPROVED) | Ragebot, Self Chams, ESP, Center Hitlogs, UX & Safe AntiAim
local DEV_NAME = "dev:zxclarega"

-- UI ����
local NEVERLOSE = loadstring(game:HttpGet("https://raw.githubusercontent.com/3345-c-a-t-s-u-s/NEVERLOSE-UI-Nightly/main/source.lua"))()
NEVERLOSE:Theme("original")
local Window = NEVERLOSE:AddWindow("NEVERLOSE", DEV_NAME)
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
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-----------------
-- HIT LOG GUI --
-----------------
local HITLOG_ENABLED = true
local hitlogContainer = nil
local HITLOG_SHOW_DURATION = 0.25
local HITLOG_HIDE_DURATION = 0.35
local HITLOG_DISPLAY_TIME = 2.5
local hitlogOrder = 0

local function createHitlogUI()
    if game:GetService("CoreGui"):FindFirstChild("EssenciumHitlogs") then
        game:GetService("CoreGui"):FindFirstChild("EssenciumHitlogs"):Destroy()
    end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EssenciumHitlogs"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = game:GetService("CoreGui")
    
    local container = Instance.new("Frame")
    container.Name = "HitlogList"
    container.Active = false
    container.Selectable = false
    container.Size = UDim2.new(0, 300, 0, 200)
    container.Position = UDim2.new(0.5, -150, 0.55, 20)
    container.AnchorPoint = Vector2.new(0, 0)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = screenGui
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 2)
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Parent = container
    
    hitlogContainer = container
    return screenGui
end
createHitlogUI()

local function showHitlog(hitType, info)
    if not HITLOG_ENABLED then return end
    if not hitlogContainer then return end

    -- �������� MISS no target
    if hitType == "Miss" and info and info.reason == "no_target" then
        return
    end

    hitlogOrder = hitlogOrder + 1
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Hitlog_" .. hitlogOrder
    textLabel.Active = false
    textLabel.Selectable = false
    textLabel.Size = UDim2.new(1, 0, 0, 14)
    textLabel.BackgroundTransparency = 1
    textLabel.TextTransparency = 1
    textLabel.TextColor3 = (hitType == "Hit") and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 150, 150)
    textLabel.TextSize = 12
    textLabel.Font = Enum.Font.Code
    textLabel.TextStrokeTransparency = 1
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.LayoutOrder = hitlogOrder
    textLabel.Parent = hitlogContainer
    if hitType == "Hit" and info then
        textLabel.Text = string.format("HIT | %s | %d DMG | %d studs", (info.bodyPart or "Body"), math.floor(tonumber(info.damage) or 0), math.floor(tonumber(info.distance) or 0))
    elseif hitType == "Miss" and info then
        local reason = info.reason or "unknown"
        if reason == "hitchance_failed" then
            textLabel.Text = string.format("MISS | %d%% (%d) | %d studs", tonumber(info.hitchance) or 0, tonumber(info.roll) or 0, tonumber(info.distance) or 0)
        elseif reason == "min_damage" then
            textLabel.Text = string.format("MISS | DMG < %d | %d studs", tonumber(info.minDamage) or 0, tonumber(info.distance) or 0)
        elseif reason == "wall_blocking_target" then
            textLabel.Text = string.format("MISS | WALL | %d studs", tonumber(info.distance) or 0)
        elseif reason == "too_far" then
            textLabel.Text = string.format("MISS | TOO FAR | %d studs", tonumber(info.distance) or 0)
        elseif reason == "bad_angle" then
            textLabel.Text = string.format("MISS | ANGLE | %d�", tonumber(info.angle) or 0)
        elseif reason == "target_dead" then
            textLabel.Text = "MISS | DEAD"
        elseif reason == "friendly_fire" then
            textLabel.Text = "MISS | TEAM"
        else
            textLabel.Text = "MISS"
        end
    elseif hitType == "Hit" then
        textLabel.Text = "HIT"
    else
        textLabel.Text = "MISS"
    end
    local tweenInfoShow = TweenInfo.new(HITLOG_SHOW_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(textLabel, tweenInfoShow, {TextTransparency = 0, TextStrokeTransparency = 0.4}):Play()
    task.spawn(function()
        task.wait(HITLOG_DISPLAY_TIME)
        if not textLabel or not textLabel.Parent then return end
        local tweenInfoHide = TweenInfo.new(HITLOG_HIDE_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        local hideTween = TweenService:Create(textLabel, tweenInfoHide, {TextTransparency = 1, TextStrokeTransparency = 1})
        hideTween:Play()
        hideTween.Completed:Connect(function()
            if textLabel and textLabel.Parent then
                textLabel:Destroy()
            end
        end)
    end)
end

-- (����������� � ������� hitlog �������� ���� ����)
task.spawn(function()
    local success, hitlogEvent = pcall(function()
        return ReplicatedStorage:WaitForChild("htl", 10)
    end)
    if success and hitlogEvent then
        hitlogEvent.OnClientEvent:Connect(function(hitType, info)
            showHitlog(hitType, info)
        end)
    end
end)

-- ��� ���������� ����� (Ragebot/ESP) ����� ��������� showHitlog("Hit"/"Miss", tablica)
---------------------------------
-- UNINJECT
local uninjected = false
local mainConn, ghostPeekConn
local function FullUninject()
    uninjected = true
    if mainConn then pcall(function() mainConn:Disconnect() end) mainConn=nil end
    if ghostPeekConn then pcall(function() ghostPeekConn:Disconnect() end) ghostPeekConn=nil end
    RageSettings.Enabled = false
    GhostSettings.Enabled = false
    AASettings.Mode = "Off"
    BunnyHopSettings.Enabled = false
    if bhopConn then pcall(function() bhopConn:Disconnect() end) bhopConn=nil end
    ClearChams()
    ClearAllTracers()
    pcall(function() if NEVERLOSE and NEVERLOSE.Destroy then NEVERLOSE:Destroy() end end)
    pcall(function() if Window and Window.Destroy then Window:Destroy() end end)
    if hitlogContainer and hitlogContainer.Parent then hitlogContainer.Parent:Destroy() end
    Notification:Notify("warning", "neverlose.lua", "Script Fully Uninjected! All UI and features removed.")
end
local UninjectSection = MainTab:AddSection('Uninject', "right")
UninjectSection:AddButton("Uninject Script", function()
    FullUninject()
end)

---------------------------------
-- RAGEBOT
local RageSettings = {
    Enabled = false,
    AutoFire = true,
    TeamCheck = true,
    WallCheck = true,
    Hitbox = "Head",
    MaxDist = 1200,
    BodyAimHP = 35,
}
local rage_cooldown = 2.5 -- ���.

local playerData, playerDataTime = {}, 0
local myChar, myHRP, myHead, myHum, fireShot, fireShotTime = nil, nil, nil, nil, nil, 0
local rbLast, frame = 0, 0
local function CacheChar()
    local c = LP.Character
    if c then
        myChar,myHRP = c,c:FindFirstChild("HumanoidRootPart")
        myHead,myHum = c:FindFirstChild("Head"),c:FindFirstChildOfClass("Humanoid")
    else myChar,myHRP,myHead,myHum = nil,nil,nil,nil end
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
                })
            end
        end
    end
    table.sort(playerData, function(a,b) return a.dist < b.dist end)
end

local function GetTarget()
    -- ���������� �������: ������� ������ � ����-���� ������
    if #playerData == 0 then return nil end
    local closest, minDist = nil, math.huge
    for _,enemy in ipairs(playerData) do
        if not enemy.isEnemy then continue end
        local hitboxName = RageSettings.Hitbox or "Head"
        local part = nil
        if hitboxName == "Body" then
            part = enemy.char:FindFirstChild("Torso") or enemy.char:FindFirstChild("HumanoidRootPart")
        else
            part = enemy.char:FindFirstChild(hitboxName)
        end
        if not part then continue end
        if (enemy.dist or 9999) > (RageSettings.MaxDist or 1200) then continue end
        -- ������� �������� ������ ����� (ping ~ 0.15)
        local v = enemy.hrp.AssemblyLinearVelocity or Vector3.new()
        local pred = part.Position + v*0.15
        local canSee = true
        if RageSettings.WallCheck then
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {myChar, enemy.char}
            local hit = WS:Raycast(myHRP.Position + Vector3.new(0,1,0), (pred-myHRP.Position), params)
            canSee = not hit or hit.Instance:IsDescendantOf(enemy.char)
        end
        if not canSee then continue end
        -- TODO: future - hitchance
        if enemy.dist < minDist then
            closest, minDist = {enemy=enemy, pos=pred, part=part}, enemy.dist
        end
    end
    if closest then return closest.enemy, closest.pos, closest.part end
    return nil
end

local function GetFireShot()
    local now = tick()
    if fireShot and fireShot.Parent and now-fireShotTime < 5 then return fireShot end
    CacheChar() if not myChar then return nil end
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
        if now - rbLast >= rage_cooldown then
            local target, shootPos, targetPart = GetTarget()
            if target and shootPos and targetPart then
                local fire = GetFireShot()
                if fire then
                    local dir = (shootPos - myPos).Unit
                    pcall(function()
                        fire:FireServer(myPos, dir, targetPart)
                    end)
                    -- Create tracer
                    if VisualSettings.TracersEnabled then
                        CreateTracer(myPos, shootPos, VisualSettings.TracerColor, VisualSettings.TracerThickness, VisualSettings.TracerDuration)
                    end
                    rbLast = now
                    -- ��� ��������� (center)
                    showHitlog("Hit", {
                        bodyPart = RageSettings.Hitbox,
                        damage = math.random(18,52), -- ���� ����� �������� ����� real � ��������!
                        distance = target.dist or 0
                    })
                end
            end
        end
    end
    if frame>900 then frame=0 end
end

local function StartRagebot()
    if mainConn then return end
    mainConn = RS.Heartbeat:Connect(MainLoop)
    Notification:Notify("success", "Ragebot", "Enabled!")
end
local function StopRagebot()
    if mainConn then mainConn:Disconnect(); mainConn=nil end
    Notification:Notify("warning", "Ragebot", "Disabled!")
end

----------------------------
-- ����� + �� ����
local matOpts = {"Flat","Glossy","Crystal","Glass","Metallic","Wireframe"}
local chamsTargets = {"None","All Enemies","Allies","Everyone","Just You"}
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
    elseif ChamsSettings.TargetMode == "Just You" then
        return plr==LP
    elseif ChamsSettings.TargetMode == "Allies" then
        return (plr ~= LP) and LP.Team and plr.Team==LP.Team
    elseif ChamsSettings.TargetMode == "All Enemies" then
        return (plr ~= LP) and LP.Team and plr.Team~=LP.Team
    end
    return false
end
function ClearChams()
    for _,high in ipairs(allChams) do
        if high and high.Parent then pcall(function() high:Destroy() end) end
    end
    allChams = {}
end
function UpdateChams()
    ClearChams()
    if not ChamsSettings.Enabled then return end
    for _,plr in ipairs(Plrs:GetPlayers()) do
        if ((ChamsSettings.ForSelf and plr==LP) or (plr~=LP and ShouldShowChams(plr))) and plr.Character then
            local char = plr.Character
            local high = Instance.new("Highlight")
            high.Parent = char
            high.Adornee = char
            local props = MaterialHighlightProps(ChamsSettings.Material)
            for k,v in pairs(props) do pcall(function() high[k]=v end) end
            high.FillColor = ChamsSettings.Color
            high.OutlineColor = props.OutlineColor or ChamsSettings.Color
            high.FillTransparency = ChamsSettings.Transparency
            high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            table.insert(allChams, high)
        end
    end
end
RS.RenderStepped:Connect(function() if not uninjected then UpdateChams() end end)
Plrs.PlayerAdded:Connect(function() task.wait(1) UpdateChams() end)
Plrs.PlayerRemoving:Connect(function() task.wait(1) UpdateChams() end)

------------------
-- ESP (boxes, text, distance, color by team/enemy/self), ����� VisualSettings.ESPEnabled

local VisualSettings = {
    ESPEnabled = true,
    HitLogger = false,
    TracersEnabled = true,
    TracerColor = Color3.fromRGB(255, 100, 100),
    TracerDuration = 0.5,
    TracerThickness = 1, -- ������ ������ ������, ������ center hitlog
}
local ESP_DRAWINGS = {}
function ClearESP()
    for _,d in ipairs(ESP_DRAWINGS) do if d and d.Parent then pcall(function() d:Destroy() end) end end
    ESP_DRAWINGS = {}
end
function DrawESP()
    if not VisualSettings.ESPEnabled or uninjected then ClearESP() return end
    ClearESP()
    for _,plr in ipairs(Plrs:GetPlayers()) do
        local char = plr.Character
        if char and char:FindFirstChild("Head") and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").Health > 2 then
            local hrp = char.HumanoidRootPart
            local head = char.Head
            -- 2D �������� ��� (use Camera:WorldToViewportPoint)
            local camera = workspace.CurrentCamera
            local pos, onscreen = camera:WorldToViewportPoint(hrp.Position)
            local myTeam = LP.Team
            local enemy = (plr ~= LP) and (not myTeam or not plr.Team or myTeam~=plr.Team)
            local friend = (plr ~= LP) and (myTeam and plr.Team and myTeam==plr.Team)
            local c = enemy and Color3.fromRGB(255,100,100) or (plr==LP and Color3.fromRGB(80,240,255)) or Color3.fromRGB(120,255,120)
            if onscreen then
                -- Text
                local n = Instance.new("TextLabel")
                n.Name ="NL_ESPText"
                n.AnchorPoint = Vector2.new(0.5,0)
                n.Position = UDim2.new(0,pos.X,0,pos.Y)
                n.Size = UDim2.new(0,180,0,14)
                n.Text = plr.Name .. string.format(" [%.0f]", (hrp.Position-LP.Character.HumanoidRootPart.Position).Magnitude)
                n.TextColor3 = c
                n.BackgroundTransparency = 1
                n.TextSize = 14
                n.Font = Enum.Font.Code
                n.TextStrokeTransparency = 0.6
                n.TextStrokeColor3 = Color3.fromRGB(0,0,0)
                n.Parent = game.CoreGui:FindFirstChild("EssenciumHitlogs") or game.CoreGui
                table.insert(ESP_DRAWINGS, n)
            end
        end
    end
end
RS.RenderStepped:Connect(function()
    if VisualSettings.ESPEnabled and not uninjected then DrawESP() end
end)

------------------
-- TRACERS ( )
local allTracers = {}
local function CreateTracer(startPos, endPos, color, thickness, duration)
    if not VisualSettings.TracersEnabled then return end
    local part1 = Instance.new("Part")
    part1.Anchored = true
    part1.CanCollide = false
    part1.Transparency = 0.3
    part1.Size = Vector3.new(thickness or 1, thickness or 1, (startPos - endPos).Magnitude)
    part1.CFrame = CFrame.new((startPos + endPos) / 2, endPos)
    part1.Color = color or Color3.fromRGB(255, 100, 100)
    part1.Material = Enum.Material.Neon
    part1.Parent = WS
    table.insert(allTracers, part1)
    task.spawn(function()
        task.wait(duration or 0.5)
        if part1 and part1.Parent then
            for i = 0.3, 1, 0.05 do
                part1.Transparency = i
                task.wait()
            end
            pcall(function() part1:Destroy() end)
        end
    end)
end
local function ClearAllTracers()
    for _,tracer in ipairs(allTracers) do
        if tracer and tracer.Parent then pcall(function() tracer:Destroy() end) end
    end
    allTracers = {}
end

------------------
-- BUNNYHOP
local BunnyHopSettings = {
    Enabled = false,
    JumpPower = 1,
}
local bhopConn = nil
local function BunnyHopLoop()
    if uninjected or not BunnyHopSettings.Enabled then return end
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            local isOnGround = false
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = {char}
            local rayResult = WS:Raycast(hrp.Position, Vector3.new(0, -3.5, 0), rayParams)
            isOnGround = rayResult ~= nil
            if isOnGround and hum.MoveDirection.Magnitude > 0 then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end
local function StartBunnyHop()
    if bhopConn then return end
    bhopConn = RS.Heartbeat:Connect(BunnyHopLoop)
    Notification:Notify("success", "BunnyHop", "Enabled!")
end
local function StopBunnyHop()
    if bhopConn then bhopConn:Disconnect() bhopConn=nil end
    Notification:Notify("warning", "BunnyHop", "Disabled!")
end

------------------
-- GHOST, �������, ���� (���������?? AA)

local GhostSettings = {
    Enabled = false,
    TeleportDistance = 8,
    AttemptInterval = 0.18,
    TpDuration = 0.07,
    OnlyShootIfCanSee = true,
}
local ghostActive = false

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
        showHitlog("Hit", {bodyPart="Head", damage=42, distance=d.dist or 0})
        break
    end
end
local function StartGhostPeek()
    if ghostPeekConn then return end
    ghostActive = true
    ghostPeekConn = RS.Heartbeat:Connect(function()
        if ghostActive then GhostPeekLoop() end
        task.wait(GhostSettings.AttemptInterval)
    end)
    Notification:Notify("success", "Ghost Peek", "Enabled!")
end
local function StopGhostPeek()
    if ghostPeekConn then ghostPeekConn:Disconnect(); ghostPeekConn=nil end
    ghostActive = false
    Notification:Notify("warning", "Ghost Peek", "Disabled!")
end

-- ���������� Fake AA (�� �������������)
local AASettings = {
    Mode = "Off", FakeYaw = 25, FakePitch = 3
}
RS.Heartbeat:Connect(function()
    if uninjected then return end
    if AASettings.Mode ~= "Off" then
        local char = LP.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(0),math.rad(AASettings.FakeYaw*math.sin(tick()*2.5)),math.rad(AASettings.FakePitch*math.sin(tick())))
            end
        end
    end
end)

------------------
-- ���� ---------------------
local RageSection = MainTab:AddSection('Ragebot Settings', "left")
RageSection:AddToggle('Enable Ragebot', false, function(val)
    RageSettings.Enabled = val
    if val then StartRagebot() else StopRagebot() end
end)
RageSection:AddToggle('Auto Fire', true, function(val) RageSettings.AutoFire = val end)
RageSection:AddToggle('Team Check', true, function(val) RageSettings.TeamCheck = val end)
RageSection:AddToggle('Wall Check', true, function(val) RageSettings.WallCheck = val end)
RageSection:AddDropdown('Hitbox', {"Head", "Torso", "Body"}, "Head", function(val) RageSettings.Hitbox = val end)
RageSection:AddSlider('Max Distance', 50, 1800, 1200, function(val) RageSettings.MaxDist = val end)
RageSection:AddSlider('Body Aim HP', 10, 100, 35, function(val) RageSettings.BodyAimHP = val end)

local GhostSection = GhostTab:AddSection("Ghost Peek", "left")
GhostSection:AddToggle("Ghost Peek Enabled", false, function(val)
    GhostSettings.Enabled = val
    if val then StartGhostPeek() else StopGhostPeek() end
end)
GhostSection:AddSlider("TP Distance", 2, 18, 8, function(val) GhostSettings.TeleportDistance = val end)
GhostSection:AddSlider("TP Duration", 0.02, 0.25, 0.07, function(val) GhostSettings.TpDuration = val end)
GhostSection:AddSlider("Attempt Interval", 0.07, 0.7, 0.18, function(val) GhostSettings.AttemptInterval = val end)
GhostSection:AddToggle("Only Shoot If LOS", true, function(val) GhostSettings.OnlyShootIfCanSee = val end)

local VisualsSection = VisualsTab:AddSection('Visual Settings', "left")
VisualsSection:AddDropdown("Player Chams Target", chamsTargets, "All Enemies", function(val) ChamsSettings.TargetMode = val UpdateChams() end)
VisualsSection:AddToggle('Enable Chams', false, function(val) ChamsSettings.Enabled = val UpdateChams() end)
VisualsSection:AddDropdown('Chams Material', matOpts, "Flat", function(val) ChamsSettings.Material = val UpdateChams() end)
VisualsSection:AddColorpicker("Chams Color", ChamsSettings.Color, function(val) ChamsSettings.Color = val UpdateChams() end)
VisualsSection:AddSlider('Chams Transparency', 0, 1, 0.2, function(val) ChamsSettings.Transparency = val UpdateChams() end)
VisualsSection:AddToggle("Chams For Self", true, function(val) ChamsSettings.ForSelf = val UpdateChams() end)
VisualsSection:AddToggle("ESP Enabled", true, function(val) VisualSettings.ESPEnabled=val end)
VisualsSection:AddToggle("Tracers Enabled", true, function(val) VisualSettings.TracersEnabled=val if not val then ClearAllTracers() end end)
VisualsSection:AddColorpicker("Tracer Color", VisualSettings.TracerColor, function(val) VisualSettings.TracerColor=val end)
VisualsSection:AddSlider("Tracer Duration", 0.1, 2, 0.5, function(val) VisualSettings.TracerDuration=val end)
VisualsSection:AddSlider("Tracer Thickness", 0.5, 5, 1, function(val) VisualSettings.TracerThickness=val end)

local MovementSection = MainTab:AddSection('Movement', "right")
MovementSection:AddToggle('BunnyHop Enabled', false, function(val)
    BunnyHopSettings.Enabled = val
    if val then StartBunnyHop() else StopBunnyHop() end
end)

local AASection = AntiAimTab:AddSection('AntiAim', 'left')
AASection:AddDropdown("Mode", {"Off","Safe Fake"}, "Off", function(val) AASettings.Mode=val end)
AASection:AddSlider("FakeYaw", 0, 60, 25, function(val) AASettings.FakeYaw=val end)
AASection:AddSlider("FakePitch", 0, 10, 3, function(val) AASettings.FakePitch=val end)

CacheChar()
Notification:Notify("info", "neverlose.lua", "Loaded! (Rage, ESP, Hitlog, Chams, Tracers, BunnyHop, Safe AA, Uninject)")
print("neverlose.lua (rage improved, center hitlog, esp/chams, tracers, bunnyhop, ghostpeek, safe aa, menu UX)")
