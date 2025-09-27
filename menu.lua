--====================================================--
-- AURORA PANEL — ProfitCruiser (fixed key→panel flow)
-- Full redesign: Compact 2-col layout + sections + gating
-- Aimbot, Recoil v2, ESP(Highlight), Crosshair, Profiles
--====================================================--

--// Services
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")
local Players           = game:GetService("Players")
local GuiService        = game:GetService("GuiService")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

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

--// Theme
local T = {
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
}

local function safeParent()
    local ok, ui = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
    return (ok and ui) or LocalPlayer:WaitForChild("PlayerGui")
end

--// Utils
local function corner(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=o end
local function stroke(o,col,th,tr) local s=Instance.new("UIStroke"); s.Color=col; s.Thickness=th or 1; s.Transparency=tr or 0; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=o end
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
Card.Size=UDim2.fromOffset(540, 320); Card.AnchorPoint=Vector2.new(0.5,0.5); Card.Position=UDim2.fromScale(0.5,0.5)
Card.BackgroundColor3=T.Card; stroke(Card,T.Stroke,1,0.45); corner(Card,18); pad(Card,18)

local Title = Instance.new("TextLabel", Card)
Title.BackgroundTransparency=1; Title.Text="ProfitCruiser — Access"; Title.Font=Enum.Font.GothamBold; Title.TextSize=20; Title.TextColor3=T.Text
Title.Size=UDim2.new(1,0,0,24); Title.TextXAlignment=Enum.TextXAlignment.Left

local Hint = Instance.new("TextLabel", Card)
Hint.BackgroundTransparency=1; Hint.Text="Paste your key. Use Get Key or join Discord."; Hint.Font=Enum.Font.Gotham; Hint.TextSize=14; Hint.TextColor3=T.Subtle
Hint.Size=UDim2.new(1,0,0,20); Hint.Position=UDim2.new(0,0,0,30); Hint.TextXAlignment=Enum.TextXAlignment.Left

local KeyBox = Instance.new("TextBox", Card)
KeyBox.Size=UDim2.new(1,0,0,40); KeyBox.Position=UDim2.new(0,0,0,64); KeyBox.Text=""; KeyBox.PlaceholderText="Enter key…"
KeyBox.ClearTextOnFocus=false; KeyBox.Font=Enum.Font.Gotham; KeyBox.TextSize=15; KeyBox.TextColor3=T.Text
KeyBox.BackgroundColor3=T.Ink; stroke(KeyBox,T.Stroke,1,0.35); corner(KeyBox,12)

local Row = Instance.new("Frame", Card)
Row.BackgroundTransparency=1; Row.Size=UDim2.new(1,0,0,42); Row.Position=UDim2.new(0,0,0,118)
local grid = Instance.new("UIGridLayout", Row)
grid.CellSize=UDim2.fromOffset(150,38); grid.CellPadding=UDim2.new(0,12,0,0); grid.HorizontalAlignment=Enum.HorizontalAlignment.Left; grid.FillDirectionMaxCells=3

local function btn(text)
    local b=Instance.new("TextButton", Row); b.Text=text; b.Font=Enum.Font.GothamMedium; b.TextSize=14; b.TextColor3=T.Text
    b.BackgroundColor3=T.Ink; b.AutoButtonColor=false; b.Size=UDim2.fromOffset(150,38)
    stroke(b,T.Stroke,1,0.35); corner(b,12)
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=T.Accent}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=T.Ink}):Play() end)
    return b
end

local GetKey = btn("Get Key")
local Discord = btn("Discord")
local Confirm = btn("Confirm")

local Status = Instance.new("TextLabel", Card)
Status.BackgroundTransparency=1; Status.Text=""; Status.Font=Enum.Font.Gotham; Status.TextSize=13; Status.TextColor3=T.Subtle
Status.Size=UDim2.new(1,0,0,20); Status.Position=UDim2.new(0,0,0,168); Status.TextXAlignment=Enum.TextXAlignment.Left

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
    if typeof(setclipboard)=="function" then setclipboard(GET_KEY_URL); Status.Text="Key link copied." else Status.Text="Key link: "..GET_KEY_URL end
