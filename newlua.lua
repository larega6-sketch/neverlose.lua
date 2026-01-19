local Compkiller = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/CompKiller/refs/heads/main/src/source.luau"))();

local ConfigManager = Compkiller:ConfigManager({
	Directory = "Compkiller-UI",
	Config = "AimConfigs",
});

Compkiller:Loader("rbxassetid://120245531583106", 2.5).yield();

local Window = Compkiller.new({
	Name = "RAGE HUB",
	Keybind = "RightControl",
	Logo = "rbxassetid://120245531583106",
	TextSize = 15,
});

Window:DrawCategory({
	Name = "Main"
});

-- RAGE BOT TAB --
local RageTab = Window:DrawTab({
	Name = "Rage Bot",
	Icon = "target",
});

local AimSection = RageTab:DrawSection({
	Name = "Aimbot",
	Position = 'left'	
});

AimSection:AddToggle({
	Name = "Enable Aimbot",
	Flag = "aimbot_enable",
	Default = false,
	Callback = function(state)
		print("Aimbot:", state)
	end,
});

AimSection:AddKeybind({
	Name = "Aimbot Key",
	Default = "MouseButton2",
	Flag = "aimbot_key",
	Callback = print,
});

AimSection:AddSlider({
	Name = "Field of View",
	Min = 0,
	Max = 360,
	Default = 90,
	Round = 0,
	Flag = "aimbot_fov",
	Callback = print
});

AimSection:AddDropdown({
	Name = "Hitbox Priority",
	Default = "Head",
	Flag = "aimbot_hitbox",
	Values = {"Head", "Body", "Random"},
	Callback = print
});

local WeaponSection = RageTab:DrawSection({
	Name = "Weapon",
	Position = 'right'	
});

WeaponSection:AddToggle({
	Name = "Silent Aim",
	Flag = "silent_aim",
	Default = false,
	Callback = print,
});

WeaponSection:AddToggle({
	Name = "Auto Shoot",
	Flag = "auto_shoot",
	Default = false,
	Callback = print,
});

WeaponSection:AddSlider({
	Name = "Hit Chance %",
	Min = 0,
	Max = 100,
	Default = 80,
	Round = 0,
	Flag = "hit_chance",
	Callback = print
});

-- ANTI-AIM TAB --
local AATab = Window:DrawTab({
	Name = "Anti-Aim",
	Icon = "shield",
	Type = "Single",
});

local AASection = AATab:DrawSection({
	Name = "Anti-Aim Settings",
	Position = 'left'	
});

AASection:AddToggle({
	Name = "Enable Anti-Aim",
	Flag = "aa_enable",
	Default = false,
	Callback = print,
});

AASection:AddDropdown({
	Name = "Pitch",
	Default = "Default",
	Flag = "aa_pitch",
	Values = {"Default", "Down", "Up", "Random"},
	Callback = print
});

AASection:AddDropdown({
	Name = "Yaw",
	Default = "Default",
	Flag = "aa_yaw",
	Values = {"Default", "Backwards", "Spin", "Jitter"},
	Callback = print
});

AASection:AddSlider({
	Name = "Jitter Range",
	Min = 0,
	Max = 180,
	Default = 45,
	Round = 0,
	Flag = "aa_jitter_range",
	Callback = print
});

local FakeLagSection = AATab:DrawSection({
	Name = "Fake Lag",
	Position = 'right'	
});

FakeLagSection:AddToggle({
	Name = "Enable Fake Lag",
	Flag = "fakelag_enable",
	Default = false,
	Callback = print,
});

FakeLagSection:AddSlider({
	Name = "Lag Amount",
	Min = 0,
	Max = 100,
	Default = 30,
	Round = 0,
	Flag = "fakelag_amount",
	Callback = print
});

FakeLagSection:AddDropdown({
	Name = "Lag Type",
	Default = "Adaptive",
	Flag = "fakelag_type",
	Values = {"Adaptive", "Static", "Random"},
	Callback = print
});

-- VISUAL TAB --
local VisualTab = Window:DrawTab({
	Name = "Visual",
	Icon = "eye",
});

local ESPsection = VisualTab:DrawSection({
	Name = "ESP",
	Position = 'left'	
});

ESPsection:AddToggle({
	Name = "Enable ESP",
	Flag = "esp_enable",
	Default = true,
	Callback = print,
});

ESPsection:AddColorPicker({
	Name = "Box Color",
	Default = Color3.fromRGB(0, 255, 140),
	Flag = "esp_box_color",
	Callback = print
});

ESPsection:AddToggle({
	Name = "Show Name",
	Flag = "esp_name",
	Default = true,
	Callback = print,
});

ESPsection:AddToggle({
	Name = "Show Health",
	Flag = "esp_health",
	Default = true,
	Callback = print,
});

local MiscSection = VisualTab:DrawSection({
	Name = "Visual Effects",
	Position = 'right'	
});

MiscSection:AddToggle({
	Name = "Chams",
	Flag = "chams_enable",
	Default = false,
	Callback = print,
});

MiscSection:AddColorPicker({
	Name = "Chams Color",
	Default = Color3.fromRGB(255, 0, 0),
	Flag = "chams_color",
	Callback = print
});

MiscSection:AddToggle({
	Name = "No Flash",
	Flag = "no_flash",
	Default = true,
	Callback = print,
});

MiscSection:AddToggle({
	Name = "No Smoke",
	Flag = "no_smoke",
	Default = false,
	Callback = print,
});

-- CONFIG TAB --
local ConfigUI = Window:DrawConfig({
	Name = "Config",
	Icon = "folder",
	Config = ConfigManager,
});

ConfigUI:Init();