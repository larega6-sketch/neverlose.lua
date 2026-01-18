local NEVERLOSE = loadstring(game:HttpGet("https://raw.githubusercontent.com/3345-c-a-t-s-u-s/NEVERLOSE-UI-Nightly/main/source.lua"))()

-- Change Theme --
NEVERLOSE:Theme("original") -- [ dark , nightly , original ]
------------------

local Window = NEVERLOSE:AddWindow("NEVERLOSE", "Arcanum Ragebot")
local Notification = NEVERLOSE:Notification()

Notification.MaxNotifications = 6

Window:AddTabLabel('Home')

local MainTab = Window:AddTab('Ragebot', 'mouse') -- Основная вкладка
local VisualsTab = Window:AddTab('Visuals', 'earth') -- Визуальная вкладка
local MiscTab = Window:AddTab('Misc', 'folder') -- Дополнительные функции

-- ========== СИСТЕМА ПЕРЕМЕННЫХ И КОНСТАНТ ==========
local Plrs = game:GetService("Players")
local WS = game:GetService("Workspace")
local RS = game:GetService("RunService")
local LP = Plrs.LocalPlayer

-- Настройки Ragebot'а
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
    
    -- AI Предсказание
    Prediction = true,
    PredMode = "Default", -- "Default" или "Beta AI"
    AIConfThreshold = 60,
    AIHistorySize = 30,
    AIPeekDetect = true,
    AIStrafeDetect = true,
    AIVisualBox = false,
    AIVisualTrace = false,
    
    -- Double Tap
    DTEnabled = false,
    DTKey = Enum.KeyCode.E,
    DTDistance = 6,
    DTMode = "Defensive",
    DTAuto = false,
    DTAutoDelay = 200,
}

-- Визуальные настройки
local VisualSettings = {
    Watermark = true,
    HotkeyList = true,
    TimeDisplay = true,
    HitLogger = true,
    MaxLogs = 8,
    Hitmarker = true,
    HitmarkerColor = "Green",
    KillEffect = true,
    KillEffectColor = "White",
    FortniteDamage = true,
    FortniteDamageColor = "White",
    AimView = false,
    AimViewColor = "Red",
    AimViewTransparency = 0.3,
}

-- Разное
local MiscSettings = {
    -- Wallbang
    Wallbang = false,
    NoCollision = false,
    
    -- Ghost Peek
    GhostPeek = true,
    GhostPeekKey = Enum.KeyCode.Q,
    GhostPeekMode = "Hold",
    GhostPeekAutoShoot = true,
    GhostPeekTeamCheck = true,
    GhostPeekRange = 100,
    GhostPeekDistance = 8,
    GhostPeekHeight = 3,
    GhostPeekQuality = 50,
    
    -- AI Peek v4
    AIPeek = false,
    AIPeekKey = Enum.KeyCode.LeftAlt,
    AIPeekMode = "Hold",
    AIPeekShowPoints = false,
    AIPeekESP = false,
    AIPeekTeamCheck = true,
    AIPeekHeight = 2.0,
    AIPeekSpeed = 200,
    AIPeekCooldown = 0.1,
    AIPeekRange = 80,
    AIPeekDistance = 8,
    
    -- Infinity Jump
    InfinityJump = false,
    InfinityJumpKey = Enum.KeyCode.Space,
    
    -- Bunny Hop
    BunnyHop = false,
    BunnyHopKey = Enum.KeyCode.F,
    BunnyHopGroundSpeed = 35,
    BunnyHopAirSpeed = 39,
}

-- Локальные переменные
local playerData = {}
local playerDataTime = 0
local PLAYER_CACHE_INTERVAL = 0.2
local myChar, myHRP, myHead, myHum
local fireShot, fireShotTime = nil, 0
local rbLast = 0
local frame = 0

-- Raycast параметры
local RayP = RaycastParams.new()
RayP.FilterType = Enum.RaycastFilterType.Exclude

-- ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
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
    
    -- Сортировка по расстоянию
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