end)
Discord.MouseButton1Click:Connect(function()
    if typeof(setclipboard)=="function" then setclipboard(DISCORD_URL) end
    Status.Text="Discord link copied."
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
    Status.Text = "Checking key…"
    local expected,err = fetchRemoteKey()
    if not expected then Status.Text = "Fetch failed: "..tostring(err or "") return end

    if trim(KeyBox.Text) == expected then
        Status.Text = "Accepted!"

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
        Status.Text = "Wrong key."
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

Root = Instance.new("Frame", App)
Root.Size=UDim2.fromOffset(980, 600); Root.AnchorPoint=Vector2.new(0.5,0.5); Root.Position=UDim2.fromScale(0.5,0.5)
Root.BackgroundColor3=T.Card; corner(Root,16); stroke(Root,T.Stroke,1,0.45); pad(Root,12)
Root.Visible=false

local PanelScale = Instance.new("UIScale", Root)
PanelScale.Scale = 1

local Top = Instance.new("Frame", Root)
Top.Size=UDim2.new(1, -16, 0, 46); Top.Position=UDim2.new(0,8,0,8); Top.BackgroundColor3=T.Panel; corner(Top,12); stroke(Top,T.Stroke,1,0.45); pad(Top,10)

local TitleLbl = Instance.new("TextLabel", Top)
TitleLbl.Size=UDim2.new(0.6,0,1,0); TitleLbl.BackgroundTransparency=1; TitleLbl.TextXAlignment=Enum.TextXAlignment.Left
TitleLbl.Text="ProfitCruiser — Aurora Panel"; TitleLbl.Font=Enum.Font.GothamBold; TitleLbl.TextSize=18; TitleLbl.TextColor3=T.Text

-- drag
local draggingEnabled = true
local dragging,rel=false,Vector2.zero
Top.InputBegan:Connect(function(i) if draggingEnabled and i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; rel=Root.AbsolutePosition-UserInputService:GetMouseLocation() end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
RunService.RenderStepped:Connect(function()
    if dragging then
        local vp=Camera.ViewportSize; local m=UserInputService:GetMouseLocation()
        local nx=math.clamp(m.X+rel.X,8,vp.X-Root.AbsoluteSize.X-8); local ny=math.clamp(m.Y+rel.Y,8,vp.Y-Root.AbsoluteSize.Y-8)
        Root.Position=UDim2.fromOffset(nx,ny)
    end
end)

-- sidebar
local Side = Instance.new("Frame", Root)
Side.Size=UDim2.new(0, 210, 1, -70); Side.Position=UDim2.new(0,8,0,62)
Side.BackgroundColor3=T.Panel; corner(Side,12); stroke(Side,T.Stroke,1,0.45); pad(Side,8)
-- ensure tab buttons stack vertically (fix: only Aimbot showing)
local SideList = Instance.new("UIListLayout", Side)
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Padding   = UDim.new(0,8)

local Content = Instance.new("Frame", Root)
Content.Size=UDim2.new(1, -234, 1, -70); Content.Position=UDim2.new(0, 226, 0, 62); Content.BackgroundTransparency=1

-- two-column grid inside pages
local function newPage(name)
    local p = Instance.new("ScrollingFrame", Content)
    p.Name = name
    p.Size = UDim2.fromScale(1, 1)
    p.Visible = false
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
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
    grid.CellSize = UDim2.new(0.5, -6, 0, 56)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Left

    local function syncCanvas()
        local contentY = grid.AbsoluteContentSize.Y
        p.CanvasSize = UDim2.new(0, 0, 0, math.max(contentY + padding.PaddingTop.Offset + padding.PaddingBottom.Offset, 0))
    end

    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncCanvas)
    p:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncCanvas)
    task.defer(syncCanvas)

    return p
end

local function tabButton(text, page)
    local b=Instance.new("TextButton", Side)
    b.Size=UDim2.new(1,0,0,40); b.Text=text; b.Font=Enum.Font.Gotham; b.TextSize=15; b.TextColor3=T.Text
    b.BackgroundColor3=T.Ink; b.AutoButtonColor=false; corner(b,10); stroke(b,T.Stroke,1,0.35)
    local bar=Instance.new("Frame", b); bar.Size=UDim2.new(0,0,1,0); bar.Position=UDim2.new(0,0,0,0); bar.BackgroundColor3=T.Neon; corner(bar,10)
    b.MouseButton1Click:Connect(function()
        for _,c in ipairs(Content:GetChildren()) do if c:IsA("Frame") then c.Visible=false end end
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
    end)
    return b
