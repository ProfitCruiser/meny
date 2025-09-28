--====================================================--
-- AURORA PANEL — ProfitCruiser (fixed key→panel flow)
-- Full redesign: Compact 2-col layout + sections + gating
-- Aimbot, ESP (Highlight), Crosshair, Profiles
--====================================================--

--// Services
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")
local Players           = game:GetService("Players")
local GuiService        = game:GetService("GuiService")
local HttpService       = game:GetService("HttpService")
local TextService       = game:GetService("TextService")
local SoundService      = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- Emergency guard: disable heavy runtime systems that were causing crashes
local SAFE_MODE = true

local function currentCamera()
    local cam = workspace.CurrentCamera
    if cam then
        Camera = cam
        return cam
    end
    return Camera
end

-- forward-declare Root so click handlers can access it before it's created
local Root

pcall(function()
    GuiService.AutoSelectGuiEnabled = false
    GuiService.SelectedObject = nil
end)

--// Gate / links
local KEY_CHECK_URL = "https://pastebin.com/raw/QgqAaumb"
local GET_KEY_URL   = "https://pastebin.com/raw/QgqAaumb"
local DISCORD_URL   = "https://discord.gg/Pgn4NMWDH8"

local ThemePresets = {
    Light = {
        BG      = Color3.fromRGB(240, 244, 255),
        Panel   = Color3.fromRGB(225, 230, 248),
        Card    = Color3.fromRGB(246, 248, 255),
        Ink     = Color3.fromRGB(210, 215, 236),
        Stroke  = Color3.fromRGB(170, 178, 210),
        Neon    = Color3.fromRGB(80, 110, 255),
        Accent  = Color3.fromRGB(105, 135, 255),
        Text    = Color3.fromRGB(24, 28, 40),
        Subtle  = Color3.fromRGB(80, 90, 120),
        Good    = Color3.fromRGB(34, 170, 120),
        Warn    = Color3.fromRGB(214, 140, 60),
        Off     = Color3.fromRGB(150, 155, 185),
    },
    Dark = {
        BG      = Color3.fromRGB(10, 9, 18),
        Panel   = Color3.fromRGB(18, 16, 31),
        Card    = Color3.fromRGB(24, 21, 40),
        Ink     = Color3.fromRGB(34, 30, 52),
        Stroke  = Color3.fromRGB(82, 74, 120),
        Neon    = Color3.fromRGB(160, 105, 255),
        Accent  = Color3.fromRGB(116, 92, 220),
        Text    = Color3.fromRGB(240, 240, 252),
        Subtle  = Color3.fromRGB(188, 182, 210),
        Good    = Color3.fromRGB(80, 210, 140),
        Warn    = Color3.fromRGB(255, 183, 77),
        Off     = Color3.fromRGB(100, 94, 130),
    },
    Galaxy = {
        BG      = Color3.fromRGB(6, 4, 18),
        Panel   = Color3.fromRGB(18, 12, 40),
        Card    = Color3.fromRGB(26, 18, 54),
        Ink     = Color3.fromRGB(36, 22, 70),
        Stroke  = Color3.fromRGB(90, 60, 150),
        Neon    = Color3.fromRGB(120, 205, 255),
        Accent  = Color3.fromRGB(160, 90, 255),
        Text    = Color3.fromRGB(225, 235, 255),
        Subtle  = Color3.fromRGB(170, 180, 220),
        Good    = Color3.fromRGB(80, 210, 200),
        Warn    = Color3.fromRGB(255, 150, 95),
        Off     = Color3.fromRGB(110, 80, 150),
    },
    Noir = {
        BG      = Color3.fromRGB(12, 12, 12),
        Panel   = Color3.fromRGB(22, 22, 22),
        Card    = Color3.fromRGB(28, 28, 28),
        Ink     = Color3.fromRGB(36, 36, 36),
        Stroke  = Color3.fromRGB(70, 70, 70),
        Neon    = Color3.fromRGB(255, 95, 95),
        Accent  = Color3.fromRGB(140, 140, 140),
        Text    = Color3.fromRGB(235, 235, 235),
        Subtle  = Color3.fromRGB(170, 170, 170),
        Good    = Color3.fromRGB(100, 205, 150),
        Warn    = Color3.fromRGB(255, 180, 90),
        Off     = Color3.fromRGB(110, 110, 110),
    },
}

local CustomThemeOverrides = {
    Neon = nil,
    Ink = nil,
    Text = nil,
}

local ThemeBindings = {}
local ThemeColorControls = {}
local CurrentThemeName = "Dark"
local T = table.clone(ThemePresets[CurrentThemeName])
local KEY_ROTATION_SECONDS = 900

local function bindTheme(instance, property, key, transform)
    local entry = {
        Instance = instance,
        Property = property,
        Key = key,
        Transform = transform,
    }
    ThemeBindings[#ThemeBindings + 1] = entry
    if instance and instance[property] ~= nil then
        local value = T[key]
        if transform then
            value = transform(value)
        end
        instance[property] = value
    end
end

local function applyThemeState(name)
    if name and ThemePresets[name] then
        CurrentThemeName = name
    end
    local base = ThemePresets[CurrentThemeName] or ThemePresets.Dark
    T = table.clone(base)
    for key, value in pairs(CustomThemeOverrides) do
        if value then
            T[key] = value
        end
    end
    for i = #ThemeBindings, 1, -1 do
        local binding = ThemeBindings[i]
        local inst = binding.Instance
        if inst and inst.Parent then
            local val = T[binding.Key]
            if binding.Transform then
                val = binding.Transform(val)
            end
            inst[binding.Property] = val
        else
            table.remove(ThemeBindings, i)
        end
    end
    if ActiveTabButton and ActiveTabButton.Parent then
        ActiveTabButton.BackgroundColor3 = T.Accent
        local indicator = TabIndicators[ActiveTabButton]
        if indicator then
            indicator.BackgroundColor3 = T.Neon
            indicator.Size = UDim2.new(0,4,1,0)
        end
    end
    if updateKeyTimerLabel then
        updateKeyTimerLabel()
    end
    for _, control in ipairs(ThemeColorControls) do
        if control.Row and control.Row.Parent then
            local themeColor = T[control.ThemeKey]
            if control.Set then
                control.Set(themeColor, true)
            end
        end
    end
    refreshStatusBanner()
end

local function setCustomThemeColor(key, color)
    if color ~= nil and typeof(color) ~= "Color3" then
        return
    end
    CustomThemeOverrides[key] = color
    applyThemeState()
end

local function setThemePreset(name)
    if ThemePresets[name] then
        CurrentThemeName = name
        CustomThemeOverrides.Neon = nil
        CustomThemeOverrides.Ink = nil
        CustomThemeOverrides.Text = nil
        applyThemeState(name)
    end
end

local Strings = {
    EN = {},
    NO = {},
}

local LocalizationEntries = {
    ["Reset Tab"] = {EN = "Reset Tab", NO = "Tilbakestill fane"},
    ["Aimbot Tab"] = {EN = "Aimbot", NO = "Aimbot"},
    ["ESP Tab"] = {EN = "ESP", NO = "ESP"},
    ["Visuals Tab"] = {EN = "Visuals", NO = "Visuelt"},
    ["Misc Tab"] = {EN = "Misc", NO = "Diverse"},
    ["Config Tab"] = {EN = "Config", NO = "Konfig"},
    ["Theme Preset"] = {EN = "Theme Preset", NO = "Temamal"},
    ["Accent Neon"] = {EN = "Accent Neon", NO = "Aksen neon"},
    ["Canvas Ink"] = {EN = "Canvas Ink", NO = "Bakgrunnsfarge"},
    ["Primary Text"] = {EN = "Primary Text", NO = "Hovedtekst"},
    ["Crosshair"] = {EN = "Crosshair", NO = "Retikkel"},
    ["Opacity"] = {EN = "Opacity", NO = "Opasitet"},
    ["Size"] = {EN = "Size", NO = "Størrelse"},
    ["Gap"] = {EN = "Gap", NO = "Mellomrom"},
    ["Thickness"] = {EN = "Thickness", NO = "Tykkelse"},
    ["Center Dot"] = {EN = "Center Dot", NO = "Punkt i midten"},
    ["Dot Size"] = {EN = "Dot Size", NO = "Punktstørrelse"},
    ["Dot Opacity"] = {EN = "Dot Opacity", NO = "Punktopasitet"},
    ["Use Team Color"] = {EN = "Use Team Color", NO = "Bruk lagfarge"},
    ["Rainbow Cycle"] = {EN = "Rainbow Cycle", NO = "Regnbue"},
    ["Rainbow Speed"] = {EN = "Rainbow Speed", NO = "Regnbuehastighet"},
    ["Pulse Opacity"] = {EN = "Pulse Opacity", NO = "Pulsopasitet"},
    ["Pulse Speed"] = {EN = "Pulse Speed", NO = "Pulshastighet"},
    ["Crosshair Preset"] = {EN = "Crosshair Preset", NO = "Retikkelmal"},
    ["Save Crosshair as Preset"] = {EN = "Save Crosshair as Preset", NO = "Lagre retikkel som mal"},
    ["Save"] = {EN = "Save", NO = "Lagre"},
    ["Toggle UI"] = {EN = "Toggle UI", NO = "Vis/skjul UI"},
    ["Panic Hotkey"] = {EN = "Panic Hotkey", NO = "Panikktast"},
    ["UI Scale"] = {EN = "UI Scale", NO = "UI-skala"},
    ["Font Scale"] = {EN = "Font Scale", NO = "Tekstskala"},
    ["Language"] = {EN = "Language", NO = "Språk"},
    ["Sound Cues"] = {EN = "Sound Cues", NO = "Lydsignaler"},
    ["Low Impact Mode"] = {EN = "Low Impact Mode", NO = "Lavbelastningsmodus"},
    ["Reset All Tabs"] = {EN = "Reset All Tabs", NO = "Tilbakestill alle faner"},
    ["English"] = {EN = "English", NO = "Engelsk"},
    ["Norsk"] = {EN = "Norsk", NO = "Norsk"},
    ["Rotation resets in %02d:%02d"] = {EN = "Rotation resets in %02d:%02d", NO = "Nøkkel fornyes om %02d:%02d"},
    ["Low impact mode ON"] = {EN = "Low impact mode ON", NO = "Lavbelastningsmodus aktiv"},
    ["Key expiring soon"] = {EN = "Key expiring soon", NO = "Nøkkel utløper snart"},
    ["Failsafe triggered"] = {EN = "Failsafe triggered — visuals paused", NO = "Failsafe aktiv — effekter stoppet"},
    ["Welcome to Aurora"] = {EN = "Welcome to Aurora", NO = "Velkommen til Aurora"},
    ["Paste your key, hit Unlock, and meet us on Discord. We'll only show this once!"] = {EN = "Paste your key, hit Unlock, and meet us on Discord. We'll only show this once!", NO = "Lim inn nøkkelen, trykk Lås opp og møt oss på Discord. Dette vises bare én gang!"},
    ["Tap Get Key"] = {EN = "Tap Get Key", NO = "Trykk Hent nøkkel"},
    ["Use the copy to grab a fresh key."] = {EN = "Use the copy to grab a fresh key.", NO = "Bruk kopien for en ny nøkkel."},
    ["Paste & Unlock"] = {EN = "Paste & Unlock", NO = "Lim inn og lås opp"},
    ["Drop the key in the box and press Unlock Panel."] = {EN = "Drop the key in the box and press Unlock Panel.", NO = "Lim inn nøkkelen og trykk Lås opp."},
    ["Join Discord"] = {EN = "Join Discord", NO = "Bli med i Discord"},
    ["Hop in for updates and rotation pings."] = {EN = "Hop in for updates and rotation pings.", NO = "Få oppdateringer og varsler om rotasjon."},
    ["Let's go"] = {EN = "Let's go", NO = "Kom i gang"},
    ["Theme Preset"] = {EN = "Theme Preset", NO = "Temamal"},
    ["QuickSearch"] = {EN = "Search", NO = "Søk"},
    ["Save Crosshair as Preset"] = {EN = "Save Crosshair as Preset", NO = "Lagre retikkel som mal"},
    ["Crosshair Preset"] = {EN = "Crosshair Preset", NO = "Retikkelmal"},
}

for key, map in pairs(LocalizationEntries) do
    Strings.EN[key] = map.EN or key
    Strings.NO[key] = map.NO or map.EN or key
end

local CurrentLanguage = "EN"
local TextRegistry = {}
local FontRegistry = {}
local FontScale = 1

local function translate(key, fallback)
    local bucket = Strings[CurrentLanguage]
    if bucket and bucket[key] then
        return bucket[key]
    end
    return fallback
end

local BannerStates = {}
local bannerOrderCounter = 0

local function refreshStatusBanner()
    if not (StatusBanner and StatusBanner.Parent) then return end
    local entries = {}
    for _, info in pairs(BannerStates) do
        entries[#entries + 1] = info
    end
    table.sort(entries, function(a, b)
        return (a.Order or 0) < (b.Order or 0)
    end)

    local parts = {}
    local bestPriority = -math.huge
    local bestColor = (T and T.Subtle) or Color3.new(1, 1, 1)
    for _, info in ipairs(entries) do
        local text = translate(info.Key, info.Fallback or info.Key)
        if text ~= "" then
            parts[#parts + 1] = text
            local priority = info.Priority or 0
            if priority >= bestPriority then
                bestPriority = priority
                local col = info.Color
                if typeof(col) == "string" and T and T[col] then
                    bestColor = T[col]
                elseif typeof(col) == "Color3" then
                    bestColor = col
                else
                    bestColor = (T and T.Subtle) or Color3.new(1, 1, 1)
                end
            end
        end
    end

    if #parts > 0 then
        StatusBanner.Visible = true
        StatusBanner.Text = table.concat(parts, "   •   ")
        StatusBanner.TextColor3 = bestColor
    else
        StatusBanner.Visible = false
    end
end

local function setBannerState(key, textKey, fallback, color, priority)
    if textKey then
        bannerOrderCounter += 1
        BannerStates[key] = {
            Key = textKey,
            Fallback = fallback,
            Color = color,
            Priority = priority or 0,
            Order = bannerOrderCounter,
        }
    else
        BannerStates[key] = nil
    end
    refreshStatusBanner()
end

local function clearBannerStates()
    for stateKey in pairs(BannerStates) do
        BannerStates[stateKey] = nil
    end
    refreshStatusBanner()
end

local function registerText(object, key, fallback, baseSize)
    TextRegistry[object] = {Key = key, Fallback = fallback}
    if baseSize then
        FontRegistry[object] = baseSize
    end
    object.Text = translate(key, fallback)
    if baseSize then
        object.TextSize = math.max(8, math.floor(baseSize * FontScale))
    end
end

local function refreshLocalization()
    for object, data in pairs(TextRegistry) do
        if object and object.Parent then
            object.Text = translate(data.Key, data.Fallback)
        else
            TextRegistry[object] = nil
        end
    end
    for object, base in pairs(FontRegistry) do
        if object and object.Parent then
            object.TextSize = math.max(8, math.floor(base * FontScale))
        else
            FontRegistry[object] = nil
        end
    end
end

local function setLanguage(lang)
    if Strings[lang] then
        CurrentLanguage = lang
        refreshLocalization()
        if updateResetButtonLabel then
            updateResetButtonLabel()
        end
        if languageCycle and languageCycle.SetOptions then
            languageCycle.SetOptions(buildLanguageOptions(), lang)
        end
        if updateSearchPlaceholder then
            updateSearchPlaceholder()
        end
        if updateKeyTimerLabel then
            updateKeyTimerLabel()
        end
        refreshStatusBanner()
    end
end

local function setFontScale(scale)
    FontScale = math.clamp(scale, 0.6, 1.6)
    refreshLocalization()
end

local function buildLanguageOptions()
    return {
        {label = translate("English", "English"), value = "EN"},
        {label = translate("Norsk", "Norsk"), value = "NO"},
    }
end

local PageRegistry = {}
local RowRegistry = {}
local CurrentPage = nil
local CurrentSearch = ""
local ActiveTabButton = nil
local TabIndicators = {}
local TabButtons = {}
local updateResetButtonLabel
local updateKeyTimerLabel
local crossPresetCycle
local languageCycle
local updateSearchPlaceholder
local StatusBanner
local lowImpactToggle
local currentTabIndex = 1
local controllerMode = UserInputService.GamepadEnabled
if controllerMode then
    GuiService.AutoSelectGuiEnabled = true
end

local function changeTab(offset)
    if #TabButtons == 0 then return end
    local newIndex = math.clamp(currentTabIndex + offset, 1, #TabButtons)
    if newIndex ~= currentTabIndex then
        local btn = TabButtons[newIndex]
        if btn then
            btn:Activate()
        end
    end
end
local SoundSettings = { Enabled = true }
local suppressSoundStack = 0

local PerformanceSettings = {
    LowImpact = false,
}

local UISoundLibrary = {
    toggleOn = "rbxassetid://9118823105",
    toggleOff = "rbxassetid://9118823476",
    slider = "rbxassetid://138081500",
    cycle = "rbxassetid://6026984224",
    confirm = "rbxassetid://6026984224",
}

local SoundCache = {}

local function playUISound(kind)
    if not SoundSettings.Enabled or suppressSoundStack > 0 then return end
    local asset = UISoundLibrary[kind]
    if not asset then return end
    local sound = SoundCache[kind]
    if not (sound and sound.Parent) then
        sound = Instance.new("Sound")
        sound.SoundId = asset
        sound.RollOffMaxDistance = 100
        sound.Volume = (kind == "confirm") and 0.75 or 0.45
        sound.Parent = SoundService
        SoundCache[kind] = sound
    end
    sound.PlaybackSpeed = 1
    sound.TimePosition = 0
    sound:Play()
end

local function registerPage(page, name)
    PageRegistry[page] = {Name = name, Controls = {}}
end

local function registerControl(parent, name, row, set, get, defaultValue, meta)
    local page = PageRegistry[parent]
    if not page then return end
    meta = meta or {}
    local control = meta.record or {}
    control.Name = name
    control.Row = row
    control.Set = set
    control.Get = get
    control.Default = defaultValue
    control.Desc = meta.desc or control.Desc or ""
    control.SkipReset = meta.skipReset or control.SkipReset
    control.SkipSearch = meta.skipSearch or control.SkipSearch
    control.Type = meta.type or control.Type or "control"
    control.CustomReset = meta.resetFunc or control.CustomReset
    control.ThemeKey = meta.themeKey or control.ThemeKey
    control.SearchText = string.lower((name or "") .. " " .. (control.Desc or ""))
    table.insert(page.Controls, control)
    RowRegistry[row] = control
    if CurrentSearch ~= "" then
        applySearch(CurrentSearch)
    end
end

local function resetPageControls(page)
    local info = PageRegistry[page]
    if not info then return end
    suppressSoundStack += 1
    for _, control in ipairs(info.Controls) do
        if control.CustomReset then
            control.CustomReset()
        elseif not control.SkipReset and control.Set and control.Default ~= nil then
            control.Set(control.Default)
        end
    end
    suppressSoundStack = math.max(0, suppressSoundStack - 1)
end

local function resetAllPages()
    for page, _ in pairs(PageRegistry) do
        resetPageControls(page)
    end
end

local function applySearch(term)
    CurrentSearch = string.lower(trim(term or ""))
    for row, control in pairs(RowRegistry) do
        if row and row.Parent then
            if control.SkipSearch or CurrentSearch == "" then
                row.Visible = true
            else
                local match = string.find(control.SearchText or "", CurrentSearch, 1, true)
                row.Visible = match ~= nil
            end
        else
            RowRegistry[row] = nil
        end
    end
end

local function safeParent()
    local ok, ui = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
    return (ok and ui) or LocalPlayer:WaitForChild("PlayerGui")
end

--// Utils
local function corner(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=o end
local function stroke(o,col,th,tr)
    local s=Instance.new("UIStroke")
    s.Color=col
    s.Thickness=th or 1
    s.Transparency=tr or 0
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    s.Parent=o
    return s
end
local function pad(o,p) local x=Instance.new("UIPadding"); x.PaddingTop=UDim.new(0,p); x.PaddingBottom=UDim.new(0,p); x.PaddingLeft=UDim.new(0,p); x.PaddingRight=UDim.new(0,p); x.Parent=o end
local function trim(s) s=tostring(s or ""):gsub("\r",""):gsub("\n",""):gsub("%s+$",""):gsub("^%s+",""); return s end
local function setInteractable(frame, on)
    for _,v in ipairs(frame:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            v.TextTransparency = on and 0 or 0.45
            if v:IsA("TextButton") then v.AutoButtonColor = on end
        elseif v:IsA("Frame") then
            v.BackgroundColor3 = on and v.BackgroundColor3 or T.Ink
        end
    end
    frame.Active = on
end

--==================== ACCESS OVERLAY ====================--
local Blur = Instance.new("BlurEffect"); Blur.Enabled=false; Blur.Size=0; Blur.Parent=Lighting

local Gate = Instance.new("ScreenGui")
Gate.Name="PC_Gate"; Gate.IgnoreGuiInset=true; Gate.ResetOnSpawn=false; Gate.ZIndexBehavior=Enum.ZIndexBehavior.Global
Gate.DisplayOrder=100; Gate.Parent=safeParent()

local Dim = Instance.new("Frame", Gate)
Dim.BackgroundColor3=Color3.new(0,0,0); Dim.BackgroundTransparency=0.35; Dim.Size=UDim2.fromScale(1,1)

local Card = Instance.new("Frame", Gate)
Card.Size=UDim2.fromOffset(600, 360); Card.AnchorPoint=Vector2.new(0.5,0.5); Card.Position=UDim2.fromScale(0.5,0.5)
Card.BackgroundColor3=T.Card; stroke(Card,T.Stroke,1,0.45); corner(Card,18); pad(Card,22)

local CardLayout = Instance.new("UIListLayout", Card)
CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
CardLayout.Padding   = UDim.new(0, 12)

local Hero = Instance.new("Frame", Card)
Hero.Name = "Hero"; Hero.Size = UDim2.new(1,0,0,128); Hero.LayoutOrder = 1; Hero.BackgroundColor3 = T.Accent; Hero.BackgroundTransparency = 0.7
Hero.ZIndex = 2; Hero.ClipsDescendants = true; corner(Hero,16); stroke(Hero,T.Stroke,1,0.28)

local heroGradient = Instance.new("UIGradient", Hero)
heroGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, T.Accent),
    ColorSequenceKeypoint.new(1, T.Neon)
})
heroGradient.Rotation = 28
heroGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.22),
    NumberSequenceKeypoint.new(1, 0.32)
})