-- ========== AI ПРЕДСКАЗАНИЕ (Beta AI) ==========
local AI_PRED = {
    history = {},
    patterns = {},
    HISTORY_SIZE = 30,
    PEEK_THRESHOLD = 15,
    STRAFE_THRESHOLD = 8,
    peekDetect = true,
    strafeDetect = true,
}

local function AI_AddHistory(playerName, pos, vel, time)
    if not AI_PRED.history[playerName] then
        AI_PRED.history[playerName] = {}
    end
    local h = AI_PRED.history[playerName]
    table.insert(h, {pos = pos, vel = vel, time = time})
    
    while #h > AI_PRED.HISTORY_SIZE do
        table.remove(h, 1)
    end
end

local function AI_AnalyzePattern(playerName)
    local h = AI_PRED.history[playerName]
    if not h or #h < 10 then return nil end
    
    local pattern = {
        isPeeking = false,
        isStrafing = false,
        peekDirection = nil,
        strafeDirection = nil,
        avgSpeed = 0,
        directionChanges = 0,
        predictedPos = nil,
        confidence = 0
    }
    
    local totalSpeed = 0
    local dirChanges = 0
    local lastDir = nil
    
    for i = 2, #h do
        local prev = h[i-1]
        local curr = h[i]
        local moveDir = (curr.pos - prev.pos).Unit
        local speed = (curr.pos - prev.pos).Magnitude / math.max(0.001, curr.time - prev.time)
        totalSpeed = totalSpeed + speed
        
        if lastDir then
            local dot = moveDir:Dot(lastDir)
            if dot < 0.5 then
                dirChanges = dirChanges + 1
            end
        end
        lastDir = moveDir
    end
    
    pattern.avgSpeed = totalSpeed / (#h - 1)
    pattern.directionChanges = dirChanges
    
    if #h >= 5 then
        local recent = h[#h]
        local older = h[#h - 4]
        local recentVel = recent.vel
        local olderVel = older.vel
        
        local velChange = (recentVel - olderVel).Magnitude
        if velChange > AI_PRED.PEEK_THRESHOLD then
            pattern.isPeeking = true
            pattern.peekDirection = recentVel.Unit
            pattern.confidence = math.min(1, velChange / 30)
        end
    end
    
    if dirChanges >= 3 and pattern.avgSpeed > 5 then
        pattern.isStrafing = true
        local lastVel = h[#h].vel
        pattern.strafeDirection = Vector3.new(-lastVel.X, 0, -lastVel.Z).Unit
        pattern.confidence = math.min(1, dirChanges / 6)
    end
    
    AI_PRED.patterns[playerName] = pattern
    return pattern
end

local function AI_PredictPosition(playerName, currentPos, currentVel, predTime)
    local pattern = AI_PRED.patterns[playerName]
    local h = AI_PRED.history[playerName]
    
    local predicted = currentPos + currentVel * predTime
    
    if not pattern or not h or #h < 5 then
        return predicted, 0.5
    end
    
    if pattern.isPeeking and pattern.peekDirection then
        local peekOffset = pattern.peekDirection * (pattern.avgSpeed * predTime * 1.5)
        predicted = currentPos + peekOffset
        return predicted, pattern.confidence
    end
    
    if pattern.isStrafing and pattern.strafeDirection then
        local strafeOffset = pattern.strafeDirection * (pattern.avgSpeed * predTime * 0.5)
        predicted = currentPos + strafeOffset
        return predicted, pattern.confidence
    end
    
    if #h >= 10 then
        local sumVel = Vector3.zero
        for i = #h - 9, #h do
            sumVel = sumVel + h[i].vel
        end
        local avgVel = sumVel / 10
        
        local weightedVel = (currentVel * 0.7) + (avgVel * 0.3)
        predicted = currentPos + weightedVel * predTime
        return predicted, 0.7
    end
    
    return predicted, 0.5
end

local function AI_GetBestPrediction(playerName, headPos, vel, ping)
    local predTime = ping * 1.2
    
    AI_AddHistory(playerName, headPos, vel, tick())
    AI_AnalyzePattern(playerName)
    
    local predicted, confidence = AI_PredictPosition(playerName, headPos, vel, predTime)
    
    local pattern = AI_PRED.patterns[playerName]
    local mode = "TRACK"
    if pattern then
        if pattern.isStrafing then mode = "STRAFE"
        elseif pattern.isPeeking then mode = "PEEK" end
    end
    
    return predicted, confidence, mode
end

-- ========== ОСНОВНОЙ ЦИКЛ RAGEBOT ==========
local function MainLoop()
    if not RageSettings.Enabled then return end
    frame = frame + 1
    
    if frame % 15 == 0 then CacheChar() end
    if not myChar or not myHRP then return end
    
    UpdatePlayerData()
    
    local now = tick()
    local hrp = myHRP
    local head = myHead
    local cam = WS.CurrentCamera
    
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
                    if RageSettings.AirShoot then
                        if d.head then table.insert(targets, {part = d.head, priority = 3}) end
                        if d.torso then table.insert(targets, {part = d.torso, priority = 2}) end
                    elseif RageSettings.SmartAim then
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
                        local ping = LP:GetNetworkPing()
                        local playerName = d.p and d.p.Name or "Unknown"
                        local realPos = tgt.Position
                        local targetPos = realPos
                        
                        local params = RaycastParams.new()
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        params.FilterDescendantsInstances = {myChar, d.c}
                        
                        local realDirection = realPos - bulletOrigin
                        local res = WS:Raycast(bulletOrigin, realDirection, params)
                        local canSeeReal = (res == nil)
                        
                        if RageSettings.WallCheck and not canSeeReal then continue end
                        
                        if canSeeReal then
                            local aiMode = "TRACK"
                            local aiConfidence = 0.5
                            
                            if RageSettings.PredMode == "Beta AI" then
                                local aiPredictedPos
                                aiPredictedPos, aiConfidence, aiMode = AI_GetBestPrediction(playerName, realPos, vel, ping)
                                
                                local confThreshold = RageSettings.AIConfThreshold / 100
                                local predDirection = aiPredictedPos - bulletOrigin
                                local predRes = WS:Raycast(bulletOrigin, predDirection, params)
                                local canSeePred = (predRes == nil)
                                
                                if canSeePred and aiConfidence >= confThreshold then
                                    targetPos = aiPredictedPos
                                else
                                    targetPos = realPos + vel * ping
                                    aiConfidence = 0.5
                                end
                            else
                                targetPos = realPos + vel * ping
                            end
                            
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
                    
                    -- Отправляем уведомление
                    local targetName = best.d.p and best.d.p.Name or "Unknown"
                    Notification:Notify("info", "Ragebot", "Shot at " .. targetName)
                end
            end
        end
    end
    
    if frame > 1000 then frame = 0 end
end

-- Запуск основного цикла
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

-- ========== СОЗДАНИЕ МЕНЮ ==========
-- Вкладка Ragebot
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

-- AI Prediction Settings
local AISection = MainTab:AddSection('AI Prediction', "right")

AISection:AddDropdown('Prediction Mode', {"Default", "Beta AI"}, "Default", function(val)
    RageSettings.PredMode = val
end)

AISection:AddToggle('Prediction', true, function(val)
    RageSettings.Prediction = val
end)

AISection:AddSlider('Confidence %', 30, 100, 60, function(val)
    RageSettings.AIConfThreshold = val
    AI_PRED.PEEK_THRESHOLD = 15
    AI_PRED.STRAFE_THRESHOLD = 8
end)

AISection:AddSlider('History Size', 10, 50, 30, function(val)
    RageSettings.AIHistorySize = val
    AI_PRED.HISTORY_SIZE = val
end)

AISection:AddToggle('Peek Detect', true, function(val)
    RageSettings.AIPeekDetect = val
    AI_PRED.peekDetect = val
end)

AISection:AddToggle('Strafe Detect', true, function(val)
    RageSettings.AIStrafeDetect = val
    AI_PRED.strafeDetect = val
end)

AISection:AddToggle('Visual Box', false, function(val)
    RageSettings.AIVisualBox = val
end)

AISection:AddToggle('Visual Trace', false, function(val)
    RageSettings.AIVisualTrace = val
end)

-- Double Tap Section
local DTSection = MainTab:AddSection('Double Tap', "left")

DTSection:AddToggle('Enable Double Tap', false, function(val)
    RageSettings.DTEnabled = val
end)

DTSection:AddKeybind('DT Key', Enum.KeyCode.E, function(val)
    RageSettings.DTKey = val
end)

DTSection:AddSlider('TP Distance', 3, 10, 6, function(val)
    RageSettings.DTDistance = val
end)

DTSection:AddDropdown('DT Mode', {"Defensive", "Aggressive"}, "Defensive", function(val)
    RageSettings.DTMode = val
end)

DTSection:AddToggle('Auto DT', false, function(val)
    RageSettings.DTAuto = val
end)

DTSection:AddSlider('Auto DT Delay (ms)', 100, 1000, 200, function(val)
    RageSettings.DTAutoDelay = val
end)

-- Вкладка Visuals
local VisualsSection = VisualsTab:AddSection('Visual Settings', "left")

VisualsSection:AddToggle('Watermark', true, function(val)
    VisualSettings.Watermark = val
end)

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

VisualsSection:AddToggle('Fortnite Damage', true, function(val)
    VisualSettings.FortniteDamage = val
end)

VisualsSection:AddDropdown('FD Color', {"White", "Red", "Blue", "Green", "Yellow", "Purple", "Cyan"}, "White", function(val)
    VisualSettings.FortniteDamageColor = val
end)

-- AimView Section
local AimViewSection = VisualsTab:AddSection('AimView', "right")

AimViewSection:AddToggle('AimView', false, function(val)
    VisualSettings.AimView = val
end)

AimViewSection:AddDropdown('AimView Color', {"Red", "Green", "Blue", "White", "Yellow", "Purple", "Cyan"}, "Red", function(val)
    VisualSettings.AimViewColor = val
end)

AimViewSection:AddSlider('Transparency %', 0, 100, 30, function(val)
    VisualSettings.AimViewTransparency = val / 100
end)

-- Вкладка Misc
local MiscSection = MiscTab:AddSection('Misc Features', "left")

MiscSection:AddToggle('Wallbang Helper', false, function(val)
    MiscSettings.Wallbang = val
end)

MiscSection:AddToggle('No Collision', false, function(val)
    MiscSettings.NoCollision = val
end)

MiscSection:AddToggle('Infinity Jump', false, function(val)
    MiscSettings.InfinityJump = val
end)

MiscSection:AddKeybind('IJ Key', Enum.KeyCode.Space, function(val)
    MiscSettings.InfinityJumpKey = val
end)

MiscSection:AddToggle('Bunny Hop', false, function(val)
    MiscSettings.BunnyHop = val
end)

MiscSection:AddKeybind('BH Key', Enum.KeyCode.F, function(val)
    MiscSettings.BunnyHopKey = val
end)

MiscSection:AddSlider('Ground Speed', 16, 100, 35, function(val)
    MiscSettings.BunnyHopGroundSpeed = val
end)

MiscSection:AddSlider('Air Speed', 16, 100, 39, function(val)
    MiscSettings.BunnyHopAirSpeed = val
end)

-- Ghost Peek Section
local GhostPeekSection = MiscTab:AddSection('Ghost Peek', "right")

GhostPeekSection:AddToggle('Ghost Peek', true, function(val)
    MiscSettings.GhostPeek = val
end)

GhostPeekSection:AddKeybind('GP Key', Enum.KeyCode.Q, function(val)
    MiscSettings.GhostPeekKey = val
end)

GhostPeekSection:AddDropdown('GP Mode', {"Hold", "Toggle"}, "Hold", function(val)
    MiscSettings.GhostPeekMode = val
end)

GhostPeekSection:AddToggle('Auto Shoot', true, function(val)
    MiscSettings.GhostPeekAutoShoot = val
end)

GhostPeekSection:AddToggle('Team Check', true, function(val)
    MiscSettings.GhostPeekTeamCheck = val
end)

GhostPeekSection:AddSlider('Range', 20, 300, 100, function(val)
    MiscSettings.GhostPeekRange = val
end)

GhostPeekSection:AddSlider('Peek Distance', 5, 60, 8, function(val)
    MiscSettings.GhostPeekDistance = val
end)

GhostPeekSection:AddSlider('Max Height', 1, 15, 3, function(val)
    MiscSettings.GhostPeekHeight = val
end)

GhostPeekSection:AddSlider('Quality', 0, 100, 50, function(val)
    MiscSettings.GhostPeekQuality = val
end)

-- AI Peek v4 Section
local AIPeekSection = MiscTab:AddSection('AI Peek v4', "left")

AIPeekSection:AddToggle('AI Peek v4', false, function(val)
    MiscSettings.AIPeek = val
end)

AIPeekSection:AddKeybind('AP Key', Enum.KeyCode.LeftAlt, function(val)
    MiscSettings.AIPeekKey = val
end)

AIPeekSection:AddDropdown('AP Mode', {"Hold", "Toggle"}, "Hold", function(val)
    MiscSettings.AIPeekMode = val
end)

AIPeekSection:AddToggle('Show Points', false, function(val)
    MiscSettings.AIPeekShowPoints = val
end)

AIPeekSection:AddToggle('ESP Outline', false, function(val)
    MiscSettings.AIPeekESP = val
end)

AIPeekSection:AddToggle('Team Check', true, function(val)
    MiscSettings.AIPeekTeamCheck = val
end)

AIPeekSection:AddSlider('Cooldown (ms)', 0, 3000, 100, function(val)
    MiscSettings.AIPeekCooldown = val / 1000
end)

AIPeekSection:AddSlider('Range', 0, 200, 80, function(val)
    MiscSettings.AIPeekRange = val
end)

AIPeekSection:AddSlider('Peek Distance', 0, 20, 8, function(val)
    MiscSettings.AIPeekDistance = val
end)

AIPeekSection:AddSlider('Speed', 0, 1000, 200, function(val)
    MiscSettings.AIPeekSpeed = val
end)

AIPeekSection:AddSlider('Max Height', 1, 10, 2, function(val)
    MiscSettings.AIPeekHeight = val
end)

-- Кнопка сброса
local ResetSection = MiscTab:AddSection('Reset', "right")
ResetSection:AddButton('Reset All Settings', function()
    RageSettings.Enabled = false
    StopRagebot()
    
    for k, v in pairs(RageSettings) do
        if type(v) == "boolean" then
            RageSettings[k] = false
        elseif k == "Hitbox" then
            RageSettings[k] = "Head"
        elseif k == "PredMode" then
            RageSettings[k] = "Default"
        elseif k == "MaxDist" then
            RageSettings[k] = 500
        elseif k == "BodyAimHP" then
            RageSettings[k] = 50
        end
    end
    
    RageSettings.AutoFire = true
    RageSettings.TeamCheck = true
    RageSettings.WallCheck = true
    RageSettings.NoAirShot = true
    RageSettings.SmartAim = true
    RageSettings.Prediction = true
    RageSettings.AIConfThreshold = 60
    RageSettings.AIHistorySize = 30
    RageSettings.AIPeekDetect = true
    RageSettings.AIStrafeDetect = true
    
    Notification:Notify("success", "Reset", "All settings have been reset!")
end)

-- Инициализация
CacheChar()
Notification:Notify("info", "Arcanum Ragebot", "Loaded successfully!")

print("Arcanum Ragebot for Neverlose UI")