end

-- Controls factory (compact, reused)
local function rowBase(parent, name)
    local r=Instance.new("Frame", parent); r.BackgroundColor3=T.Card; r.Size=UDim2.new(0.5,-6,0,56)
    corner(r,10); stroke(r,T.Stroke,1,0.25)
    local l=Instance.new("TextLabel", r); l.BackgroundTransparency=1; l.Position=UDim2.new(0,12,0,0); l.Size=UDim2.new(1,-140,1,0)
    l.Text=name; l.TextColor3=T.Text; l.Font=Enum.Font.Gotham; l.TextSize=14; l.TextXAlignment=Enum.TextXAlignment.Left
    return r,l
end

local function mkToggle(parent, name, default, cb)
    local r,_=rowBase(parent,name)
    local sw=Instance.new("Frame", r); sw.Size=UDim2.new(0,68,0,28); sw.Position=UDim2.new(1,-84,0.5,-14); sw.BackgroundColor3=T.Ink; corner(sw,16); stroke(sw,T.Stroke,1,0.35)
    local k=Instance.new("Frame", sw); k.Size=UDim2.new(0,24,0,24); k.Position=UDim2.new(0,2,0.5,-12); k.BackgroundColor3=Color3.fromRGB(235,235,245); corner(k,12)
    local state = default
    local function set(v)
        state=v
        TweenService:Create(k,TweenInfo.new(0.12),{Position=v and UDim2.new(1,-26,0.5,-12) or UDim2.new(0,2,0.5,-12)}):Play()
        TweenService:Create(sw,TweenInfo.new(0.12),{BackgroundColor3=v and T.Neon or T.Ink}):Play()
        if cb then cb(v,r) end
    end
    sw.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then set(not state) end end)
    set(state)
    return {Row=r, Set=set, Get=function() return state end}
end

local function mkSlider(parent, name, min, max, default, cb, unit)
    local r,l=rowBase(parent,name)
    local v=Instance.new("TextLabel", r); v.BackgroundTransparency=1; v.Size=UDim2.new(0,110,1,0); v.Position=UDim2.new(1,-118,0,0)
    v.Text=""; v.TextColor3=T.Subtle; v.Font=Enum.Font.Gotham; v.TextSize=14; v.TextXAlignment=Enum.TextXAlignment.Right
    local bar=Instance.new("Frame", r); bar.Size=UDim2.new(1,-24,0,6); bar.Position=UDim2.new(0,12,0,38); bar.BackgroundColor3=T.Ink; corner(bar,4)
    local fill=Instance.new("Frame", bar); fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=T.Neon; corner(fill,4)

    local val=math.clamp(default or min, min, max)
    local function render()
        local a=(val-min)/(max-min)
        fill.Size=UDim2.new(a,0,1,0)
        local u = unit and (" "..unit) or ""
        v.Text = (math.floor(val*100+0.5)/100)..u
    end
    local dragging=false
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local m=UserInputService:GetMouseLocation().X; local x=bar.AbsolutePosition.X; local w=bar.AbsoluteSize.X
            local a=math.clamp((m-x)/w,0,1); val=min + a*(max-min); render(); if cb then cb(val,r) end
        end
    end)
    render()
    return {Row=r, Set=function(x) val=math.clamp(x,min,max); render(); if cb then cb(val,r) end end, Get=function() return val end}
end

-- simple button control (used for Kill Menu)
local function mkButton(parent, name, onClick, opts)
    local r,_ = rowBase(parent, name)
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