local heroPad = Instance.new("UIPadding", Hero)
heroPad.PaddingTop = UDim.new(0, 18); heroPad.PaddingBottom = UDim.new(0, 18)
heroPad.PaddingLeft = UDim.new(0, 20); heroPad.PaddingRight = UDim.new(0, 20)

local heroLayout = Instance.new("UIListLayout", Hero)
heroLayout.SortOrder = Enum.SortOrder.LayoutOrder; heroLayout.Padding = UDim.new(0, 8)

local Pill = Instance.new("TextLabel", Hero)
Pill.BackgroundTransparency = 0.2; Pill.BackgroundColor3 = T.Ink; Pill.LayoutOrder = 1
Pill.Size = UDim2.new(0, 150, 0, 26); Pill.Font = Enum.Font.GothamBold; Pill.TextSize = 13
Pill.Text = "ACCESS PASS"; Pill.TextColor3 = T.Text; Pill.TextXAlignment = Enum.TextXAlignment.Center
Pill.ZIndex = 3
corner(Pill, 13); stroke(Pill, T.Stroke, 1, 0.5)

local Title = Instance.new("TextLabel", Hero)
Title.BackgroundTransparency=1; Title.Text="ProfitCruiser — Access Portal"; Title.Font=Enum.Font.GothamBlack; Title.TextSize=24; Title.TextColor3=T.Text
Title.Size=UDim2.new(1,0,0,34); Title.TextXAlignment=Enum.TextXAlignment.Left; Title.LayoutOrder = 2; Title.ZIndex = 3

local Hint = Instance.new("TextLabel", Hero)
Hint.BackgroundTransparency=1; Hint.Text="Paste your private key to unlock Aurora. Grab a new key or meet the crew on Discord for instant drops."; Hint.Font=Enum.Font.Gotham
Hint.TextSize=14; Hint.TextColor3=T.Text; Hint.TextWrapped=true; Hint.TextXAlignment=Enum.TextXAlignment.Left; Hint.TextYAlignment=Enum.TextYAlignment.Top
Hint.Size=UDim2.new(1,0,0,44); Hint.LayoutOrder = 3; Hint.ZIndex = 3

local Features = Instance.new("TextLabel", Hero)
Features.BackgroundTransparency = 1; Features.Text = "⚡ Rapid updates    🛡️ Anti-ban shielding    🎯 Elite aim assist"
Features.Font = Enum.Font.Gotham; Features.TextSize = 13; Features.TextColor3 = T.Subtle; Features.TextXAlignment = Enum.TextXAlignment.Left
Features.Size = UDim2.new(1,0,0,22); Features.LayoutOrder = 4; Features.ZIndex = 3

local InputSection = Instance.new("Frame", Card)
InputSection.BackgroundColor3 = T.Panel; InputSection.BackgroundTransparency = 0.05; InputSection.Size = UDim2.new(1,0,0,120)
InputSection.LayoutOrder = 2; corner(InputSection,14); stroke(InputSection,T.Stroke,1,0.28)

local inputPad = Instance.new("UIPadding", InputSection)
inputPad.PaddingTop = UDim.new(0, 14); inputPad.PaddingBottom = UDim.new(0, 14)
inputPad.PaddingLeft = UDim.new(0, 18); inputPad.PaddingRight = UDim.new(0, 18)

local inputLayout = Instance.new("UIListLayout", InputSection)
inputLayout.SortOrder = Enum.SortOrder.LayoutOrder; inputLayout.Padding = UDim.new(0, 8)

local KeyLabel = Instance.new("TextLabel", InputSection)
KeyLabel.BackgroundTransparency = 1; KeyLabel.Text = "Master Key"; KeyLabel.Font = Enum.Font.GothamMedium; KeyLabel.TextSize = 15
KeyLabel.TextColor3 = T.Text; KeyLabel.TextXAlignment = Enum.TextXAlignment.Left; KeyLabel.Size = UDim2.new(1,0,0,22)
KeyLabel.LayoutOrder = 1

local KeyBox = Instance.new("TextBox", InputSection)
KeyBox.Size=UDim2.new(1,0,0,40); KeyBox.Text=""; KeyBox.PlaceholderText="Paste key or drop to auto-fill…"
KeyBox.ClearTextOnFocus=false; KeyBox.Font=Enum.Font.Gotham; KeyBox.TextSize=16; KeyBox.TextColor3=T.Text
KeyBox.BackgroundColor3=T.Ink; stroke(KeyBox,T.Stroke,1,0.35); corner(KeyBox,12); KeyBox.LayoutOrder = 2

local KeyNote = Instance.new("TextLabel", InputSection)
KeyNote.BackgroundTransparency = 1; KeyNote.Text = "Keys rotate fast — confirm before the cycle resets. Discord pings fire instantly."
KeyNote.Font = Enum.Font.Gotham; KeyNote.TextSize = 12; KeyNote.TextColor3 = T.Subtle; KeyNote.TextWrapped = true
KeyNote.TextXAlignment = Enum.TextXAlignment.Left; KeyNote.TextYAlignment = Enum.TextYAlignment.Top
KeyNote.Size = UDim2.new(1,0,0,32); KeyNote.LayoutOrder = 3
bindTheme(KeyNote, "TextColor3", "Subtle")
FontRegistry[KeyNote] = 12

local KeyTimerLabel = Instance.new("TextLabel", InputSection)
KeyTimerLabel.BackgroundTransparency = 1
KeyTimerLabel.Font = Enum.Font.Gotham
KeyTimerLabel.TextSize = 12
KeyTimerLabel.TextColor3 = T.Subtle
KeyTimerLabel.Text = "Rotation resets in --:--"
KeyTimerLabel.TextWrapped = false
KeyTimerLabel.TextXAlignment = Enum.TextXAlignment.Left
KeyTimerLabel.Size = UDim2.new(1, 0, 0, 20)
KeyTimerLabel.LayoutOrder = 4
bindTheme(KeyTimerLabel, "TextColor3", "Subtle")
FontRegistry[KeyTimerLabel] = 12

local keyTimerEnd = os.clock() + KEY_ROTATION_SECONDS
local lastTimerUpdate = 0

updateKeyTimerLabel = function()
    local remaining = math.max(0, keyTimerEnd - os.clock())
    local minutes = math.floor(remaining / 60)
    local seconds = math.floor(remaining % 60)
    if KeyTimerLabel then
        KeyTimerLabel.Text = string.format(translate("Rotation resets in %02d:%02d", "Rotation resets in %02d:%02d"), minutes, seconds)
        if remaining <= 60 then
            KeyTimerLabel.TextColor3 = T.Warn
            setBannerState("key", "Key expiring soon", "Key expiring soon", "Warn", 4)
        else
            KeyTimerLabel.TextColor3 = T.Subtle
            setBannerState("key")
        end
    end
end

updateKeyTimerLabel()

RunService.Heartbeat:Connect(function()
    if os.clock() - lastTimerUpdate >= 1 then
        lastTimerUpdate = os.clock()
        updateKeyTimerLabel()
    end
end)

local Divider = Instance.new("Frame", Card)
Divider.BackgroundColor3 = T.Stroke; Divider.BackgroundTransparency = 0.55; Divider.Size = UDim2.new(1,0,0,1); Divider.LayoutOrder = 3

local Row = Instance.new("Frame", Card)
Row.BackgroundTransparency=1; Row.Size=UDim2.new(1,0,0,48); Row.LayoutOrder = 4

local rowLayout = Instance.new("UIListLayout", Row)
rowLayout.FillDirection = Enum.FillDirection.Horizontal; rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center; rowLayout.Padding = UDim.new(0, 14)

local function btn(text, style)
    local b=Instance.new("TextButton", Row); b.Text=text; b.Font=Enum.Font.GothamMedium; b.TextSize=15; b.TextColor3=T.Text
    b.AutoButtonColor=false; b.Size=UDim2.new(0,172,0,42); b.LayoutOrder = style == "primary" and 3 or 1
    local isPrimary = style == "primary"
    local baseColor = isPrimary and T.Accent or T.Ink
    local hoverColor = isPrimary and T.Neon or Color3.fromRGB(58, 52, 88)
    b.BackgroundColor3=baseColor; stroke(b,T.Stroke,1,0.35); corner(b,12)
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=hoverColor}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=baseColor}):Play() end)
    return b
end

local GetKey = btn("Get Key Link")
local Discord = btn("Join Discord")
local Confirm = btn("Unlock Panel", "primary")

local Status = Instance.new("TextLabel", Card)
Status.BackgroundColor3 = T.Ink; Status.BackgroundTransparency = 0.6; Status.Text=""; Status.Font=Enum.Font.Gotham
Status.TextSize=13; Status.TextColor3=T.Subtle; Status.Size=UDim2.new(1,0,0,28); Status.LayoutOrder = 5
Status.TextXAlignment=Enum.TextXAlignment.Center; Status.TextYAlignment = Enum.TextYAlignment.Center; corner(Status,12)
bindTheme(Status, "BackgroundColor3", "Ink")
bindTheme(Status, "TextColor3", "Subtle")
FontRegistry[Status] = 13

local function updateStatus(text, color)
    Status.Text = text
    Status.TextColor3 = color or T.Subtle
end

updateStatus("Paste your key to unlock ProfitCruiser.")

-- Success overlay in its own GUI so it survives hiding Gate
local SuccessGui = Instance.new("ScreenGui")
SuccessGui.Name = "PC_Success"; SuccessGui.IgnoreGuiInset = true; SuccessGui.ResetOnSpawn = false
SuccessGui.ZIndexBehavior = Enum.ZIndexBehavior.Global; SuccessGui.DisplayOrder = 110
SuccessGui.Parent = safeParent()