local function mkCycle(parent, name, options, default, cb)
    local r,_ = rowBase(parent, name)
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
    for i,opt in ipairs(options) do
        if typeof(opt) == "table" then
            normalized[i] = {
                label = opt.label or opt.text or tostring(opt.value),
                value = opt.value,
            }
        else
            normalized[i] = {label = tostring(opt), value = opt}
        end
    end

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

    return {
        Row = r,
        Set = function(value)
            local targetIndex
            if typeof(value) == "number" and normalized[value] then
                targetIndex = value
            else
                targetIndex = findIndexByValue(value)
            end
            if targetIndex then
                apply(targetIndex)
            end
        end,
        Get = function()
            if normalized[idx] then return normalized[idx].value end
        end,
    }
end

--==================== FEATURE STATE ====================--
local RC={ Enabled=false, OnlyWhileShooting=true, VerticalStrength=0.6, HorizontalStrength=0.0, Smooth=0.35 }
local AA={
    Enabled=false,
    Strength=0.15,
    PartName="Head",
    ShowFOV=false,
    FOVRadiusPx=180,
    MaxDistance=250,
    RequireRMB=false,
    WallCheck=true,
    DynamicPart=false,
    StickyAim=false,
    StickTime=0.35,
    AdaptiveSmoothing=false,
    CloseRangeBoost=0.2,
    Prediction=0,
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

--==================== RUNTIME / DRAW ====================--
-- FOV ring
local AA_GUI=Instance.new("ScreenGui"); AA_GUI.Name="PC_FOV"; AA_GUI.IgnoreGuiInset=true; AA_GUI.ResetOnSpawn=false; AA_GUI.DisplayOrder=45; AA_GUI.Parent=safeParent()
local FOV=Instance.new("Frame", AA_GUI); FOV.AnchorPoint=Vector2.new(0.5,0.5); FOV.Position=UDim2.fromScale(0.5,0.5); FOV.BackgroundTransparency=1; FOV.Visible=false
local FStroke=Instance.new("UIStroke", FOV); FStroke.Thickness=2; FStroke.Transparency=0.15; FStroke.Color=Color3.fromRGB(0,255,140); corner(FOV, math.huge)

-- Crosshair
local CrossGui=Instance.new("ScreenGui"); CrossGui.Name="PC_Crosshair"; CrossGui.IgnoreGuiInset=true; CrossGui.ResetOnSpawn=false; CrossGui.DisplayOrder=44; CrossGui.Parent=safeParent()
local function crossPart() local f=Instance.new("Frame"); f.BorderSizePixel=0; f.Parent=CrossGui; f.Visible=false; return f end
local chL,chR,chU,chD = crossPart(),crossPart(),crossPart(),crossPart()
local dot = crossPart()
local function updCross()
    if not Cross.Enabled then for _,f in ipairs({chL,chR,chU,chD,dot}) do f.Visible=false end return end
    local vp=Camera.ViewportSize; local cx,cy=vp.X*0.5,vp.Y*0.5; local g,s,t=Cross.Gap,Cross.Size,Cross.Thickness

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
RunService.RenderStepped:Connect(updCross)

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
    local origin=Camera.CFrame.Position; local dir=(part.Position-origin)
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances={LocalPlayer.Character, char}; rp.IgnoreWater=true
    return workspace:Raycast(origin, dir, rp)==nil
end
local function getTarget()
    local my=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not my then return nil end
    local cx,cy=Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2; local best,score
    for _,pl in ipairs(Players:GetPlayers()) do
        if isEnemy(pl) and pl.Character then
            local part=aimPart(pl.Character); local hrp=pl.Character:FindFirstChild("HumanoidRootPart")
            if part and hrp then
                local dist=(hrp.Position-my.Position).Magnitude
                if dist<=AA.MaxDistance then
                    local sp,on=Camera:WorldToViewportPoint(part.Position)
                    if on then
                        local dx,dy=sp.X-cx, sp.Y-cy; local pd=(dx*dx+dy*dy)^0.5
                        if pd<=AA.FOVRadiusPx and hasLOS(part, pl.Character) then
                            local s=pd + dist*0.02; if not score or s<score then best,score=part,s end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- Recoil comp
local function applyRC(dt)
    if not RC.Enabled then return end
    if RC.OnlyWhileShooting and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
    local v = RC.VerticalStrength * 12
    local h = RC.HorizontalStrength * 12
    local des = Camera.CFrame * CFrame.Angles(-math.rad(v*dt), -math.rad(h*dt), 0)
    Camera.CFrame = Camera.CFrame:Lerp(des, math.clamp(RC.Smooth,0.05,1))
end

local stickyTarget, stickyTimer = nil, 0
local function validateTarget(part)
    return part and part:IsDescendantOf(workspace)
end

-- Main render
RunService.RenderStepped:Connect(function(dt)
    FOV.Visible = (AA.Enabled and AA.ShowFOV)
    FOV.Size    = UDim2.fromOffset(AA.FOVRadiusPx*2, AA.FOVRadiusPx*2)

    if AA.Enabled and (not AA.RequireRMB or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then
        local candidate = getTarget()
        if AA.StickyAim then
            if candidate then
                stickyTarget = candidate
                stickyTimer = AA.StickTime
            else
                stickyTimer = math.max(0, stickyTimer - dt)
                if stickyTimer <= 0 or not validateTarget(stickyTarget) then
                    stickyTarget = nil
                end
            end
        else
            stickyTarget = nil
            stickyTimer = 0
        end

        local t = stickyTarget or candidate
        if t then
            local pos=Camera.CFrame.Position
            local targetPos=t.Position
            if AA.Prediction > 0 then
                local vel = t.AssemblyLinearVelocity or Vector3.zero
                targetPos = targetPos + vel * math.clamp(AA.Prediction, 0, 1.5)
            end
            local des=CFrame.lookAt(pos, targetPos)
            local alpha=math.clamp(AA.Strength + dt*0.5, 0, 1)
            if AA.AdaptiveSmoothing then
                local dist = (targetPos - pos).Magnitude
                local normalized = 1 - math.clamp(dist / math.max(AA.MaxDistance, 1), 0, 1)
                alpha = math.clamp(alpha + normalized * AA.CloseRangeBoost, 0, 1)
            end
            Camera.CFrame = Camera.CFrame:Lerp(des, alpha)
        end
    end
    applyRC(dt)
end)

-- ESP (Highlight)
local function hl(model)
    local h = model:FindFirstChild("_HL_")
    if not h then
        h = Instance.new("Highlight")
        h.Name = "_HL_"
        h.DepthMode = ESP.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        h.FillTransparency = ESP.FillTransparency
        h.OutlineTransparency = ESP.OutlineTransparency
        h.Parent = model
    end
    -- make sure it adorns the whole character even if parent/rig is unusual
    h.Adornee = model
    return h
end
local function isEnemyESP(p) if not LocalPlayer.Team or not p.Team then return nil end return LocalPlayer.Team~=p.Team end
local function distTo(c) local hrp=c and c:FindFirstChild("HumanoidRootPart"); local my=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if hrp and my then return (hrp.Position-my.Position).Magnitude end return math.huge end
local function espTick(p)
    if p==LocalPlayer then return end
    local c=p.Character; if not c then return end
    local h=hl(c); local show=ESP.Enabled
    if show and ESP.EnemiesOnly then local e=isEnemyESP(p); show=(e==true) end
    if show and ESP.UseDistance then show=distTo(c)<=ESP.MaxDistance end
    h.Enabled=show; if not show then return end
    h.DepthMode = ESP.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    h.FillTransparency = math.clamp(ESP.FillTransparency, 0, 1)
    h.OutlineTransparency = math.clamp(ESP.OutlineTransparency, 0, 1)
    local e=isEnemyESP(p)
    if e==true then h.FillColor=ESP.EnemyColor; h.OutlineColor=ESP.EnemyColor
    elseif e==false then h.FillColor=ESP.FriendColor; h.OutlineColor=ESP.FriendColor
    else h.FillColor=ESP.NeutralColor; h.OutlineColor=ESP.NeutralColor end
end
RunService.RenderStepped:Connect(function() for _,pl in ipairs(Players:GetPlayers()) do espTick(pl) end end)
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(0.2); espTick(p) end) end)