local Success = Instance.new("Frame", SuccessGui)
Success.Visible=false; Success.Size=UDim2.fromScale(1,1); Success.BackgroundTransparency=1
local Center = Instance.new("Frame", Success)
Center.Size=UDim2.fromOffset(420,220); Center.AnchorPoint=Vector2.new(0.5,0.5); Center.Position=UDim2.fromScale(0.5,0.5); Center.BackgroundColor3=T.Card
corner(Center,16); stroke(Center,T.Good,2,0)
local GG = Instance.new("TextLabel", Center)
GG.BackgroundTransparency=1; GG.Size=UDim2.fromScale(1,1); GG.Text="ACCESS GRANTED ✨"; GG.TextColor3=T.Good; GG.Font=Enum.Font.GothamBold; GG.TextSize=28

-- FLAG: only allow reveal of Root after overlay finished
local allowReveal = false

local function fetchRemoteKey()
    local ok,res=pcall(game.HttpGet,game,KEY_CHECK_URL)
    if not ok then return nil,res end
    local cleaned=trim(res); if #cleaned==0 then return nil,"empty" end
    return cleaned
end

GetKey.MouseButton1Click:Connect(function()
    playUISound("cycle")
    if typeof(setclipboard)=="function" then
        setclipboard(GET_KEY_URL)
        updateStatus("Key link copied to clipboard.", T.Neon)
    else
        updateStatus("Key link: "..GET_KEY_URL)
    end
end)
Discord.MouseButton1Click:Connect(function()
    playUISound("cycle")
    if typeof(setclipboard)=="function" then setclipboard(DISCORD_URL) end
    updateStatus("Discord invite copied — we'll see you inside!", T.Neon)
    if syn and syn.request then pcall(function() syn.request({Url=DISCORD_URL,Method="GET"}) end) end
end)

-- new showGranted supports callback after hide
local function showGranted(seconds, after)
    Success.Visible = true
    task.delay(seconds or 2.0, function()
        Success.Visible = false
        if after then pcall(after) end
    end)
end

Confirm.MouseButton1Click:Connect(function()
    updateStatus("Checking key…", T.Text)
    local expected,err = fetchRemoteKey()
    if not expected then updateStatus("Fetch failed: "..tostring(err or ""), T.Warn) return end

    if trim(KeyBox.Text) == expected then
        updateStatus("Accepted!", T.Good)
        playUISound("confirm")
        keyTimerEnd = os.clock() + KEY_ROTATION_SECONDS
        updateKeyTimerLabel()

        -- Immediately hide the gate UI so the key box is gone
        Gate.Enabled = false

        -- Ensure Root is hidden while we show the success overlay
        if Root then Root.Visible = false end

        -- Show blur and keep it while overlay is visible
        Blur.Enabled = true
        TweenService:Create(Blur, TweenInfo.new(0.2), {Size = 8}):Play()

        -- Show the granted overlay for 2s, then remove blur and reveal the panel
        showGranted(2.0, function()
            -- animate blur out
            TweenService:Create(Blur, TweenInfo.new(0.2), {Size = 0}):Play()
            task.delay(0.2, function() Blur.Enabled = false end)

            -- mark that reveal is allowed and show Root
            allowReveal = true
            if Root then Root.Visible = true end
        end)

    else
        updateStatus("Wrong key.", T.Warn)
    end
end)

Gate.Enabled=true
Blur.Enabled=true; TweenService:Create(Blur,TweenInfo.new(0.2),{Size=8}):Play()

-- Ensure AA_GUI is disabled when gate is open
Gate:GetPropertyChangedSignal("Enabled"):Connect(function()
    AA_GUI.Enabled = not Gate.Enabled
end)

--==================== MAIN APP ====================--
local App = Instance.new("ScreenGui")
App.Name="AuroraPanel"; App.IgnoreGuiInset=true; App.ResetOnSpawn=false; App.ZIndexBehavior=Enum.ZIndexBehavior.Global
App.DisplayOrder=50; App.Parent=safeParent()

local SafeFrame = Instance.new("Frame", App)
SafeFrame.Name = "SafeArea"
SafeFrame.BackgroundTransparency = 1
SafeFrame.Size = UDim2.fromScale(1, 1)

local SafePadding = Instance.new("UIPadding", SafeFrame)

local function applySafeArea()
    local inset = GuiService:GetSafeZoneInsets()
    SafePadding.PaddingLeft = UDim.new(0, inset.X)
    SafePadding.PaddingRight = UDim.new(0, inset.X)
    SafePadding.PaddingTop = UDim.new(0, inset.Y)
    SafePadding.PaddingBottom = UDim.new(0, inset.Y)
end

applySafeArea()

local function hookCameraSafeArea(cam)
    if not cam then return end
    cam:GetPropertyChangedSignal("ViewportSize"):Connect(applySafeArea)
end

if workspace.CurrentCamera then
    hookCameraSafeArea(workspace.CurrentCamera)
else
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        hookCameraSafeArea(workspace.CurrentCamera)
    end)
end

local SelectionImage = Instance.new("Frame")
SelectionImage.Name = "ControllerSelection"
SelectionImage.BackgroundTransparency = 1
SelectionImage.Size = UDim2.new(1, 12, 1, 12)
SelectionImage.AnchorPoint = Vector2.new(0.5, 0.5)
SelectionImage.Parent = App
local selectionStroke = stroke(SelectionImage, T.Neon, 2, 0.1)
selectionStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Outline
bindTheme(selectionStroke, "Color", "Neon")
GuiService.SelectionImageObject = SelectionImage

Root = Instance.new("Frame", SafeFrame)
Root.Size=UDim2.fromOffset(980, 600); Root.AnchorPoint=Vector2.new(0.5,0.5); Root.Position=UDim2.fromScale(0.5,0.5)
Root.BackgroundColor3=T.Card; corner(Root,16); stroke(Root,T.Stroke,1,0.45); pad(Root,12)
Root.Visible=false

local PanelScale = Instance.new("UIScale", Root)
PanelScale.Scale = 1

local Top = Instance.new("Frame", Root)
Top.Size=UDim2.new(1, -16, 0, 46); Top.Position=UDim2.new(0,8,0,8); Top.BackgroundColor3=T.Panel; corner(Top,12); stroke(Top,T.Stroke,1,0.45); pad(Top,10)

local TitleLbl = Instance.new("TextLabel", Top)
TitleLbl.Size=UDim2.new(1,0,1,0); TitleLbl.BackgroundTransparency=1; TitleLbl.TextXAlignment=Enum.TextXAlignment.Left
TitleLbl.Text="ProfitCruiser — Aurora Panel"; TitleLbl.Font=Enum.Font.GothamBold; TitleLbl.TextSize=18; TitleLbl.TextColor3=T.Text

StatusBanner = Instance.new("TextLabel", Root)
StatusBanner.Name = "StatusBanner"
StatusBanner.Size = UDim2.new(1, -16, 0, 30)
StatusBanner.Position = UDim2.new(0, 8, 0, 58)
StatusBanner.BackgroundColor3 = T.Panel
StatusBanner.BackgroundTransparency = 0.05
StatusBanner.Text = ""
StatusBanner.Font = Enum.Font.Gotham
StatusBanner.TextSize = 13
StatusBanner.TextColor3 = T.Subtle
StatusBanner.TextXAlignment = Enum.TextXAlignment.Left
StatusBanner.TextYAlignment = Enum.TextYAlignment.Center
StatusBanner.TextWrapped = true
StatusBanner.Visible = false
corner(StatusBanner, 10)
local bannerStroke = stroke(StatusBanner, T.Stroke, 1, 0.35)
bindTheme(StatusBanner, "BackgroundColor3", "Panel")
bindTheme(bannerStroke, "Color", "Stroke")
FontRegistry[StatusBanner] = 13
refreshStatusBanner()

if SAFE_MODE then
    setBannerState("safe", "SafeModeActive", "Safe mode active — runtime features are temporarily disabled to prevent crashes.", "Warn", 8)
end

-- drag
local draggingEnabled = true
local dragging,rel=false,Vector2.zero
Top.InputBegan:Connect(function(i) if draggingEnabled and i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; rel=Root.AbsolutePosition-UserInputService:GetMouseLocation() end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
RunService.RenderStepped:Connect(function()
    if dragging then
        local cam = currentCamera()
        if not cam then
            return
        end
        local vp=cam.ViewportSize; local m=UserInputService:GetMouseLocation()
        local nx=math.clamp(m.X+rel.X,8,vp.X-Root.AbsoluteSize.X-8); local ny=math.clamp(m.Y+rel.Y,8,vp.Y-Root.AbsoluteSize.Y-8)
        Root.Position=UDim2.fromOffset(nx,ny)
    end
end)



-- sidebar
local Side = Instance.new("Frame", Root)
Side.Size=UDim2.new(0, 210, 1, -106); Side.Position=UDim2.new(0,8,0,98)
Side.BackgroundColor3=T.Panel; corner(Side,12); stroke(Side,T.Stroke,1,0.45); pad(Side,8)
-- ensure tab buttons stack vertically (fix: only Aimbot showing)
local SideList = Instance.new("UIListLayout", Side)
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Padding   = UDim.new(0,8)

local Content = Instance.new("Frame", Root)
Content.Size=UDim2.new(1, -234, 1, -106)
Content.Position=UDim2.new(0, 226, 0, 98)
Content.BackgroundTransparency=1
Content.ClipsDescendants = true

local ToolsBar = Instance.new("Frame", Content)
ToolsBar.Name = "ToolsBar"
ToolsBar.Size = UDim2.new(1, 0, 0, 40)
ToolsBar.BackgroundTransparency = 0.05
corner(ToolsBar, 10)
local toolsStroke = stroke(ToolsBar, T.Stroke, 1, 0.45)
bindTheme(ToolsBar, "BackgroundColor3", "Panel")
bindTheme(toolsStroke, "Color", "Stroke")

local toolsPadding = Instance.new("UIPadding", ToolsBar)
toolsPadding.PaddingLeft = UDim.new(0, 12)
toolsPadding.PaddingRight = UDim.new(0, 12)
toolsPadding.PaddingTop = UDim.new(0, 8)
toolsPadding.PaddingBottom = UDim.new(0, 8)

local toolsLayout = Instance.new("UIListLayout", ToolsBar)
toolsLayout.FillDirection = Enum.FillDirection.Horizontal
toolsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
toolsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
toolsLayout.Padding = UDim.new(0, 10)

local SearchBox = Instance.new("TextBox", ToolsBar)
SearchBox.Name = "QuickSearch"
SearchBox.Size = UDim2.new(0.6, -20, 1, -4)
SearchBox.ClearTextOnFocus = false
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 14
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.TextYAlignment = Enum.TextYAlignment.Center
SearchBox.PlaceholderText = "Search settings…"
SearchBox.BackgroundColor3 = T.Ink
SearchBox.TextColor3 = T.Text
SearchBox.PlaceholderColor3 = T.Subtle
corner(SearchBox, 8)
local searchStroke = stroke(SearchBox, T.Stroke, 1, 0.35)
bindTheme(SearchBox, "BackgroundColor3", "Ink")
bindTheme(SearchBox, "TextColor3", "Text")
bindTheme(searchStroke, "Color", "Stroke")
FontRegistry[SearchBox] = 14
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    applySearch(SearchBox.Text)
end)
updateSearchPlaceholder = function()
    SearchBox.PlaceholderText = translate("QuickSearch", "Search") .. "…"
end
updateSearchPlaceholder()

local ResetTabButton = Instance.new("TextButton", ToolsBar)
ResetTabButton.Name = "ResetTab"
ResetTabButton.Size = UDim2.new(0, 140, 1, -4)
ResetTabButton.AutoButtonColor = false
ResetTabButton.Font = Enum.Font.GothamMedium
ResetTabButton.TextSize = 14
ResetTabButton.TextColor3 = T.Text
ResetTabButton.Text = "Reset"
ResetTabButton.BackgroundColor3 = T.Ink
corner(ResetTabButton, 8)
local resetStroke = stroke(ResetTabButton, T.Stroke, 1, 0.35)
bindTheme(ResetTabButton, "BackgroundColor3", "Ink")
bindTheme(ResetTabButton, "TextColor3", "Text")
bindTheme(resetStroke, "Color", "Stroke")

updateResetButtonLabel = function()
    if CurrentPage and PageRegistry[CurrentPage] then
        local info = PageRegistry[CurrentPage]
        local pageLabel = translate(info.Name .. " Tab", info.Name)
        ResetTabButton.Text = translate("Reset Tab", "Reset Tab") .. " — " .. pageLabel
        ResetTabButton.TextTransparency = 0
        ResetTabButton.Active = true
    else
        ResetTabButton.Text = translate("Reset Tab", "Reset Tab")
        ResetTabButton.TextTransparency = 0.35
        ResetTabButton.Active = false
    end
end

ResetTabButton.MouseButton1Click:Connect(function()
    if CurrentPage then
        resetPageControls(CurrentPage)
        playUISound("cycle")
    end
end)

local PagesHolder = Instance.new("Frame", Content)
PagesHolder.Name = "Pages"
PagesHolder.Size = UDim2.new(1, 0, 1, -48)
PagesHolder.Position = UDim2.new(0, 0, 0, 48)
PagesHolder.BackgroundTransparency = 1
PagesHolder.ClipsDescendants = true

local ColorOverlay = Instance.new("Frame", App)
ColorOverlay.Name = "ColorOverlay"
ColorOverlay.Visible = false
ColorOverlay.ZIndex = 350
ColorOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
ColorOverlay.BackgroundTransparency = 0.45
ColorOverlay.Size = UDim2.fromScale(1, 1)

local ColorPanel = Instance.new("Frame", ColorOverlay)
ColorPanel.Size = UDim2.fromOffset(320, 220)
ColorPanel.AnchorPoint = Vector2.new(0.5, 0.5)
ColorPanel.Position = UDim2.fromScale(0.5, 0.5)
ColorPanel.BackgroundColor3 = T.Card
corner(ColorPanel, 12)
local colorPanelStroke = stroke(ColorPanel, T.Stroke, 1, 0.35)
bindTheme(ColorPanel, "BackgroundColor3", "Card")
bindTheme(colorPanelStroke, "Color", "Stroke")

local colorPanelPad = Instance.new("UIPadding", ColorPanel)
colorPanelPad.PaddingTop = UDim.new(0, 16)
colorPanelPad.PaddingBottom = UDim.new(0, 16)
colorPanelPad.PaddingLeft = UDim.new(0, 16)
colorPanelPad.PaddingRight = UDim.new(0, 16)

local colorPanelLayout = Instance.new("UIListLayout", ColorPanel)
colorPanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
colorPanelLayout.Padding = UDim.new(0, 10)

local colorPanelTitle = Instance.new("TextLabel", ColorPanel)
colorPanelTitle.BackgroundTransparency = 1
colorPanelTitle.Font = Enum.Font.GothamBold
colorPanelTitle.TextSize = 16
colorPanelTitle.TextColor3 = T.Text
colorPanelTitle.Text = "Adjust Color"
colorPanelTitle.TextXAlignment = Enum.TextXAlignment.Left
bindTheme(colorPanelTitle, "TextColor3", "Text")
FontRegistry[colorPanelTitle] = 16