--==================== PAGES & CONTROLS ====================--
local AimbotP = newPage("Aimbot")
local ESPP    = newPage("ESP")
local VisualP = newPage("Visuals")
local MiscP   = newPage("Misc")
local ConfP   = newPage("Config")

-- create tabs (avoid firing signals programmatically)
tabButton("Aimbot", AimbotP)
tabButton("ESP", ESPP)
tabButton("Visuals", VisualP)
tabButton("Misc", MiscP)
tabButton("Config", ConfP)
-- make Aimbot page visible by default
AimbotP.Visible = true

-- Aimbot block
mkToggle(AimbotP,"Enable Aimbot", AA.Enabled, function(v) AA.Enabled=v end)
mkToggle(AimbotP,"Require Right Mouse (hold)", AA.RequireRMB, function(v) AA.RequireRMB=v end)
mkToggle(AimbotP,"Wall Check (line of sight)", AA.WallCheck, function(v) AA.WallCheck=v end)
mkToggle(AimbotP,"Show FOV", AA.ShowFOV, function(v) AA.ShowFOV=v end)
mkSlider(AimbotP,"FOV Radius", 40, 500, AA.FOVRadiusPx, function(x) AA.FOVRadiusPx=math.floor(x) end,"px")
mkSlider(AimbotP,"Strength (lower=stronger)", 0.05, 0.40, AA.Strength, function(x) AA.Strength=x end)
mkSlider(AimbotP,"Max Distance", 50, 1000, AA.MaxDistance, function(x) AA.MaxDistance=math.floor(x) end,"studs")
local dynamicPartToggle
dynamicPartToggle = mkToggle(AimbotP,"Auto Bone Selection", AA.DynamicPart, function(v) AA.DynamicPart=v end)
local partCycle = mkCycle(AimbotP,"Manual Target Bone", {"Head","UpperTorso","HumanoidRootPart"}, AA.PartName, function(val) AA.PartName=val end)
local stickyToggle = mkToggle(AimbotP,"Sticky Aim (keep last target)", AA.StickyAim, function(v)
    AA.StickyAim=v
    if not v then stickyTarget=nil; stickyTimer=0 end
end)
local stickyDuration = mkSlider(AimbotP,"Sticky Duration", 0.1, 1.5, AA.StickTime, function(x)
    AA.StickTime=x
    stickyTimer = math.min(stickyTimer, AA.StickTime)
end,"s")
local adaptiveToggle = mkToggle(AimbotP,"Adaptive Smoothing Boost", AA.AdaptiveSmoothing, function(v) AA.AdaptiveSmoothing=v end)
local closeBoost = mkSlider(AimbotP,"Close-range Boost", 0, 0.6, AA.CloseRangeBoost, function(x) AA.CloseRangeBoost=x end)
local predictionSlider = mkSlider(AimbotP,"Lead Prediction", 0, 0.75, AA.Prediction, function(x) AA.Prediction=x end,"s")