local colorInputs = {}
local channelNames = {"R", "G", "B"}
for _, channel in ipairs(channelNames) do
    local row = Instance.new("Frame", ColorPanel)
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 32)

    local label = Instance.new("TextLabel", row)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = T.Subtle
    label.Text = channel .. ":"
    label.Size = UDim2.new(0, 32, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    bindTheme(label, "TextColor3", "Subtle")
    FontRegistry[label] = 14

    local box = Instance.new("TextBox", row)
    box.Size = UDim2.new(1, -36, 1, 0)
    box.Position = UDim2.new(0, 36, 0, 0)
    box.Font = Enum.Font.Gotham
    box.TextSize = 14
    box.Text = "255"
    box.ClearTextOnFocus = false
    box.TextColor3 = T.Text
    box.BackgroundColor3 = T.Ink
    box.PlaceholderText = "0-255"
    corner(box, 8)
    local boxStroke = stroke(box, T.Stroke, 1, 0.35)
    bindTheme(box, "BackgroundColor3", "Ink")
    bindTheme(box, "TextColor3", "Text")
    bindTheme(boxStroke, "Color", "Stroke")
    FontRegistry[box] = 14
    colorInputs[channel] = box
end

local colorPreview = Instance.new("Frame", ColorPanel)
colorPreview.BackgroundColor3 = Color3.new(1, 1, 1)
colorPreview.Size = UDim2.new(1, 0, 0, 36)
corner(colorPreview, 10)
local previewStroke = stroke(colorPreview, T.Stroke, 1, 0.35)
bindTheme(previewStroke, "Color", "Stroke")

local colorButtonsRow = Instance.new("Frame", ColorPanel)
colorButtonsRow.BackgroundTransparency = 1
colorButtonsRow.Size = UDim2.new(1, 0, 0, 36)

local colorButtonsLayout = Instance.new("UIListLayout", colorButtonsRow)
colorButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
colorButtonsLayout.Padding = UDim.new(0, 10)

local function makeColorAction(text, themeKey)
    local btn = Instance.new("TextButton", colorButtonsRow)
    btn.Size = UDim2.new(0.5, -5, 1, 0)
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.Text = text
    btn.TextColor3 = T.Text
    btn.BackgroundColor3 = T.Accent
    corner(btn, 10)
    local bStroke = stroke(btn, T.Stroke, 1, 0.35)
    bindTheme(btn, "BackgroundColor3", themeKey or "Accent")
    bindTheme(btn, "TextColor3", "Text")
    bindTheme(bStroke, "Color", "Stroke")
    FontRegistry[btn] = 14
    return btn
end

local applyColorButton = makeColorAction("Apply", "Accent")
local cancelColorButton = makeColorAction("Cancel", "Ink")

local activeColorControl = nil
local activeThemeKey = nil

local function closeColorOverlay()
    ColorOverlay.Visible = false
    activeColorControl = nil
    activeThemeKey = nil
end

cancelColorButton.MouseButton1Click:Connect(function()
    playUISound("toggleOff")
    closeColorOverlay()
end)

ColorOverlay.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local pos = input.Position
        if not ColorPanel.AbsolutePosition or not ColorPanel.AbsoluteSize then return end
        local minX = ColorPanel.AbsolutePosition.X
        local minY = ColorPanel.AbsolutePosition.Y
        local maxX = minX + ColorPanel.AbsoluteSize.X
        local maxY = minY + ColorPanel.AbsoluteSize.Y
        if pos.X < minX or pos.X > maxX or pos.Y < minY or pos.Y > maxY then
            closeColorOverlay()
        end
    end
end)

applyColorButton.MouseButton1Click:Connect(function()
    if not activeColorControl then
        closeColorOverlay()
        return
    end
    local r = tonumber(colorInputs.R.Text) or 0
    local g = tonumber(colorInputs.G.Text) or 0
    local b = tonumber(colorInputs.B.Text) or 0
    local color = Color3.fromRGB(math.clamp(r,0,255), math.clamp(g,0,255), math.clamp(b,0,255))
    if activeColorControl.Set then
        activeColorControl.Set(color)
    end
    if activeThemeKey then
        setCustomThemeColor(activeThemeKey, color)
    end
    colorPreview.BackgroundColor3 = color
    playUISound("toggleOn")
    closeColorOverlay()
end)

local function openColorOverlay(control, themeKey, title)
    activeColorControl = control
    activeThemeKey = themeKey
    if title then
        colorPanelTitle.Text = title
    end
    local color = control and control.Get and control.Get() or Color3.new(1, 1, 1)
    colorInputs.R.Text = tostring(math.floor(color.R * 255 + 0.5))
    colorInputs.G.Text = tostring(math.floor(color.G * 255 + 0.5))
    colorInputs.B.Text = tostring(math.floor(color.B * 255 + 0.5))
    colorPreview.BackgroundColor3 = color
    ColorOverlay.Visible = true
end

ColorOverlay.Visible = false

-- two-column grid inside pages
local function newPage(name)
    local p = Instance.new("ScrollingFrame", PagesHolder)
    p.Name = name
    p.Size = UDim2.fromScale(1, 1)
    p.Visible = false
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ClipsDescendants = true
    p.Active = true
    p.ScrollingEnabled = true
    p.ScrollBarThickness = 4
    p.ScrollBarImageColor3 = T.Subtle
    p.ScrollBarImageTransparency = 0.15
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.ScrollingDirection = Enum.ScrollingDirection.Y

    local padding = Instance.new("UIPadding", p)
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 12)

    local grid = Instance.new("UIGridLayout", p)
    grid.CellPadding = UDim2.new(0, 12, 0, 12)
    grid.CellSize = UDim2.new(0.5, -6, 0, 64)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Left

    local function syncCanvas()
        local contentY = grid.AbsoluteContentSize.Y
        local viewportY = p.AbsoluteSize.Y
        local paddingY = padding.PaddingTop.Offset + padding.PaddingBottom.Offset
        local totalY = math.max(contentY + paddingY, viewportY)
        p.CanvasSize = UDim2.new(0, 0, 0, totalY)

        -- clamp current scroll position so we can always scroll back up
        local maxScroll = math.max(0, totalY - viewportY)
        local current = p.CanvasPosition
        if current.Y > maxScroll or current.Y < 0 then
            p.CanvasPosition = Vector2.new(current.X, math.clamp(current.Y, 0, maxScroll))
        end
    end

    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncCanvas)
    p:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncCanvas)
    task.defer(syncCanvas)

    registerPage(p, name)
    return p
end

local function tabButton(text, page)
    local b=Instance.new("TextButton", Side)
    b.Size=UDim2.new(1,0,0,40)
    b.Text=text
    b.Font=Enum.Font.Gotham
    b.TextSize=15
    b.TextColor3=T.Text
    b.BackgroundColor3=T.Ink
    b.AutoButtonColor=false
    b.Selectable = true
    corner(b,10)
    local tabStroke = stroke(b,T.Stroke,1,0.35)
    bindTheme(b, "BackgroundColor3", "Ink")
    bindTheme(b, "TextColor3", "Text")
    bindTheme(tabStroke, "Color", "Stroke")
    registerText(b, text .. " Tab", text, 15)
    local bar=Instance.new("Frame", b); bar.Size=UDim2.new(0,0,1,0); bar.Position=UDim2.new(0,0,0,0); bar.BackgroundColor3=T.Neon; corner(bar,10)
    bindTheme(bar, "BackgroundColor3", "Neon")
    TabIndicators[b] = bar
    local function activateTabButton()
        for _,c in ipairs(Content:GetChildren()) do
            if c:IsA("GuiObject") then
                c.Visible = false
            end
        end
        for _,x in ipairs(Side:GetChildren()) do
            if x:IsA("TextButton") then
                TweenService:Create(x,TweenInfo.new(0.12),{BackgroundColor3=T.Ink}):Play()
                local f=x:FindFirstChildOfClass("Frame"); if f then TweenService:Create(f,TweenInfo.new(0.12),{Size=UDim2.new(0,0,1,0)}):Play() end
            end
        end
        page.Visible=true
        if page:IsA("ScrollingFrame") then page.CanvasPosition = Vector2.new(0,0) end
        TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=T.Accent}):Play()
        TweenService:Create(bar,TweenInfo.new(0.12),{Size=UDim2.new(0,4,1,0)}):Play()
        CurrentPage = page
        ActiveTabButton = b
        local idxAttr = b:GetAttribute("TabIndex")
        if typeof(idxAttr) == "number" then
            currentTabIndex = idxAttr
        end
        updateResetButtonLabel()
        if controllerMode then
            GuiService.SelectedObject = b
        end
    end
    b.MouseButton1Click:Connect(activateTabButton)
    b.Activated:Connect(activateTabButton)
    local index = #TabButtons + 1
    TabButtons[index] = b
    b:SetAttribute("TabIndex", index)
    return b
end

-- floating tooltip bubble for control descriptions
local Tooltip = Instance.new("Frame", App)
Tooltip.Name = "ControlTooltip"
Tooltip.Visible = false
Tooltip.Active = false
Tooltip.ZIndex = 200
Tooltip.BackgroundColor3 = T.Panel
Tooltip.BackgroundTransparency = 0.05
Tooltip.Size = UDim2.fromOffset(220, 64)
Tooltip.ClipsDescendants = false
corner(Tooltip, 10)
local tooltipStroke = stroke(Tooltip, T.Stroke, 1, 0.2)
bindTheme(Tooltip, "BackgroundColor3", "Panel")
bindTheme(tooltipStroke, "Color", "Stroke")

local tooltipPad = Instance.new("UIPadding", Tooltip)
tooltipPad.PaddingTop = UDim.new(0, 8)
tooltipPad.PaddingBottom = UDim.new(0, 8)
tooltipPad.PaddingLeft = UDim.new(0, 12)
tooltipPad.PaddingRight = UDim.new(0, 12)

local tooltipText = Instance.new("TextLabel", Tooltip)
tooltipText.BackgroundTransparency = 1
tooltipText.Size = UDim2.new(1, 0, 1, 0)
tooltipText.Font = Enum.Font.Gotham
tooltipText.TextSize = 13
tooltipText.TextColor3 = T.Text
tooltipText.TextWrapped = true
tooltipText.TextXAlignment = Enum.TextXAlignment.Left
tooltipText.TextYAlignment = Enum.TextYAlignment.Top
tooltipText.ZIndex = Tooltip.ZIndex + 1
bindTheme(tooltipText, "TextColor3", "Text")
FontRegistry[tooltipText] = 13

local tooltipOwner = nil
local tooltipBounds = Vector2.new(Tooltip.Size.X.Offset, Tooltip.Size.Y.Offset)

local function updateTooltipPosition(x, y)
    local cam = currentCamera()
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local width = tooltipBounds.X
    local height = tooltipBounds.Y
    local px = math.clamp(x + 16, 8, vp.X - width - 8)
    local py = math.clamp(y + 20, 8, vp.Y - height - 8)
    Tooltip.Position = UDim2.fromOffset(px, py)
end

local function openTooltip(owner, text)
    tooltipOwner = owner
    tooltipText.Text = text
    local bounds = TextService:GetTextSize(text, tooltipText.TextSize, tooltipText.Font, Vector2.new(280, 800))
    local width = math.clamp(bounds.X + 24, 160, 320)
    local height = math.clamp(bounds.Y + 16, 32, 220)
    tooltipBounds = Vector2.new(width, height)
    Tooltip.Size = UDim2.fromOffset(width, height)
    Tooltip.Visible = true
    local mouse = UserInputService:GetMouseLocation()
    updateTooltipPosition(mouse.X, mouse.Y)
end

local function closeTooltip(owner)
    if tooltipOwner ~= owner then return end
    tooltipOwner = nil
    Tooltip.Visible = false
end

local function trackTooltip(owner, x, y)
    if tooltipOwner ~= owner then return end
    updateTooltipPosition(x, y)
end

Root:GetPropertyChangedSignal("Visible"):Connect(function()
    if not Root.Visible then
        tooltipOwner = nil
        Tooltip.Visible = false
    end
end)

-- Controls factory (compact, reused)
local function rowBase(parent, name, desc)
    local infoText = trim(desc or "")
    local hasDesc = infoText ~= ""
    local r = Instance.new("Frame", parent)
    r.BackgroundColor3 = T.Card
    local rowHeight = UserInputService.TouchEnabled and 74 or 64
    r.Size = UDim2.new(0.5, -6, 0, rowHeight)
    corner(r, 10)
    local rowStroke = stroke(r, T.Stroke, 1, 0.25)
    bindTheme(r, "BackgroundColor3", "Card")
    bindTheme(rowStroke, "Color", "Stroke")

    local labelOffset = hasDesc and 54 or 18
    local labelWidth = hasDesc and -210 or -176

    local l = Instance.new("TextLabel", r)
    l.BackgroundTransparency = 1
    l.Position = UDim2.new(0, labelOffset, 0, 0)
    l.Size = UDim2.new(1, labelWidth, 1, 0)
    l.Text = name
    l.TextColor3 = T.Text
    l.Font = Enum.Font.Gotham
    l.TextSize = 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextWrapped = true
    bindTheme(l, "TextColor3", "Text")
    registerText(l, name, name, 14)

    if hasDesc then
        local infoButton = Instance.new("TextButton", r)
        infoButton.Name = "Info"
        infoButton.Size = UDim2.fromOffset(26, 26)
        infoButton.Position = UDim2.new(0, 18, 0.5, -13)
        infoButton.BackgroundColor3 = T.Ink
        infoButton.AutoButtonColor = false
        infoButton.Text = "?"
        infoButton.Font = Enum.Font.GothamBold
        infoButton.TextSize = 16
        infoButton.TextColor3 = T.Subtle
        infoButton.ZIndex = 3
        corner(infoButton, 13)
        local infoStroke = stroke(infoButton, T.Stroke, 1, 0.45)
        bindTheme(infoButton, "BackgroundColor3", "Ink")
        bindTheme(infoButton, "TextColor3", "Subtle")
        bindTheme(infoStroke, "Color", "Stroke")

        local baseColor = infoButton.BackgroundColor3
        local baseText = infoButton.TextColor3

        infoButton.MouseEnter:Connect(function()
            TweenService:Create(infoButton, TweenInfo.new(0.12), {
                BackgroundColor3 = T.Accent,
                TextColor3 = T.Text,
            }):Play()
            openTooltip(infoButton, infoText)
        end)

        infoButton.MouseLeave:Connect(function()
            TweenService:Create(infoButton, TweenInfo.new(0.12), {
                BackgroundColor3 = baseColor,
                TextColor3 = baseText,
            }):Play()
            closeTooltip(infoButton)
        end)

        infoButton.MouseButton1Click:Connect(function()
            openTooltip(infoButton, infoText)
        end)

        infoButton.MouseMoved:Connect(function(x, y)
            trackTooltip(infoButton, x, y)
        end)
    end

    return r, l
end

local function mkToggle(parent, name, default, cb, desc)
    local r,_=rowBase(parent,name,desc)
    local sw=Instance.new("Frame", r); sw.Size=UDim2.new(0,68,0,28); sw.Position=UDim2.new(1,-84,0.5,-14); sw.BackgroundColor3=T.Ink; corner(sw,16); stroke(sw,T.Stroke,1,0.35)
    local k=Instance.new("Frame", sw); k.Size=UDim2.new(0,24,0,24); k.Position=UDim2.new(0,2,0.5,-12); k.BackgroundColor3=Color3.fromRGB(235,235,245); corner(k,12)
    local state = default
    local defaultValue = state
    local function set(v)
        local previous = state
        state=v
        TweenService:Create(k,TweenInfo.new(0.12),{Position=v and UDim2.new(1,-26,0.5,-12) or UDim2.new(0,2,0.5,-12)}):Play()
        TweenService:Create(sw,TweenInfo.new(0.12),{BackgroundColor3=v and T.Neon or T.Ink}):Play()
        if cb then cb(v,r) end
        if previous ~= v then
            playUISound(v and "toggleOn" or "toggleOff")
        end
    end
    sw.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            set(not state)
        elseif i.UserInputType == Enum.UserInputType.Gamepad1 and i.KeyCode == Enum.KeyCode.ButtonA then
            set(not state)
        end
    end)
    set(state)
    local control = {Row=r, Set=set, Get=function() return state end, Default = defaultValue, Type = "toggle"}
    registerControl(parent, name, r, set, control.Get, defaultValue, {desc = desc, type = "toggle", record = control})
    return control
end