-- Recoil sub-section
local rcEn = mkToggle(AimbotP,"Recoil Control", RC.Enabled, function(v,row) RC.Enabled=v end)
local rcShoot = mkToggle(AimbotP,"RC: Only while shooting", RC.OnlyWhileShooting, function(v) RC.OnlyWhileShooting=v end)
local rcV = mkSlider(AimbotP,"RC: Vertical Strength", 0, 3, RC.VerticalStrength, function(x) RC.VerticalStrength=x end)
local rcH = mkSlider(AimbotP,"RC: Horizontal Strength", 0, 3, RC.HorizontalStrength, function(x) RC.HorizontalStrength=x end)
local rcS = mkSlider(AimbotP,"RC: Smooth", 0.05, 1, RC.Smooth, function(x) RC.Smooth=x end)
local function refreshRCUI()
    local on=RC.Enabled
    setInteractable(rcShoot.Row,on); setInteractable(rcV.Row,on); setInteractable(rcH.Row,on); setInteractable(rcS.Row,on)
    setInteractable(stickyDuration.Row, AA.StickyAim)
    setInteractable(closeBoost.Row, AA.AdaptiveSmoothing)
    if partCycle and partCycle.Row then setInteractable(partCycle.Row, not AA.DynamicPart) end
end
RunService.RenderStepped:Connect(refreshRCUI)

-- ESP
mkToggle(ESPP,"Enable ESP", ESP.Enabled, function(v) ESP.Enabled=v end)
mkToggle(ESPP,"Enemies Only", ESP.EnemiesOnly, function(v) ESP.EnemiesOnly=v end)
mkToggle(ESPP,"Use Distance Limit", ESP.UseDistance, function(v) ESP.UseDistance=v end)
mkSlider(ESPP,"Max Distance", 50, 2000, ESP.MaxDistance, function(x) ESP.MaxDistance=math.floor(x) end,"studs")
mkToggle(ESPP,"Render Through Walls", ESP.ThroughWalls, function(v) ESP.ThroughWalls=v end)
mkSlider(ESPP,"Fill Transparency", 0, 1, ESP.FillTransparency, function(x) ESP.FillTransparency=x end)
mkSlider(ESPP,"Outline Transparency", 0, 1, ESP.OutlineTransparency, function(x) ESP.OutlineTransparency=x end)

-- Visuals
local crossT = mkToggle(VisualP,"Crosshair", Cross.Enabled, function(v) Cross.Enabled=v; updCross() end)
mkSlider(VisualP,"Opacity", 0.1,1, Cross.Opacity, function(x) Cross.Opacity=x; updCross() end)
mkSlider(VisualP,"Size", 4,24, Cross.Size, function(x) Cross.Size=math.floor(x); updCross() end)
mkSlider(VisualP,"Gap", 2,20, Cross.Gap, function(x) Cross.Gap=math.floor(x); updCross() end)
mkSlider(VisualP,"Thickness", 1,6, Cross.Thickness, function(x) Cross.Thickness=math.floor(x); updCross() end)
local dotT = mkToggle(VisualP,"Center Dot", Cross.CenterDot, function(v) Cross.CenterDot=v; updCross() end)
local dotS = mkSlider(VisualP,"Dot Size", 1,6, Cross.DotSize, function(x) Cross.DotSize=math.floor(x); updCross() end)
local dotO = mkSlider(VisualP,"Dot Opacity", 0.1,1, Cross.DotOpacity, function(x) Cross.DotOpacity=x; updCross() end)
local teamColorToggle
local rainbowToggle
teamColorToggle = mkToggle(VisualP,"Use Team Color", Cross.UseTeamColor, function(v)
    Cross.UseTeamColor=v
    if v and rainbowToggle then
        Cross.Rainbow=false
        rainbowToggle.Set(false)
    end
    updCross()
end)
rainbowToggle = mkToggle(VisualP,"Rainbow Cycle", Cross.Rainbow, function(v)
    Cross.Rainbow=v
    if v and teamColorToggle then
        Cross.UseTeamColor=false
        teamColorToggle.Set(false)
    end
    updCross()
end)
local rainbowSpeed = mkSlider(VisualP,"Rainbow Speed", 0.2, 3, Cross.RainbowSpeed, function(x) Cross.RainbowSpeed=x; updCross() end)
local pulseToggle = mkToggle(VisualP,"Pulse Opacity", Cross.Pulse, function(v) Cross.Pulse=v; updCross() end)
local pulseSpeed = mkSlider(VisualP,"Pulse Speed", 0.5, 5, Cross.PulseSpeed, function(x) Cross.PulseSpeed=x; updCross() end)
RunService.RenderStepped:Connect(function()
    local on=Cross.CenterDot; setInteractable(dotS.Row,on); setInteractable(dotO.Row,on)
    if rainbowSpeed then setInteractable(rainbowSpeed.Row, Cross.Rainbow) end
    if pulseSpeed then setInteractable(pulseSpeed.Row, Cross.Pulse) end
end)

-- Misc
mkToggle(MiscP,"Press K to toggle UI", true, function() end)
local dragToggle = mkToggle(MiscP,"Allow Dragging", true, function(v)
    draggingEnabled = v
    if not v then dragging=false end
end)
local centerBtn = mkButton(MiscP, "Center Panel", function()
    Root.Position = UDim2.fromScale(0.5,0.5)
    dragging = false
end, {buttonText="Center"})
local scaleSlider = mkSlider(MiscP,"UI Scale", 0.85, 1.25, PanelScale.Scale, function(x) PanelScale.Scale=x end,"x")