local function mkSlider(parent, name, min, max, default, cb, unit, desc)
    local r,l=rowBase(parent,name,desc)
    local hasDesc = trim(desc or "") ~= ""
    local sliderLeft = hasDesc and 54 or 18
    local valueWidth = 110
    local rightPadding = 28

    l.Position = UDim2.new(0, sliderLeft, 0, 6)
    l.Size = UDim2.new(1, -(sliderLeft + valueWidth + rightPadding), 0, 26)
    l.TextYAlignment = Enum.TextYAlignment.Top

    local v=Instance.new("TextLabel", r); v.BackgroundTransparency=1; v.Size=UDim2.new(0,valueWidth,0,24); v.Position=UDim2.new(1,-valueWidth-18,0,6)
    v.Text=""; v.TextColor3=T.Subtle; v.Font=Enum.Font.Gotham; v.TextSize=14; v.TextXAlignment=Enum.TextXAlignment.Right
    v.TextYAlignment = Enum.TextYAlignment.Top

    local bar=Instance.new("Frame", r); bar.Size=UDim2.new(1, -(sliderLeft + valueWidth + rightPadding), 0, 6); bar.Position=UDim2.new(0,sliderLeft,0,38); bar.BackgroundColor3=T.Ink; corner(bar,4)
    local fill=Instance.new("Frame", bar); fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=T.Neon; corner(fill,4)

    local defaultValue = math.clamp(default or min, min, max)
    local val=defaultValue
    local function render()
        local a=(val-min)/(max-min)
        fill.Size=UDim2.new(a,0,1,0)
        local u = unit and (" "..unit) or ""
        v.Text = (math.floor(val*100+0.5)/100)..u
    end
    local dragging=false
    bar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local m=UserInputService:GetMouseLocation().X; local x=bar.AbsolutePosition.X; local w=bar.AbsoluteSize.X
            local a=math.clamp((m-x)/w,0,1); val=min + a*(max-min); render(); if cb then cb(val,r) end
        end
    end)
    render()
    local function getter()
        return val
    end
    local function setter(x)
        local before = val
        val=math.clamp(x,min,max)
        render()
        if cb then cb(val,r) end
        if math.abs((before or 0) - val) > 1e-4 then
            playUISound("slider")
        end
    end
    local control = {
        Row = r,
        Set = setter,
        Get = getter,
        Default = defaultValue,
        Min = min,
        Max = max,
        Type = "slider",
    }
    registerControl(parent, name, r, setter, getter, defaultValue, {desc = desc, type = "slider", record = control})
    return control
end

-- simple button control (used for Kill Menu)
local function mkButton(parent, name, onClick, opts, desc)
    local r,_ = rowBase(parent, name, desc)
    -- make the label take full width, then place a button pill on the right
    local btn = Instance.new("TextButton", r)
    btn.Size = UDim2.new(0, 120, 0, 30)
    btn.Position = UDim2.new(1, -132, 0.5, -15)
    opts = opts or {}
    local danger = opts.danger
    local buttonText = opts.buttonText or (danger and "Kill Menu" or "Run")
    local baseColor = opts.backgroundColor or (danger and Color3.fromRGB(170, 60, 70) or T.Ink)
    local hoverColor = opts.hoverColor or (danger and Color3.fromRGB(200, 75, 85) or T.Accent)
    local textColor = opts.textColor or (danger and Color3.fromRGB(255,235,235) or T.Text)
    btn.Text = buttonText
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.TextColor3 = textColor
    btn.BackgroundColor3 = baseColor
    btn.AutoButtonColor = false
    corner(btn, 10)
    stroke(btn, (danger and Color3.fromRGB(200,80,90)) or opts.strokeColor or T.Stroke, 1, 0.35)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = hoverColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = baseColor}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if onClick then onClick(r) end
    end)
    return {Row=r, Button=btn}
end