-- Kill Menu logic
local function killMenu()
    -- hide all UIs
    if Root then Root.Visible = false end
    if Gate then Gate.Enabled = false end
    if SuccessGui then SuccessGui.Enabled = false end
    if AA_GUI then AA_GUI.Enabled = false end
    if CrossGui then CrossGui.Enabled = false end
    -- remove blur
    TweenService:Create(Blur, TweenInfo.new(0.15), {Size = 0}):Play()
    Blur.Enabled = false
    -- disable features so runtime loops render nothing
    AA.Enabled=false; RC.Enabled=false; ESP.Enabled=false; Cross.Enabled=false; updCross()
    stickyTarget=nil; stickyTimer=0
    -- clean existing highlights
    for _,pl in ipairs(Players:GetPlayers()) do
        local ch = pl.Character
        if ch then local h = ch:FindFirstChild("_HL_"); if h then pcall(function() h:Destroy() end) end end
    end
end

-- panic key (P) also kills the menu
UserInputService.InputBegan:Connect(function(i)
    if i.KeyCode==Enum.KeyCode.K then Root.Visible = not Root.Visible end
    if i.KeyCode==Enum.KeyCode.P then killMenu() end
end)

-- Button to kill menu
mkButton(MiscP, "Kill Menu (remove UI)", function() killMenu() end, {danger=true, buttonText="Kill Menu"})

-- Config / profiles
local BASE="ProfitCruiser"; local PROF=BASE.."/Profiles"; local MODE="memory"; local MEM=rawget(_G,"PC_ProfileStore") or {}; _G.PC_ProfileStore=MEM
local function ensure() if makefolder then local ok1=true if not (isfolder and isfolder(BASE)) then ok1=pcall(function() makefolder(BASE) end) end local ok2=true if not (isfolder and isfolder(PROF)) then ok2=pcall(function() makefolder(PROF) end) end return ok1 and ok2 end return false end
if ensure() and writefile and readfile then MODE="filesystem" end
local function deep(dst,src) for k,v in pairs(src) do if typeof(v)=="table" and typeof(dst[k])=="table" then deep(dst[k],v) else dst[k]=v end end end
local function gather() return {RC=RC, AA=AA, ESP=ESP, Cross=Cross} end
local function apply(s) if not s then return end deep(RC,s.RC or {}); deep(AA,s.AA or {}); deep(ESP,s.ESP or {}); deep(Cross,s.Cross or {}); updCross() end
local function save(name) local ok,data=pcall(function() return HttpService:JSONEncode(gather()) end); if not ok then return false,"encode" end if MODE=="filesystem" then local p=PROF.."/"..name..".json"; local s,err=pcall(function() writefile(p,data) end); return s,(s and nil or tostring(err)) else MEM[name]=data; return true end end
local function load(name) if MODE=="filesystem" then local p=PROF.."/"..name..".json"; if not (isfile and isfile(p)) then return false,"missing" end local ok,raw=pcall(function() return readfile(p) end); if not ok then return false,"read" end local ok2,tbl=pcall(function() return HttpService:JSONDecode(raw) end); if not ok2 then return false,"decode" end apply(tbl); return true else local raw=MEM[name]; if not raw then return false,"missing" end local ok2,tbl=pcall(function() return HttpService:JSONDecode(raw) end); if not ok2 then return false,"decode" end apply(tbl); return true end end

local saveBtn = mkToggle(ConfP,"Save Default (click)", false, function(v,row) if v then local ok,err=save("Default"); (row:FindFirstChildWhichIsA("TextLabel")).Text = ok and "Saved Default ✅" or ("Save failed: "..tostring(err)); task.delay(0.4,function() (row:FindFirstChildWhichIsA("TextLabel")).Text="Save Default (click)" end) end end)
local loadBtn = mkToggle(ConfP,"Load Default (click)", false, function(v,row) if v then local ok,err=load("Default"); (row:FindFirstChildWhichIsA("TextLabel")).Text = ok and "Loaded Default ✅" or ("Load failed: "..tostring(err)); task.delay(0.4,function() (row:FindFirstChildWhichIsA("TextLabel")).Text="Load Default (click)" end) end end)

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