local function mkCycle(parent, name, options, default, cb, desc)
    local r,_ = rowBase(parent, name, desc)
    local btn = Instance.new("TextButton", r)
    btn.Size = UDim2.new(0, 120, 0, 30)
    btn.Position = UDim2.new(1, -132, 0.5, -15)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.TextColor3 = T.Text
    btn.BackgroundColor3 = T.Ink
    btn.AutoButtonColor = false
    corner(btn, 10)
    stroke(btn, T.Stroke, 1, 0.35)

    local normalized = {}

    local function rebuild(opts)
        table.clear(normalized)
        for i,opt in ipairs(opts) do
            if typeof(opt) == "table" then
                normalized[i] = {
                    label = opt.label or opt.text or tostring(opt.value),
                    value = opt.value,
                }
            else
                normalized[i] = {label = tostring(opt), value = opt}
            end
        end
    end

    rebuild(options)

    local function findIndexByValue(val)
        for i,opt in ipairs(normalized) do
            if opt.value == val then return i end
        end
        return nil
    end

    local idx = 1
    if default ~= nil then
        if typeof(default) == "number" and normalized[default] then
            idx = default
        else
            idx = findIndexByValue(default) or idx
        end
    end

    local function apply(index)
        if #normalized == 0 then return end
        idx = ((index - 1) % #normalized) + 1
        local opt = normalized[idx]
        btn.Text = opt.label
        if cb then cb(opt.value, r) end
    end

    btn.MouseButton1Click:Connect(function()
        apply(idx + 1)
    end)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = T.Accent}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = T.Ink}):Play()
    end)

    apply(idx)

    local function getter()
        if normalized[idx] then return normalized[idx].value end
    end
    local function setter(value)
        local targetIndex
        if typeof(value) == "number" and normalized[value] then
            targetIndex = value
        else
            targetIndex = findIndexByValue(value)
        end
        if targetIndex then
            local previous = getter()
            apply(targetIndex)
            if previous ~= getter() then
                playUISound("cycle")
            end
        end
    end
    local control = {
        Row = r,
        Set = setter,
        Get = getter,
        Default = getter(),
        Options = normalized,
        Type = "cycle",
    }
    function control.SetOptions(opts, defaultValue)
        rebuild(opts)
        if defaultValue ~= nil then
            setter(defaultValue)
        else
            idx = math.clamp(idx, 1, math.max(1, #normalized))
            apply(idx)
        end
    end

    registerControl(parent, name, r, setter, getter, control.Default, {desc = desc, type = "cycle", record = control})
    return control
end

local function mkThemeColor(parent, name, themeKey, desc)
    local row,_ = rowBase(parent, name, desc)
    local preview = Instance.new("Frame", row)
    preview.Size = UDim2.new(0, 36, 0, 36)
    preview.Position = UDim2.new(1, -44, 0.5, -18)
    preview.BackgroundColor3 = T[themeKey]
    corner(preview, 8)
    local previewStroke = stroke(preview, T.Stroke, 1, 0.3)
    bindTheme(previewStroke, "Color", "Stroke")

    local edit = Instance.new("TextButton", row)
    edit.Size = UDim2.new(0, 90, 0, 30)
    edit.Position = UDim2.new(1, -150, 0.5, -15)
    edit.AutoButtonColor = false
    edit.Font = Enum.Font.GothamMedium
    edit.TextSize = 13
    edit.Text = "Edit"
    edit.TextColor3 = T.Text
    edit.BackgroundColor3 = T.Ink
    corner(edit, 10)
    local editStroke = stroke(edit, T.Stroke, 1, 0.3)
    bindTheme(edit, "BackgroundColor3", "Ink")
    bindTheme(edit, "TextColor3", "Text")
    bindTheme(editStroke, "Color", "Stroke")

    local currentColor = T[themeKey]

    local control = {
        Row = row,
        ThemeKey = themeKey,
        Default = currentColor,
    }

    function control.Set(color, skipOverride)
        currentColor = color
        preview.BackgroundColor3 = color
        if not skipOverride then
            setCustomThemeColor(themeKey, color)
        end
    end

    function control.Get()
        return currentColor
    end

    function control.CustomReset()
        setCustomThemeColor(themeKey, nil)
        currentColor = T[themeKey]
        preview.BackgroundColor3 = currentColor
    end

    edit.MouseButton1Click:Connect(function()
        playUISound("cycle")
        openColorOverlay(control, themeKey, "Edit " .. name)
    end)

    ThemeColorControls[#ThemeColorControls + 1] = control
    registerControl(parent, name, row, function(color)
        control.Set(color)
    end, control.Get, currentColor, {desc = desc, type = "color", record = control, resetFunc = control.CustomReset, themeKey = themeKey})
    return control
end

--==================== FEATURE STATE ====================--
local AA={
    Enabled=false,
    Strength=0.15,
    PartName="Head",
    ShowFOV=false,
    FOVRadiusPx=180,
    MaxDistance=250,
    MinDistance=0,
    Deadzone=4,
    RequireRMB=false,
    WallCheck=true,
    DynamicPart=false,
    StickyAim=false,
    StickTime=0.35,
    AdaptiveSmoothing=false,
    CloseRangeBoost=0.2,
    Prediction=0,
    TargetSort="Hybrid",
    DistanceWeight=0.02,
    ReactionDelay=0,
    ReactionJitter=0,
    VerticalOffset=0,
}
local ESP={
    Enabled=false,
    EnemiesOnly=false,
    UseDistance=true,
    MaxDistance=1200,
    EnemyColor=Color3.fromRGB(255,70,70),
    FriendColor=Color3.fromRGB(0,255,140),
    NeutralColor=Color3.fromRGB(255,255,0),
    FillTransparency=0.5,
    OutlineTransparency=0,
    ThroughWalls=true,
    ColorIntensity=1,
}
local Cross={
    Enabled=false,
    Color=Color3.fromRGB(0,255,200),
    Opacity=0.9,
    Size=8,
    Gap=4,
    Thickness=2,
    CenterDot=false,
    DotSize=2,
    DotOpacity=1,
    UseTeamColor=false,
    Rainbow=false,
    RainbowSpeed=1,
    Pulse=false,
    PulseSpeed=2.5,
}

local CrosshairPresets = {
    {
        label = "Baseline",
        data = {
            Color = Color3.fromRGB(0, 255, 200),
            Opacity = 0.9,
            Size = 8,
            Gap = 4,
            Thickness = 2,
            CenterDot = false,
            DotSize = 2,
            DotOpacity = 1,
            UseTeamColor = false,
            Rainbow = false,
            RainbowSpeed = 1,
            Pulse = false,
            PulseSpeed = 2.5,
        },
    },
    {
        label = "Tight Beam",
        data = {
            Color = Color3.fromRGB(255, 120, 90),
            Opacity = 0.85,
            Size = 6,
            Gap = 2,
            Thickness = 2,
            CenterDot = true,
            DotSize = 2,
            DotOpacity = 0.9,
            UseTeamColor = false,
            Rainbow = false,
            Pulse = false,
        },
    },
    {
        label = "Soft Pulse",
        data = {
            Color = Color3.fromRGB(160, 105, 255),
            Opacity = 0.75,
            Size = 10,
            Gap = 5,
            Thickness = 3,
            CenterDot = false,
            DotOpacity = 1,
            UseTeamColor = false,
            Rainbow = false,
            Pulse = true,
            PulseSpeed = 1.8,
        },
    },
    {
        label = "Team Lock",
        data = {
            Opacity = 1,
            Size = 9,
            Gap = 3,
            Thickness = 2,
            CenterDot = true,
            DotSize = 3,
            DotOpacity = 1,
            UseTeamColor = true,
            Rainbow = false,
            Pulse = false,
        },
    },
}

local UserCrosshairPresets = {}
local currentCrossPreset = "Custom"
local crossApplyingPreset = false

local function crossChanged()
    if crossApplyingPreset then return end
    currentCrossPreset = "Custom"
    if crossPresetCycle and crossPresetCycle.Set then
        crossPresetCycle.Set(nil)
    end
end

local Keybinds = {
    ToggleUI = {
        name = "Toggle UI",
        key = Enum.KeyCode.K,
        default = Enum.KeyCode.K,
        description = "Toggle the main interface on and off.",
    },
    Panic = {
        name = "Panic Hotkey",
        key = Enum.KeyCode.P,
        default = Enum.KeyCode.P,
        description = "Quickly disable visuals and close the UI.",
    },
}

local KeybindControls = {}
local activeRebind = nil
local activeRebindConn = nil

local function stopActiveRebind()
    if activeRebindConn then
        activeRebindConn:Disconnect()
        activeRebindConn = nil
    end
    if activeRebind and activeRebind.Button and activeRebind.Bind then
        activeRebind.Button.Text = activeRebind.Bind.key.Name
    end
    activeRebind = nil
end

local function beginRebind(id, button)
    local bind = Keybinds[id]
    if not bind then return end
    stopActiveRebind()
    button.Text = "Press key…"
    activeRebind = {Id = id, Button = button, Bind = bind}
    activeRebindConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        bind.key = input.KeyCode
        button.Text = input.KeyCode.Name
        playUISound("toggleOn")
        stopActiveRebind()
    end)
    task.delay(6, function()
        if activeRebind and activeRebind.Id == id then
            stopActiveRebind()
        end
    end)
end

local function createKeybindRow(parent, id, bind)
    local row,_ = rowBase(parent, bind.name, bind.description)
    local button = Instance.new("TextButton", row)
    button.Size = UDim2.new(0, 120, 0, 30)
    button.Position = UDim2.new(1, -132, 0.5, -15)
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 14
    button.TextColor3 = T.Text
    button.BackgroundColor3 = T.Ink
    button.AutoButtonColor = false
    corner(button, 10)
    local bStroke = stroke(button, T.Stroke, 1, 0.3)
    bindTheme(button, "BackgroundColor3", "Ink")
    bindTheme(button, "TextColor3", "Text")
    bindTheme(bStroke, "Color", "Stroke")
    FontRegistry[button] = 14

    local control = {Row = row, Default = bind.default}
    function control.Set(code)
        bind.key = code or bind.default
        button.Text = bind.key.Name
    end
    function control.Get()
        return bind.key
    end
    function control.CustomReset()
        control.Set(bind.default)
    end

    button.MouseButton1Click:Connect(function()
        playUISound("cycle")
        beginRebind(id, button)
    end)

    control.Set(bind.key)
    KeybindControls[id] = control
    registerControl(parent, bind.name, row, function(code)
        control.Set(code)
    end, control.Get, bind.default, {desc = bind.description, record = control, resetFunc = control.CustomReset})
end

local function captureCrossState()
    return {
        Color = Cross.Color,
        Opacity = Cross.Opacity,
        Size = Cross.Size,
        Gap = Cross.Gap,
        Thickness = Cross.Thickness,
        CenterDot = Cross.CenterDot,
        DotSize = Cross.DotSize,
        DotOpacity = Cross.DotOpacity,
        UseTeamColor = Cross.UseTeamColor,
        Rainbow = Cross.Rainbow,
        RainbowSpeed = Cross.RainbowSpeed,
        Pulse = Cross.Pulse,
        PulseSpeed = Cross.PulseSpeed,
    }
end

local function buildCrossPresetOptions()
    local opts = {}
    for _, preset in ipairs(CrosshairPresets) do
        table.insert(opts, {label = preset.label, value = preset})
    end
    for _, preset in ipairs(UserCrosshairPresets) do
        table.insert(opts, {label = preset.label .. " ★", value = preset})
    end
    table.insert(opts, {label = "Custom", value = nil})
    return opts
end

local function applyCrossPreset(presetRecord)
    if not presetRecord then return end
    local data = presetRecord.data or presetRecord
    crossApplyingPreset = true
    suppressSoundStack += 1
    for key, control in pairs(CrossControlMap) do
        if data[key] ~= nil and control and control.Set then
            control.Set(data[key])
        end
    end
    suppressSoundStack = math.max(0, suppressSoundStack - 1)
    if data.Color then
        Cross.Color = data.Color
    end
    crossApplyingPreset = false
    updCross()
    currentCrossPreset = presetRecord.label or "Preset"
end

--==================== RUNTIME / DRAW ====================--
-- FOV ring
local AA_GUI=Instance.new("ScreenGui"); AA_GUI.Name="PC_FOV"; AA_GUI.IgnoreGuiInset=true; AA_GUI.ResetOnSpawn=false; AA_GUI.DisplayOrder=45; AA_GUI.Parent=safeParent()
local FOV=Instance.new("Frame", AA_GUI); FOV.AnchorPoint=Vector2.new(0.5,0.5); FOV.Position=UDim2.fromScale(0.5,0.5); FOV.BackgroundTransparency=1; FOV.Visible=false
local FStroke=Instance.new("UIStroke", FOV); FStroke.Thickness=2; FStroke.Transparency=0.15; FStroke.Color=Color3.fromRGB(0,255,140); corner(FOV, math.huge)
bindTheme(FStroke, "Color", "Neon")
local fovSliderControl
local draggingFOV = false

local function updateFOVRadiusFromMouse()
    if not fovSliderControl then return end
    local min = fovSliderControl.Min or 40
    local max = fovSliderControl.Max or 500
    local center = FOV.AbsolutePosition + FOV.AbsoluteSize * 0.5
    local mouse = UserInputService:GetMouseLocation()
    local offset = Vector2.new(mouse.X, mouse.Y) - center
    local radius = math.clamp(offset.Magnitude, min, max)
    fovSliderControl.Set(radius)
end

FOV.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingFOV = true
        updateFOVRadiusFromMouse()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingFOV = false
    end
end)

RunService.RenderStepped:Connect(function()
    if SAFE_MODE then
        if FOV.Visible then
            FOV.Visible = false
        end
        draggingFOV = false
        return
    end
    if draggingFOV then
        updateFOVRadiusFromMouse()
    end
end)

-- Crosshair
local CrossGui=Instance.new("ScreenGui"); CrossGui.Name="PC_Crosshair"; CrossGui.IgnoreGuiInset=true; CrossGui.ResetOnSpawn=false; CrossGui.DisplayOrder=44; CrossGui.Parent=safeParent()
local function crossPart() local f=Instance.new("Frame"); f.BorderSizePixel=0; f.Parent=CrossGui; f.Visible=false; return f end
local chL,chR,chU,chD = crossPart(),crossPart(),crossPart(),crossPart()
local dot = crossPart()
local function updCross()
    local cam = currentCamera()
    if not cam then
        for _,f in ipairs({chL,chR,chU,chD,dot}) do
            f.Visible = false
        end
        return
    end
    if not Cross.Enabled then
        for _,f in ipairs({chL,chR,chU,chD,dot}) do f.Visible=false end
        return
    end
    local vp=cam.ViewportSize; local cx,cy=vp.X*0.5,vp.Y*0.5; local g,s,t=Cross.Gap,Cross.Size,Cross.Thickness

    local color = Cross.Color
    if Cross.Rainbow then
        local h = (os.clock() * math.max(Cross.RainbowSpeed, 0)) % 1
        color = Color3.fromHSV(h, 0.9, 1)
    elseif Cross.UseTeamColor and LocalPlayer.TeamColor then
        color = LocalPlayer.TeamColor.Color
    end

    local pulseFactor = 1
    if Cross.Pulse then
        local wave = math.sin(os.clock() * math.max(Cross.PulseSpeed, 0.01) * math.pi * 2) * 0.5 + 0.5
        pulseFactor = 0.6 + 0.4 * wave
    end

    local baseOpacity = math.clamp(Cross.Opacity * pulseFactor, 0, 1)
    local dotOpacity = math.clamp(Cross.DotOpacity * pulseFactor, 0, 1)

    local function sty(f,opa)
        f.BackgroundColor3=color
        f.BackgroundTransparency=1-math.clamp(opa or baseOpacity,0,1)
    end
    chU.Size=UDim2.fromOffset(t,s); chU.Position=UDim2.fromOffset(cx - t/2, cy - g - s)
    chD.Size=UDim2.fromOffset(t,s); chD.Position=UDim2.fromOffset(cx - t/2, cy + g)
    chL.Size=UDim2.fromOffset(s,t); chL.Position=UDim2.fromOffset(cx - g - s, cy - t/2)
    chR.Size=UDim2.fromOffset(s,t); chR.Position=UDim2.fromOffset(cx + g, cy - t/2)
    for _,f in ipairs({chL,chR,chU,chD}) do sty(f); f.Visible=true end
    dot.Size=UDim2.fromOffset(Cross.DotSize,Cross.DotSize); dot.Position=UDim2.fromOffset(cx - Cross.DotSize/2, cy - Cross.DotSize/2); sty(dot, dotOpacity); dot.Visible=Cross.CenterDot
end
local crossAccumulator = 0
RunService.RenderStepped:Connect(function(dt)
    if SAFE_MODE then
        for _,f in ipairs({chL,chR,chU,chD,dot}) do
            f.Visible = false
        end
        return
    end
    if PerformanceSettings.LowImpact then
        crossAccumulator += dt
        if crossAccumulator < 0.05 then
            return
        end
        crossAccumulator = 0
    else
        crossAccumulator = 0
    end
    updCross()
end)

-- Targeting helpers
local function isEnemy(p) if p==LocalPlayer then return false end if LocalPlayer.Team and p.Team then return LocalPlayer.Team~=p.Team end return true end
local function aimPart(c)
    if not c then return nil end
    if AA.DynamicPart then
        for _,name in ipairs({"Head","UpperTorso","HumanoidRootPart","Torso"}) do
            local part=c:FindFirstChild(name)
            if part and part:IsA("BasePart") then return part end
        end
    end
    local p=c:FindFirstChild(AA.PartName)
    if not(p and p:IsA("BasePart")) then p=(c:FindFirstChild("UpperTorso") or c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head")) end
    return p
end
local function hasLOS(part,char)
    if not AA.WallCheck then return true end
    local cam = currentCamera()
    if not cam then
        return false
    end
    local origin=cam.CFrame.Position; local dir=(part.Position-origin)
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances={LocalPlayer.Character, char}; rp.IgnoreWater=true
    return workspace:Raycast(origin, dir, rp)==nil
end
local function buildCandidate(pl, my, cx, cy)
    if not isEnemy(pl) then return nil end
    local char = pl.Character
    if not char then return nil end
    local part = aimPart(char)
    if not part then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local maxDist = math.max(0, AA.MaxDistance or 0)
    local minDist = math.clamp(AA.MinDistance or 0, 0, maxDist)
    local dist = (hrp.Position-my.Position).Magnitude
    if dist > maxDist or dist < minDist then return nil end
    local cam = currentCamera()
    if not cam then
        return nil
    end
    local sp,on = cam:WorldToViewportPoint(part.Position)
    if not on then return nil end
    local dx,dy = sp.X-cx, sp.Y-cy
    local pd = (dx*dx+dy*dy)^0.5
    if pd>AA.FOVRadiusPx then return nil end
    if not hasLOS(part, char) then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return {
        player = pl,
        character = char,
        part = part,
        hrp = hrp,
        humanoid = hum,
        distance = dist,
        pixelDist = pd,
        screen = Vector2.new(sp.X, sp.Y),
        velocity = (hrp.AssemblyLinearVelocity or part.AssemblyLinearVelocity or Vector3.zero),
    }
end
local function scoreCandidate(info)
    local mode = AA.TargetSort or "Hybrid"
    if mode == "Distance" then
        return info.distance
    elseif mode == "Health" then
        local hum = info.humanoid
        if hum then return hum.Health end
        return math.huge
    elseif mode == "Angle" then
        return info.pixelDist
    else
        local w = math.clamp(AA.DistanceWeight or 0, 0, 0.25)
        return info.pixelDist + info.distance * w
    end
end
local function getTarget()
    local my=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not my then return nil end
    local cam = currentCamera()
    if not cam then
        return nil
    end
    local cx,cy=cam.ViewportSize.X/2, cam.ViewportSize.Y/2; local best,bScore
    for _,pl in ipairs(Players:GetPlayers()) do
        local info = buildCandidate(pl, my, cx, cy)
        if info then
            local sc = scoreCandidate(info)
            if not bScore or sc < bScore then
                best,bScore = info,sc
            end
        end
    end
    return best
end

local stickyTarget, stickyTimer = nil, 0
local rng = Random.new()
local lastTargetPart, reactionTimer = nil, 0
local function validateTarget(info)
    return info and info.part and info.part:IsDescendantOf(workspace)
end
local function refreshTarget(info)
    if not validateTarget(info) then return nil end
    local player = info.player
    if not player then return nil end
    local char = player.Character
    if not char then return nil end
    info.character = char
    info.part = info.part and info.part.Parent and info.part or aimPart(char)
    if not info.part then return nil end
    info.hrp = char:FindFirstChild("HumanoidRootPart")
    if not info.hrp then return nil end
    info.humanoid = char:FindFirstChildOfClass("Humanoid")
    local my = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not my then return nil end
    local maxDist = math.max(0, AA.MaxDistance or 0)
    local minDist = math.clamp(AA.MinDistance or 0, 0, maxDist)
    info.distance = (info.hrp.Position - my.Position).Magnitude
    if info.distance > maxDist or info.distance < minDist then return nil end
    local cam = currentCamera()
    if not cam then
        return nil
    end
    local sp,on = cam:WorldToViewportPoint(info.part.Position)
    info.screen = Vector2.new(sp.X, sp.Y)
    local cx,cy = cam.ViewportSize.X/2, cam.ViewportSize.Y/2
    local dx,dy = sp.X-cx, sp.Y-cy
    info.pixelDist = (dx*dx+dy*dy)^0.5
    if AA.WallCheck and not hasLOS(info.part, char) then return nil end
    info.onScreen = on
    info.velocity = (info.hrp.AssemblyLinearVelocity or info.part.AssemblyLinearVelocity or Vector3.zero)
    return info
end

-- Main render
RunService.RenderStepped:Connect(function(dt)
    if SAFE_MODE then
        FOV.Visible = false
        stickyTarget = nil
        reactionTimer = 0
        lastTargetPart = nil
        return
    end

    local cam = currentCamera()
    if not cam then
        FOV.Visible = false
        return
    end

    local fovRadius = math.max(0, AA.FOVRadiusPx or 0)
    FOV.Visible = (AA.Enabled and AA.ShowFOV)
    FOV.Size    = UDim2.fromOffset(fovRadius*2, fovRadius*2)

    local aiming = AA.Enabled and (not AA.RequireRMB or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
    if aiming then
        local candidate = getTarget()
        if AA.StickyAim then
            if candidate then
                stickyTarget = candidate
                stickyTimer = AA.StickTime
            else
                stickyTimer = math.max(0, stickyTimer - dt)
                if stickyTimer <= 0 then
                    stickyTarget = nil
                end
            end
        else
            stickyTarget = nil
            stickyTimer = 0
        end

        if stickyTarget then
            stickyTarget = refreshTarget(stickyTarget)
            if not stickyTarget then
                stickyTimer = 0
            end
        end

        local targetInfo = stickyTarget or candidate
        if targetInfo and not validateTarget(targetInfo) then
            targetInfo = nil
            if stickyTarget and not validateTarget(stickyTarget) then
                stickyTarget = nil
                stickyTimer = 0
            end
        end

        if targetInfo then
            if targetInfo.part ~= lastTargetPart then
                lastTargetPart = targetInfo.part
                local delay = math.max(0, AA.ReactionDelay or 0)
                local jitter = math.max(0, AA.ReactionJitter or 0)
                if jitter > 0 then
                    delay = delay + rng:NextNumber(0, jitter)
                end
                reactionTimer = delay
            end

            if reactionTimer > 0 then
                reactionTimer = math.max(0, reactionTimer - dt)
            else
                local pos = cam.CFrame.Position
                local targetPos = targetInfo.part.Position + Vector3.new(0, AA.VerticalOffset or 0, 0)
                if AA.Prediction > 0 then
                    targetPos = targetPos + targetInfo.velocity * math.clamp(AA.Prediction, 0, 1.5)
                end
                local des = CFrame.lookAt(pos, targetPos)
                local alpha = math.clamp(AA.Strength + dt*0.5, 0, 1)
                if AA.AdaptiveSmoothing then
                    local normalized = 1 - math.clamp((targetInfo.distance or 0) / math.max(AA.MaxDistance, 1), 0, 1)
                    alpha = math.clamp(alpha + normalized * AA.CloseRangeBoost, 0, 1)
                end

                local deadzone = math.max(0, AA.Deadzone or 0)
                if deadzone > 0 then
                    local closeness = (targetInfo.pixelDist - deadzone) / math.max(deadzone, 1)
                    if closeness > 0 then
                        local scale = math.clamp(closeness, 0.05, 1)
                        cam.CFrame = cam.CFrame:Lerp(des, math.clamp(alpha * scale, 0, 1))
                    end
                else
                    cam.CFrame = cam.CFrame:Lerp(des, alpha)
                end
            end
        else
            lastTargetPart = nil
            reactionTimer = 0
        end
    else
        lastTargetPart = nil
        reactionTimer = 0
    end
end)

-- ESP (Highlight)
local highlightFolder = Instance.new("Folder")
highlightFolder.Name = "PC_HighlightPool"
highlightFolder.Parent = safeParent()

local highlightPool = {}
local activeHighlights = {}

local function acquireHighlight(player)
    local highlight = activeHighlights[player]
    if highlight and highlight.Parent then
        return highlight
    end
    highlight = table.remove(highlightPool) or Instance.new("Highlight")
    highlight.Name = "_HL_"
    highlight.Enabled = false
    highlight.Parent = highlightFolder
    activeHighlights[player] = highlight
    return highlight
end

local function releaseHighlight(player)
    local highlight = activeHighlights[player]
    if highlight then
        highlight.Enabled = false
        highlight.Adornee = nil
        highlight.Parent = highlightFolder
        highlightPool[#highlightPool + 1] = highlight
        activeHighlights[player] = nil
    end
end

local function releaseAllHighlights()
    local toRelease = {}
    for player in pairs(activeHighlights) do
        toRelease[#toRelease + 1] = player
    end
    for _, player in ipairs(toRelease) do
        releaseHighlight(player)
    end
end

local function isEnemyESP(p) if not LocalPlayer.Team or not p.Team then return nil end return LocalPlayer.Team~=p.Team end
local function distTo(c) local hrp=c and c:FindFirstChild("HumanoidRootPart"); local my=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if hrp and my then return (hrp.Position-my.Position).Magnitude end return math.huge end
local function tintESPColor(color)
    local h,s,v = Color3.toHSV(color)
    local intensity = math.clamp(ESP.ColorIntensity or 1, 0, 2)
    v = math.clamp(v * intensity, 0, 1)
    local satScale = math.clamp(0.55 + 0.45 * intensity, 0, 1.5)
    s = math.clamp(s * satScale, 0, 1)
    return Color3.fromHSV(h, s, v)
end
local function espTick(p)
    if p==LocalPlayer then return end
    local c=p.Character
    if not c then
        releaseHighlight(p)
        return
    end
    local h=acquireHighlight(p)
    h.Adornee = c
    h.Parent = highlightFolder
    local show=ESP.Enabled
    if show and ESP.EnemiesOnly then local e=isEnemyESP(p); show=(e==true) end
    if show and ESP.UseDistance then show=distTo(c)<=ESP.MaxDistance end
    h.Enabled=show; if not show then return end
    h.DepthMode = ESP.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    h.FillTransparency = math.clamp(ESP.FillTransparency, 0, 1)
    h.OutlineTransparency = math.clamp(ESP.OutlineTransparency, 0, 1)
    local e=isEnemyESP(p)
    if e==true then
        local col = tintESPColor(ESP.EnemyColor)
        h.FillColor=col; h.OutlineColor=col
    elseif e==false then
        local col = tintESPColor(ESP.FriendColor)
        h.FillColor=col; h.OutlineColor=col
    else
        local col = tintESPColor(ESP.NeutralColor)
        h.FillColor=col; h.OutlineColor=col
    end
end
local espAccumulator = 0
RunService.RenderStepped:Connect(function(dt)
    if SAFE_MODE then
        if next(activeHighlights) then
            releaseAllHighlights()
        end
        return
    end
    local interval = PerformanceSettings.LowImpact and 0.08 or 0
    if interval > 0 then
        espAccumulator += dt
        if espAccumulator < interval then
            return
        end
        espAccumulator = 0
    else
        espAccumulator = 0
    end
    for _,pl in ipairs(Players:GetPlayers()) do espTick(pl) end
end)
for _, pl in ipairs(Players:GetPlayers()) do
    pl.CharacterRemoving:Connect(function()
        if SAFE_MODE then return end
        releaseHighlight(pl)
    end)
end

Players.PlayerAdded:Connect(function(p)
    if SAFE_MODE then return end
    p.CharacterAdded:Connect(function()
        task.wait(0.2)
        if SAFE_MODE then return end
        espTick(p)
    end)
    p.CharacterRemoving:Connect(function()
        if SAFE_MODE then return end
        releaseHighlight(p)
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    if SAFE_MODE then return end
    releaseHighlight(p)
end)

--==================== PAGES & CONTROLS ====================--
local AimbotP = newPage("Aimbot")
local ESPP    = newPage("ESP")
local VisualP = newPage("Visuals")
local MiscP   = newPage("Misc")
local ConfP   = newPage("Config")

local ESPColorPresets = {
    {label = "Crimson Pulse", value = Color3.fromRGB(255, 70, 70)},
    {label = "Solar Gold", value = Color3.fromRGB(255, 255, 0)},
    {label = "Toxic Lime", value = Color3.fromRGB(0, 255, 140)},
    {label = "Electric Azure", value = Color3.fromRGB(90, 190, 255)},
    {label = "Aurora Cyan", value = Color3.fromRGB(70, 255, 255)},
    {label = "Royal Violet", value = Color3.fromRGB(180, 110, 255)},
    {label = "Sunburst", value = Color3.fromRGB(255, 170, 60)},
    {label = "Frostbite", value = Color3.fromRGB(210, 235, 255)},
}

-- create tabs (avoid firing signals programmatically)
tabButton("Aimbot", AimbotP)
tabButton("ESP", ESPP)
tabButton("Visuals", VisualP)
tabButton("Misc", MiscP)
tabButton("Config", ConfP)
task.defer(function()
    if TabButtons[1] then
        TabButtons[1]:Activate()
    else
        AimbotP.Visible = true
        CurrentPage = AimbotP
        updateResetButtonLabel()
    end
end)

-- Aimbot block
mkToggle(AimbotP,"Enable Aimbot", AA.Enabled, function(v) AA.Enabled=v end, "Turns the aimbot feature on or off.")
mkToggle(AimbotP,"Require Right Mouse (hold)", AA.RequireRMB, function(v) AA.RequireRMB=v end, "Only activates the aimbot while the right mouse button is held down.")
mkToggle(AimbotP,"Wall Check (line of sight)", AA.WallCheck, function(v) AA.WallCheck=v end, "Skips targets that are blocked by walls or other geometry.")
mkToggle(AimbotP,"Show FOV", AA.ShowFOV, function(v) AA.ShowFOV=v end, "Displays the aiming field-of-view circle on your screen.")
fovSliderControl = mkSlider(AimbotP,"FOV Radius", 40, 500, AA.FOVRadiusPx, function(x) AA.FOVRadiusPx=math.floor(x) end,"px", "Sets the radius of the aim assist field-of-view circle in pixels.")
mkSlider(AimbotP,"Deadzone Padding", 0, 20, AA.Deadzone, function(x) AA.Deadzone=x end,"px", "Defines an inner deadzone where the aimbot will not move the camera.")
mkSlider(AimbotP,"Strength (lower=stronger)", 0.05, 0.40, AA.Strength, function(x) AA.Strength=x end,nil, "Controls how strongly the camera lerps toward the target (lower means snappier).")
mkSlider(AimbotP,"Max Distance", 50, 1000, AA.MaxDistance, function(x) AA.MaxDistance=math.floor(x) end,"studs", "Limits aiming to targets within this distance.")
mkSlider(AimbotP,"Min Distance Gate", 0, 250, AA.MinDistance, function(x) AA.MinDistance=math.floor(x) end,"studs", "Ignores targets that are closer than this distance.")
local targetPriority = mkCycle(AimbotP,"Target Priority", {
    {label="Hybrid (angle+distance)", value="Hybrid"},
    {label="Closest Angle", value="Angle"},
    {label="Closest Distance", value="Distance"},
    {label="Lowest Health", value="Health"},
}, AA.TargetSort, function(val) AA.TargetSort=val end, "Chooses how potential targets are ranked before aiming.")
local distanceWeight = mkSlider(AimbotP,"Hybrid Distance Weight", 0, 0.08, AA.DistanceWeight, function(x) AA.DistanceWeight=x end,nil, "Adjusts how much distance influences the hybrid priority mode.")
local dynamicPartToggle
dynamicPartToggle = mkToggle(AimbotP,"Auto Bone Selection", AA.DynamicPart, function(v) AA.DynamicPart=v end, "Automatically chooses which body part to aim at based on target movement.")
local partCycle = mkCycle(AimbotP,"Manual Target Bone", {"Head","UpperTorso","HumanoidRootPart"}, AA.PartName, function(val) AA.PartName=val end, "Selects the specific body part to aim at when auto selection is disabled.")
local stickyToggle = mkToggle(AimbotP,"Sticky Aim (keep last target)", AA.StickyAim, function(v)
    AA.StickyAim=v
    if not v then stickyTarget=nil; stickyTimer=0 end
end, "Keeps following the most recent target for a short period even if they leave the FOV.")
local stickyDuration = mkSlider(AimbotP,"Sticky Duration", 0.1, 1.5, AA.StickTime, function(x)
    AA.StickTime=x
    stickyTimer = math.min(stickyTimer, AA.StickTime)
end,"s", "How long sticky aim should hold onto the previous target.")
local reactionDelay = mkSlider(AimbotP,"Reaction Delay", 0, 0.35, AA.ReactionDelay, function(x) AA.ReactionDelay=x end,"s", "Adds a delay before the aimbot begins to adjust toward a target.")
local reactionJitter = mkSlider(AimbotP,"Reaction Jitter", 0, 0.3, AA.ReactionJitter, function(x) AA.ReactionJitter=x end,"s", "Adds random variation to the reaction delay for a more human feel.")
local adaptiveToggle = mkToggle(AimbotP,"Adaptive Smoothing Boost", AA.AdaptiveSmoothing, function(v) AA.AdaptiveSmoothing=v end, "Boosts smoothing strength as enemies move closer to you.")
local closeBoost = mkSlider(AimbotP,"Close-range Boost", 0, 0.6, AA.CloseRangeBoost, function(x) AA.CloseRangeBoost=x end,nil, "Amount of extra smoothing applied when targets are nearby.")
local predictionSlider = mkSlider(AimbotP,"Lead Prediction", 0, 0.75, AA.Prediction, function(x) AA.Prediction=x end,"s", "Predicts where moving targets will be after this many seconds.")
local heightOffset = mkSlider(AimbotP,"Aim Height Offset", -2, 2, AA.VerticalOffset, function(x) AA.VerticalOffset=x end,"studs", "Shifts the aim point up or down relative to the target.")

setInteractable(stickyDuration.Row, AA.StickyAim)
setInteractable(closeBoost.Row, AA.AdaptiveSmoothing)
if partCycle and partCycle.Row then setInteractable(partCycle.Row, not AA.DynamicPart) end
if reactionJitter and reactionJitter.Row then setInteractable(reactionJitter.Row, (AA.ReactionDelay or 0) > 0) end
if distanceWeight and distanceWeight.Row then setInteractable(distanceWeight.Row, (AA.TargetSort or "Hybrid") == "Hybrid") end
RunService.RenderStepped:Connect(function()
    setInteractable(stickyDuration.Row, AA.StickyAim)
    setInteractable(closeBoost.Row, AA.AdaptiveSmoothing)
    if partCycle and partCycle.Row then setInteractable(partCycle.Row, not AA.DynamicPart) end
    if reactionJitter and reactionJitter.Row then setInteractable(reactionJitter.Row, (AA.ReactionDelay or 0) > 0) end
    if distanceWeight and distanceWeight.Row then setInteractable(distanceWeight.Row, (AA.TargetSort or "Hybrid") == "Hybrid") end
end)

-- ESP
mkToggle(ESPP,"Enable ESP", ESP.Enabled, function(v) ESP.Enabled=v end, "Turns highlight ESP visuals on or off.")
mkToggle(ESPP,"Enemies Only", ESP.EnemiesOnly, function(v) ESP.EnemiesOnly=v end, "Only shows ESP highlights on enemy players.")
mkToggle(ESPP,"Use Distance Limit", ESP.UseDistance, function(v) ESP.UseDistance=v end, "Restricts ESP to players within the max distance slider.")
mkSlider(ESPP,"Max Distance", 50, 2000, ESP.MaxDistance, function(x) ESP.MaxDistance=math.floor(x) end,"studs", "Sets the farthest distance that ESP highlights will appear.")
mkToggle(ESPP,"Render Through Walls", ESP.ThroughWalls, function(v) ESP.ThroughWalls=v end, "Forces highlight outlines to show even through walls.")
mkSlider(ESPP,"Fill Transparency", 0, 1, ESP.FillTransparency, function(x) ESP.FillTransparency=x end,nil, "Adjusts how solid the ESP highlight fill appears.")
mkSlider(ESPP,"Outline Transparency", 0, 1, ESP.OutlineTransparency, function(x) ESP.OutlineTransparency=x end,nil, "Adjusts how visible the ESP outline is.")
mkSlider(ESPP,"Color Intensity", 0.4, 1.6, ESP.ColorIntensity, function(x) ESP.ColorIntensity=x end,nil, "Boosts or softens highlight brightness for every player type.")
mkCycle(ESPP, "Enemy Highlight", ESPColorPresets, ESP.EnemyColor, function(col) ESP.EnemyColor = col end, "Choose the glow color used when enemies are highlighted.")
mkCycle(ESPP, "Friendly Highlight", ESPColorPresets, ESP.FriendColor, function(col) ESP.FriendColor = col end, "Select the highlight tint for teammates and allies.")
mkCycle(ESPP, "Neutral Highlight", ESPColorPresets, ESP.NeutralColor, function(col) ESP.NeutralColor = col end, "Pick the tone shown for players with no team alignment.")

-- Visuals
local themeCycle = mkCycle(VisualP, "Theme Preset", {"Light", "Dark", "Galaxy", "Noir"}, CurrentThemeName, function(val)
    setThemePreset(val)
end, "Switch between curated Aurora themes.")
mkThemeColor(VisualP, "Accent Neon", "Neon", "Adjust the vibrant accent glow color.")
mkThemeColor(VisualP, "Canvas Ink", "Ink", "Change the panel and card surfaces.")
mkThemeColor(VisualP, "Primary Text", "Text", "Tweak the main interface text color.")
local crossT = mkToggle(VisualP,"Crosshair", Cross.Enabled, function(v) Cross.Enabled=v; crossChanged(); updCross() end, "Shows or hides the custom crosshair overlay.")
local crossOpacity = mkSlider(VisualP,"Opacity", 0.1,1, Cross.Opacity, function(x) Cross.Opacity=x; crossChanged(); updCross() end,nil, "Sets how transparent the crosshair appears.")
local crossSize = mkSlider(VisualP,"Size", 4,24, Cross.Size, function(x) Cross.Size=math.floor(x); crossChanged(); updCross() end,nil, "Controls the overall length of the crosshair lines.")
local crossGap = mkSlider(VisualP,"Gap", 2,20, Cross.Gap, function(x) Cross.Gap=math.floor(x); crossChanged(); updCross() end,nil, "Adjusts the gap between the crosshair arms and the center.")
local crossThickness = mkSlider(VisualP,"Thickness", 1,6, Cross.Thickness, function(x) Cross.Thickness=math.floor(x); crossChanged(); updCross() end,nil, "Changes how thick each crosshair arm is.")
local dotT = mkToggle(VisualP,"Center Dot", Cross.CenterDot, function(v) Cross.CenterDot=v; crossChanged(); updCross() end, "Adds a dot to the middle of the crosshair.")
local dotS = mkSlider(VisualP,"Dot Size", 1,6, Cross.DotSize, function(x) Cross.DotSize=math.floor(x); crossChanged(); updCross() end,nil, "Sets the size of the center dot.")
local dotO = mkSlider(VisualP,"Dot Opacity", 0.1,1, Cross.DotOpacity, function(x) Cross.DotOpacity=x; crossChanged(); updCross() end,nil, "Controls the transparency of the center dot.")
local teamColorToggle
local rainbowToggle
teamColorToggle = mkToggle(VisualP,"Use Team Color", Cross.UseTeamColor, function(v)
    Cross.UseTeamColor=v
    crossChanged()
    if v and rainbowToggle then
        Cross.Rainbow=false
        rainbowToggle.Set(false)
    end
    updCross()
end, "Applies your current team color to the crosshair.")
rainbowToggle = mkToggle(VisualP,"Rainbow Cycle", Cross.Rainbow, function(v)
    Cross.Rainbow=v
    crossChanged()
    if v and teamColorToggle then
        Cross.UseTeamColor=false
        teamColorToggle.Set(false)
    end
    updCross()
end, "Cycles crosshair colors through a rainbow gradient.")
local rainbowSpeed = mkSlider(VisualP,"Rainbow Speed", 0.2, 3, Cross.RainbowSpeed, function(x) Cross.RainbowSpeed=x; crossChanged(); updCross() end,nil, "Controls how quickly the rainbow effect animates.")
local pulseToggle = mkToggle(VisualP,"Pulse Opacity", Cross.Pulse, function(v) Cross.Pulse=v; crossChanged(); updCross() end, "Makes the crosshair fade in and out repeatedly.")
local pulseSpeed = mkSlider(VisualP,"Pulse Speed", 0.5, 5, Cross.PulseSpeed, function(x) Cross.PulseSpeed=x; crossChanged(); updCross() end,nil, "Sets the speed of the crosshair opacity pulse.")
RunService.RenderStepped:Connect(function()
    local on=Cross.CenterDot; setInteractable(dotS.Row,on); setInteractable(dotO.Row,on)
    if rainbowSpeed then setInteractable(rainbowSpeed.Row, Cross.Rainbow) end
    if pulseSpeed then setInteractable(pulseSpeed.Row, Cross.Pulse) end
end)

local CrossControlMap = {
    Enabled = crossT,
    Opacity = crossOpacity,
    Size = crossSize,
    Gap = crossGap,
    Thickness = crossThickness,
    CenterDot = dotT,
    DotSize = dotS,
    DotOpacity = dotO,
    UseTeamColor = teamColorToggle,
    Rainbow = rainbowToggle,
    RainbowSpeed = rainbowSpeed,
    Pulse = pulseToggle,
    PulseSpeed = pulseSpeed,
}

crossPresetCycle = mkCycle(VisualP, "Crosshair Preset", buildCrossPresetOptions(), CrosshairPresets[1], function(record)
    if record == nil then
        currentCrossPreset = "Custom"
        return
    end
    applyCrossPreset(record)
end, "Swap between curated crosshair layouts.")

local savePresetButton = mkButton(VisualP, "Save Crosshair as Preset", function()
    local data = captureCrossState()
    local newName = "Custom " .. (#UserCrosshairPresets + 1)
    local record = {label = newName, data = data}
    table.insert(UserCrosshairPresets, record)
    crossPresetCycle.SetOptions(buildCrossPresetOptions(), record)
    playUISound("toggleOn")
end, {buttonText = "Save"}, "Store your current crosshair tuning for later use.")

-- Misc
mkToggle(MiscP,"Press K to toggle UI", true, function() end, "Reminder that you can press K to hide or show the panel.")
local dragToggle = mkToggle(MiscP,"Allow Dragging", true, function(v)
    draggingEnabled = v
    if not v then dragging=false end
end, "Enables dragging the window around the screen.")
local centerBtn = mkButton(MiscP, "Center Panel", function()
    Root.Position = UDim2.fromScale(0.5,0.5)
    dragging = false
end, {buttonText="Center"}, "Recenters the panel on your screen.")
local scaleSlider = mkSlider(MiscP,"UI Scale", 0.85, 1.25, PanelScale.Scale, function(x) PanelScale.Scale=x end,"x", "Changes the overall size of the menu UI.")
local fontScaleSlider = mkSlider(MiscP,"Font Scale", 0.8, 1.4, FontScale, function(x) setFontScale(x) end,"x", "Adjusts text size without affecting layout scale.")
local soundToggle = mkToggle(MiscP, "Sound Cues", SoundSettings.Enabled, function(v)
    SoundSettings.Enabled = v
end, "Play gentle interface sounds when toggles, sliders, and confirmations fire.")
lowImpactToggle = mkToggle(MiscP, "Low Impact Mode", PerformanceSettings.LowImpact, function(v)
    PerformanceSettings.LowImpact = v
    if v then
        setBannerState("lowImpact", "Low impact mode ON", "Low impact mode ON", "Warn", 2)
    else
        setBannerState("lowImpact")
    end
end, "Reduce update rates for ESP, crosshair, and graphs to recover FPS on weaker devices.")
languageCycle = mkCycle(MiscP, "Language", buildLanguageOptions(), CurrentLanguage, function(lang) setLanguage(lang) end, "Choose the interface language.")
for _, id in ipairs({"ToggleUI", "Panic"}) do
    createKeybindRow(MiscP, id, Keybinds[id])
end

local creditCard = Instance.new("Frame", MiscP)
creditCard.Name = "CreditsCard"
creditCard.BackgroundColor3 = T.Card
creditCard.Size = UDim2.new(0.5, -6, 0, 64)
corner(creditCard, 10)
stroke(creditCard, T.Stroke, 1, 0.25)

local creditPadding = Instance.new("UIPadding", creditCard)
creditPadding.PaddingLeft = UDim.new(0, 18)
creditPadding.PaddingRight = UDim.new(0, 18)
creditPadding.PaddingTop = UDim.new(0, 12)
creditPadding.PaddingBottom = UDim.new(0, 12)

local creditTitle = Instance.new("TextLabel", creditCard)
creditTitle.BackgroundTransparency = 1
creditTitle.Position = UDim2.new(0, 0, 0, 0)
creditTitle.Size = UDim2.new(1, -140, 0, 22)
creditTitle.Font = Enum.Font.GothamBold
creditTitle.Text = "Cred til ProfitCruiser"
creditTitle.TextColor3 = T.Text
creditTitle.TextSize = 15
creditTitle.TextXAlignment = Enum.TextXAlignment.Left
creditTitle.TextYAlignment = Enum.TextYAlignment.Top

local creditSub = Instance.new("TextLabel", creditCard)
creditSub.BackgroundTransparency = 1
creditSub.Position = UDim2.new(0, 0, 0, 24)
creditSub.Size = UDim2.new(1, -140, 1, -28)
creditSub.Font = Enum.Font.Gotham
creditSub.Text = "Aurora-panelet er laget av ProfitCruiser crewet."
creditSub.TextColor3 = T.Subtle
creditSub.TextSize = 12
creditSub.TextWrapped = true
creditSub.TextXAlignment = Enum.TextXAlignment.Left
creditSub.TextYAlignment = Enum.TextYAlignment.Top

local discordBtn = Instance.new("TextButton", creditCard)
discordBtn.Name = "DiscordCopy"
discordBtn.AutoButtonColor = false
discordBtn.Size = UDim2.new(0, 120, 0, 34)
discordBtn.Position = UDim2.new(1, -132, 0.5, -17)
discordBtn.Font = Enum.Font.GothamBold
discordBtn.Text = "Discord"
discordBtn.TextColor3 = T.Text
discordBtn.TextSize = 14
discordBtn.BackgroundColor3 = T.Accent
corner(discordBtn, 12)
stroke(discordBtn, T.Stroke, 1, 0.3)

local discordHover = T.Neon
local discordBase = discordBtn.BackgroundColor3
discordBtn.MouseEnter:Connect(function()
    TweenService:Create(discordBtn, TweenInfo.new(0.12), {BackgroundColor3 = discordHover}):Play()
end)
discordBtn.MouseLeave:Connect(function()
    TweenService:Create(discordBtn, TweenInfo.new(0.12), {BackgroundColor3 = discordBase}):Play()
end)

local defaultSubText = creditSub.Text
local copySignal = 0
discordBtn.MouseButton1Click:Connect(function()
    copySignal += 1
    local ticket = copySignal
    local success = false
    if setclipboard then
        success = pcall(function()
            setclipboard(DISCORD_URL)
        end)
        success = success == true
    end
    if success then
        creditSub.Text = "Discord-lenken er kopiert!"
        creditSub.TextColor3 = T.Good
    else
        creditSub.Text = "Kunne ikke kopiere automatisk — bruk lenken: " .. DISCORD_URL
        creditSub.TextColor3 = T.Warn
    end
    TweenService:Create(creditSub, TweenInfo.new(0.12), {TextTransparency = 0}):Play()
    task.delay(1.6, function()
        if copySignal == ticket then
            creditSub.Text = defaultSubText
            creditSub.TextColor3 = T.Subtle
        end
    end)
end)

if not _G.__PC_OnboardSeen then
    local overlay = Instance.new("Frame", Gate)
    overlay.Name = "Onboarding"
    overlay.ZIndex = 150
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.45
    overlay.Size = UDim2.fromScale(1, 1)

    local coach = Instance.new("Frame", overlay)
    coach.Size = UDim2.fromOffset(320, 260)
    coach.AnchorPoint = Vector2.new(1, 0)
    coach.Position = UDim2.new(1, -40, 0, 40)
    coach.BackgroundColor3 = T.Card
    coach.BackgroundTransparency = 0
    corner(coach, 14)
    local coachStroke = stroke(coach, T.Stroke, 1, 0.35)
    bindTheme(coach, "BackgroundColor3", "Card")
    bindTheme(coachStroke, "Color", "Stroke")

    local coachPad = Instance.new("UIPadding", coach)
    coachPad.PaddingTop = UDim.new(0, 18)
    coachPad.PaddingBottom = UDim.new(0, 18)
    coachPad.PaddingLeft = UDim.new(0, 20)
    coachPad.PaddingRight = UDim.new(0, 20)

    local coachLayout = Instance.new("UIListLayout", coach)
    coachLayout.SortOrder = Enum.SortOrder.LayoutOrder
    coachLayout.Padding = UDim.new(0, 10)

    local coachTitle = Instance.new("TextLabel", coach)
    coachTitle.BackgroundTransparency = 1
    coachTitle.Font = Enum.Font.GothamBold
    coachTitle.TextSize = 18
    coachTitle.TextColor3 = T.Text
    coachTitle.TextXAlignment = Enum.TextXAlignment.Left
    coachTitle.Text = "Welcome to Aurora"
    registerText(coachTitle, "Onboard Title", "Welcome to Aurora", 18)
    bindTheme(coachTitle, "TextColor3", "Text")

    local coachBody = Instance.new("TextLabel", coach)
    coachBody.BackgroundTransparency = 1
    coachBody.Font = Enum.Font.Gotham
    coachBody.TextSize = 13
    coachBody.TextColor3 = T.Subtle
    coachBody.TextWrapped = true
    coachBody.TextXAlignment = Enum.TextXAlignment.Left
    coachBody.Size = UDim2.new(1, 0, 0, 120)
    coachBody.Text = "Paste your key, hit Unlock, and meet us on Discord. We'll only show this once!"
    registerText(coachBody, "Onboard Body", "Paste your key, hit Unlock, and meet us on Discord. We'll only show this once!", 13)
    bindTheme(coachBody, "TextColor3", "Subtle")

    local checklist = {
        {"Tap Get Key", "Use the copy to grab a fresh key."},
        {"Paste & Unlock", "Drop the key in the box and press Unlock Panel."},
        {"Join Discord", "Hop in for updates and rotation pings."},
    }

    for _, item in ipairs(checklist) do
        local rowFrame = Instance.new("Frame", coach)
        rowFrame.BackgroundTransparency = 1
        rowFrame.Size = UDim2.new(1, 0, 0, 40)

        local rowLayout = Instance.new("UIListLayout", rowFrame)
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        rowLayout.Padding = UDim.new(0, 8)

        local bullet = Instance.new("TextLabel", rowFrame)
        bullet.BackgroundTransparency = 1
        bullet.Font = Enum.Font.GothamBold
        bullet.TextSize = 14
        bullet.TextColor3 = T.Neon
        bullet.Text = "•"
        bullet.Size = UDim2.new(0, 12, 1, 0)
        bindTheme(bullet, "TextColor3", "Neon")

        local step = Instance.new("TextLabel", rowFrame)
        step.BackgroundTransparency = 1
        step.Font = Enum.Font.Gotham
        step.TextSize = 13
        step.TextColor3 = T.Text
        step.TextWrapped = true
        step.TextXAlignment = Enum.TextXAlignment.Left
        step.Text = item[1] .. " — " .. item[2]
        bindTheme(step, "TextColor3", "Text")
        FontRegistry[step] = 13
    end

    local closeBtn = Instance.new("TextButton", coach)
    closeBtn.Size = UDim2.new(0, 140, 0, 34)
    closeBtn.AnchorPoint = Vector2.new(0, 0)
    closeBtn.BackgroundColor3 = T.Accent
    closeBtn.TextColor3 = T.Text
    closeBtn.Font = Enum.Font.GothamMedium
    closeBtn.TextSize = 14
    closeBtn.Text = "Let's go"
    closeBtn.AutoButtonColor = false
    corner(closeBtn, 10)
    local closeStroke = stroke(closeBtn, T.Stroke, 1, 0.35)
    bindTheme(closeBtn, "BackgroundColor3", "Accent")
    bindTheme(closeBtn, "TextColor3", "Text")
    bindTheme(closeStroke, "Color", "Stroke")
    registerText(closeBtn, "Onboard Start", "Let's go", 14)

    closeBtn.MouseButton1Click:Connect(function()
        playUISound("cycle")
        overlay:Destroy()
        _G.__PC_OnboardSeen = true
    end)
end

-- Kill Menu logic
local function killMenu()
    -- hide all UIs
    if Root then Root.Visible = false end
    if Gate then Gate.Enabled = false end
    if SuccessGui then SuccessGui.Enabled = false end
    if AA_GUI then AA_GUI.Enabled = false end
    if CrossGui then CrossGui.Enabled = false end
    clearBannerStates()
    PerformanceSettings.LowImpact = false
    if lowImpactToggle and lowImpactToggle.Set then
        suppressSoundStack += 1
        lowImpactToggle.Set(false)
        suppressSoundStack = math.max(0, suppressSoundStack - 1)
    end
    -- remove blur
    TweenService:Create(Blur, TweenInfo.new(0.15), {Size = 0}):Play()
    Blur.Enabled = false
    -- disable features so runtime loops render nothing
    AA.Enabled=false; ESP.Enabled=false; Cross.Enabled=false; updCross()
    stickyTarget=nil; stickyTimer=0
    releaseAllHighlights()
end

-- panic key (P) also kills the menu
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if Keybinds.ToggleUI and input.KeyCode == Keybinds.ToggleUI.key then
            Root.Visible = not Root.Visible
            playUISound("toggleOn")
        elseif Keybinds.Panic and input.KeyCode == Keybinds.Panic.key then
            playUISound("toggleOff")
            killMenu()
        end
    elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
        controllerMode = true
        GuiService.AutoSelectGuiEnabled = true
        if input.KeyCode == Enum.KeyCode.DPadLeft or input.KeyCode == Enum.KeyCode.ButtonL1 then
            changeTab(-1)
        elseif input.KeyCode == Enum.KeyCode.DPadRight or input.KeyCode == Enum.KeyCode.ButtonR1 then
            changeTab(1)
        elseif input.KeyCode == Enum.KeyCode.ButtonStart then
            Root.Visible = not Root.Visible
        end
    end
end)

UserInputService.GamepadConnected:Connect(function()
    controllerMode = true
    GuiService.AutoSelectGuiEnabled = true
    if TabButtons[currentTabIndex] then
        GuiService.SelectedObject = TabButtons[currentTabIndex]
    end
end)

UserInputService.GamepadDisconnected:Connect(function()
    controllerMode = UserInputService.GamepadEnabled
    if not controllerMode then
        GuiService.AutoSelectGuiEnabled = false
        GuiService.SelectedObject = nil
    end
end)

local recentTouches = {}
UserInputService.TouchStarted:Connect(function(input, processed)
    if processed then return end
    recentTouches[input] = tick()
    local now = tick()
    local count = 0
    for touch, start in pairs(recentTouches) do
        if now - start <= 0.25 then
            count += 1
        else
            recentTouches[touch] = nil
        end
    end
    if count >= 3 then
        Root.Visible = not Root.Visible
        playUISound("toggleOn")
    end
end)

UserInputService.TouchEnded:Connect(function(input)
    recentTouches[input] = nil
end)

-- Button to kill menu
mkButton(MiscP, "Kill Menu (remove UI)", function() killMenu() end, {danger=true, buttonText="Kill Menu"}, "Completely closes the UI and disables every feature until re-executed.")

-- Config / profiles
local BASE="ProfitCruiser"; local PROF=BASE.."/Profiles"; local MODE="memory"; local MEM=rawget(_G,"PC_ProfileStore") or {}; _G.PC_ProfileStore=MEM
local function ensure() if makefolder then local ok1=true if not (isfolder and isfolder(BASE)) then ok1=pcall(function() makefolder(BASE) end) end local ok2=true if not (isfolder and isfolder(PROF)) then ok2=pcall(function() makefolder(PROF) end) end return ok1 and ok2 end return false end
if ensure() and writefile and readfile then MODE="filesystem" end
local function deep(dst,src) for k,v in pairs(src) do if typeof(v)=="table" and typeof(dst[k])=="table" then deep(dst[k],v) else dst[k]=v end end end
local function gather() return {AA=AA, ESP=ESP, Cross=Cross} end
local function apply(s)
    if not s then return end
    deep(AA,s.AA or {})
    deep(ESP,s.ESP or {})
    deep(Cross,s.Cross or {})
    updCross()
end
local function save(name) local ok,data=pcall(function() return HttpService:JSONEncode(gather()) end); if not ok then return false,"encode" end if MODE=="filesystem" then local p=PROF.."/"..name..".json"; local s,err=pcall(function() writefile(p,data) end); return s,(s and nil or tostring(err)) else MEM[name]=data; return true end end
local function load(name) if MODE=="filesystem" then local p=PROF.."/"..name..".json"; if not (isfile and isfile(p)) then return false,"missing" end local ok,raw=pcall(function() return readfile(p) end); if not ok then return false,"read" end local ok2,tbl=pcall(function() return HttpService:JSONDecode(raw) end); if not ok2 then return false,"decode" end apply(tbl); return true else local raw=MEM[name]; if not raw then return false,"missing" end local ok2,tbl=pcall(function() return HttpService:JSONDecode(raw) end); if not ok2 then return false,"decode" end apply(tbl); return true end end

local saveBtn = mkToggle(ConfP,"Save Default (click)", false, function(v,row) if v then local ok,err=save("Default"); (row:FindFirstChildWhichIsA("TextLabel")).Text = ok and "Saved Default ✅" or ("Save failed: "..tostring(err)); task.delay(0.4,function() (row:FindFirstChildWhichIsA("TextLabel")).Text="Save Default (click)" end) end end, "Saves your current settings into the Default profile slot.")
local loadBtn = mkToggle(ConfP,"Load Default (click)", false, function(v,row) if v then local ok,err=load("Default"); (row:FindFirstChildWhichIsA("TextLabel")).Text = ok and "Loaded Default ✅" or ("Load failed: "..tostring(err)); task.delay(0.4,function() (row:FindFirstChildWhichIsA("TextLabel")).Text="Load Default (click)" end) end end, "Loads the Default profile back into all features.")

local resetAllButton = mkButton(ConfP, "Reset All Tabs", function()
    resetAllPages()
    playUISound("cycle")
end, {buttonText = "Reset All"}, "Restores every tab to its default configuration in one click.")

-- Show panel when gate closes (only if allowed by flow)
Gate:GetPropertyChangedSignal("Enabled"):Connect(function()
    local on = Gate.Enabled
    TweenService:Create(Blur, TweenInfo.new(0.2), {Size = on and 8 or 0}):Play()
    Blur.Enabled = on or (not on and not allowReveal)
    -- Only reveal Root if gate closed AND the reveal flag was set (set after overlay finishes)
    if (not on) and allowReveal and Root then
        Root.Visible = true
    end
end)
