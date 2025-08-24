--// VibeMenu — Minimal Template LIB
--// Load like: local VibeMenu = loadstring(game:HttpGet(URL))()
--// Then: local ui = VibeMenu.Init({ title="VibeMenu", toggleKey = Enum.KeyCode.K })

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS      = game:GetService("UserInputService")
local TweenS   = game:GetService("TweenService")
local CoreGui  = game:GetService("CoreGui")
local Camera   = workspace.CurrentCamera

local function clamp(n,a,b) return math.clamp(n,a,b) end

local VibeMenu = {}    -- library table
VibeMenu._state = {}   -- will hold runtime ui refs

----------------------------------------------------------------
-- Internal helpers (no UI until Init is called)
----------------------------------------------------------------
local function makeTabButton(text)
    local b = Instance.new("TextButton")
    b.Text = text
    b.AutoButtonColor = false
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 14
    b.TextColor3 = Color3.fromRGB(220,230,255)
    b.BackgroundColor3 = Color3.fromRGB(34,36,48)
    b.Size = UDim2.fromOffset(110,36)
    b.ZIndex = 2
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
    local s = Instance.new("UIStroke", b)
    s.Color = Color3.fromRGB(80,100,170)
    s.Transparency = 0.25
    b.MouseEnter:Connect(function()
        TweenS:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(42,44,60)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenS:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(34,36,48)}):Play()
    end)
    return b
end

local function createPage(container, name)
    local pg = Instance.new("ScrollingFrame", container)
    pg.Name = name
    pg.Active = true
    pg.ScrollBarThickness = 6
    pg.BackgroundTransparency = 1
    pg.Size = UDim2.fromScale(1,1)
    pg.Visible = false
    pg.AutomaticCanvasSize = Enum.AutomaticSize.None
    pg.CanvasSize = UDim2.new(0,0,0,0)

    local list = Instance.new("UIListLayout", pg)
    list.Padding = UDim.new(0,8)
    list.SortOrder = Enum.SortOrder.LayoutOrder

    local function fit()
        task.defer(function()
            pg.CanvasSize = UDim2.new(0,0,0, list.AbsoluteContentSize.Y + 8)
        end)
    end
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
    fit()

    return pg
end

local function card(parent, titleText)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1,-8,0,0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundColor3 = Color3.fromRGB(28,30,42)
    f.ZIndex = 2
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,10)
    local st = Instance.new("UIStroke", f)
    st.Color = Color3.fromRGB(70,120,255)
    st.Transparency = 0.55

    local title = Instance.new("TextLabel", f)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(230,236,255)
    title.Position = UDim2.fromOffset(10,8)
    title.Size = UDim2.new(1,-20,0,16)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 2

    local inner = Instance.new("Frame", f)
    inner.Name = "Inner"
    inner.Position = UDim2.fromOffset(10, 30)
    inner.Size = UDim2.new(1,-20,0,0)
    inner.BackgroundTransparency = 1
    inner.AutomaticSize = Enum.AutomaticSize.Y
    inner.ZIndex = 2
    local list = Instance.new("UIListLayout", inner)
    list.Padding = UDim.new(0,6)
    list.SortOrder = Enum.SortOrder.LayoutOrder

    return inner, f
end

----------------------------------------------------------------
-- Public: Init
----------------------------------------------------------------
function VibeMenu.Init(opts)
    opts = opts or {}
    local titleText = tostring(opts.title or "VibeMenu")
    local toggleKey = opts.toggleKey or Enum.KeyCode.K

    -- cleanup any previous instance named VibeMenu
    pcall(function()
        local old = CoreGui:FindFirstChild("VibeMenu")
        if old then old:Destroy() end
    end)

    -- ROOT
    local Gui = Instance.new("ScreenGui")
    Gui.Name = "VibeMenu"
    Gui.DisplayOrder = 9999
    Gui.IgnoreGuiInset = true
    Gui.ResetOnSpawn = false
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    Gui.Parent = CoreGui

    -- Window
    local Window = Instance.new("Frame", Gui)
    Window.Name = "Window"
    Window.BackgroundColor3 = Color3.fromRGB(23,24,32)
    Window.ClipsDescendants = true
    Window.Position = UDim2.fromOffset(8,8)
    Window.Size = UDim2.fromOffset(720, 480)
    Instance.new("UICorner", Window).CornerRadius = UDim.new(0,12)
    local winStroke = Instance.new("UIStroke", Window)
    winStroke.Color = Color3.fromRGB(70,120,255)
    winStroke.Thickness = 1
    winStroke.Transparency = 0.6

    -- Galaxy (inside)
    local GalaxyBG = Instance.new("Frame", Window)
    GalaxyBG.BackgroundTransparency = 1
    GalaxyBG.Size = UDim2.fromScale(1,1)
    GalaxyBG.ClipsDescendants = true
    GalaxyBG.ZIndex = 0

    local Stars = Instance.new("Frame", GalaxyBG)
    Stars.BackgroundTransparency = 1
    Stars.Size = UDim2.fromScale(1,1)
    Stars.ZIndex = 0
    local starPool = {}
    for i=1,90 do
        local d = Instance.new("Frame")
        d.Size = UDim2.fromOffset(2,2)
        d.BackgroundColor3 = Color3.fromRGB(170,120,255)
        d.BorderSizePixel = 0
        d.BackgroundTransparency = 0.15
        d.Position = UDim2.fromScale(math.random(), math.random())
        d.Parent = Stars
        table.insert(starPool, d)
    end
    RunService.Heartbeat:Connect(function(dt)
        for i,pt in ipairs(starPool) do
            local p = pt.Position.Y.Scale + (0.03 + (i % 7)*0.001)*dt
            if p>1 then p = 0 end
            pt.Position = UDim2.fromScale(pt.Position.X.Scale, p)
        end
    end)

    -- Topbar
    local Top = Instance.new("Frame", Window)
    Top.Size = UDim2.new(1,0,0,42)
    Top.BackgroundColor3 = Color3.fromRGB(18,20,28)
    Top.ZIndex = 3
    Instance.new("UICorner", Top).CornerRadius = UDim.new(0,12)

    local Title = Instance.new("TextLabel", Top)
    Title.BackgroundTransparency = 1
    Title.Text = titleText
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextColor3 = Color3.fromRGB(235,240,255)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Position = UDim2.fromOffset(12,10)
    Title.Size = UDim2.fromOffset(220,22)
    Title.ZIndex = 3

    local Hint = Instance.new("TextLabel", Top)
    Hint.BackgroundTransparency = 1
    Hint.Text = "[K] to toggle"
    Hint.Font = Enum.Font.Gotham
    Hint.TextSize = 12
    Hint.TextColor3 = Color3.fromRGB(175,185,210)
    Hint.AnchorPoint = Vector2.new(1,0)
    Hint.Position = UDim2.new(1,-12,0,13)
    Hint.Size = UDim2.fromOffset(120,18)
    Hint.TextXAlignment = Enum.TextXAlignment.Right
    Hint.ZIndex = 3

    -- Tabs
    local Tabs = Instance.new("Frame", Window)
    Tabs.Position = UDim2.fromOffset(10, 52)
    Tabs.Size = UDim2.new(1,-20,0,36)
    Tabs.BackgroundTransparency = 1
    Tabs.ZIndex = 2
    local TabsList = Instance.new("UIListLayout", Tabs)
    TabsList.FillDirection = Enum.FillDirection.Horizontal
    TabsList.Padding = UDim.new(0,10)
    TabsList.VerticalAlignment = Enum.VerticalAlignment.Center

    -- Content
    local Content = Instance.new("Frame", Window)
    Content.Name = "Content"
    Content.BackgroundTransparency = 1
    Content.Position = UDim2.fromOffset(10, 96)
    Content.Size = UDim2.new(1,-20,1,-106)
    Content.ZIndex = 2

    -- State container we return as API instance
    local inst = {
        _gui = Gui,
        _window = Window,
        _tabs = Tabs,
        _content = Content,
        _pages = {},
        _current = nil,
        _toggleKey = toggleKey
    }

    function inst:SwitchTo(name)
        for n,pg in pairs(self._pages) do
            pg.Visible = (n==name)
        end
        self._current = name
    end

    function inst:AddTab(name)
        local btn = makeTabButton(name)
        btn.Parent = self._tabs
        btn.MouseButton1Click:Connect(function() self:SwitchTo(name) end)
        return btn
    end

    function inst:CreatePage(name)
        local pg = createPage(self._content, name)
        self._pages[name] = pg
        return pg
    end

    function inst:Card(parent, titleText)
        return card(parent, titleText) -- returns inner, outer
    end

    -- Controls
    function inst:Toggle(parent, label, default, cb)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1,0,0,28)
        row.BackgroundTransparency = 1

        local t = Instance.new("TextLabel", row)
        t.BackgroundTransparency = 1; t.Text = label; t.Font = Enum.Font.Gotham
        t.TextSize = 13; t.TextColor3 = Color3.fromRGB(210,220,240)
        t.TextXAlignment = Enum.TextXAlignment.Left; t.Size = UDim2.new(1,-70,1,0)

        local btn = Instance.new("TextButton", row)
        btn.AnchorPoint = Vector2.new(1,0.5); btn.Position = UDim2.new(1,0,0.5,0)
        btn.Size = UDim2.fromOffset(54,22); btn.Text = ""; btn.AutoButtonColor=false
        btn.BackgroundColor3 = Color3.fromRGB(24,26,36)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0)
        local dot = Instance.new("Frame", btn)
        dot.Size = UDim2.fromOffset(18,18); dot.Position = UDim2.fromOffset(3,2)
        dot.BackgroundColor3 = Color3.fromRGB(140,140,150); dot.BorderSizePixel=0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

        local value = not not default
        local function apply(v)
            value = not not v
            if value then
                TweenS:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(0,170,130)}):Play()
                TweenS:Create(dot, TweenInfo.new(0.18), {Position = UDim2.fromOffset(33,2), BackgroundColor3 = Color3.fromRGB(235,255,255)}):Play()
            else
                TweenS:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(24,26,36)}):Play()
                TweenS:Create(dot, TweenInfo.new(0.18), {Position = UDim2.fromOffset(3,2), BackgroundColor3 = Color3.fromRGB(140,140,150)}):Play()
            end
            if cb then pcall(cb, value) end
        end
        btn.MouseButton1Click:Connect(function() apply(not value) end)
        apply(value)
        return { Set = apply, Get=function() return value end }
    end

    function inst:Slider(parent, label, min,max,increment, default, cb)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1,0,0,40)
        row.BackgroundTransparency = 1

        local t = Instance.new("TextLabel", row)
        t.BackgroundTransparency = 1; t.Text = label; t.Font = Enum.Font.Gotham
        t.TextSize = 13; t.TextColor3 = Color3.fromRGB(210,220,240)
        t.TextXAlignment = Enum.TextXAlignment.Left; t.Size = UDim2.new(1,0,0,16)

        local valueLbl = Instance.new("TextLabel", row)
        valueLbl.BackgroundTransparency = 1; valueLbl.Text = tostring(default or min)
        valueLbl.Font=Enum.Font.Gotham; valueLbl.TextSize=12; valueLbl.TextColor3=Color3.fromRGB(170,180,210)
        valueLbl.AnchorPoint=Vector2.new(1,0); valueLbl.Position=UDim2.new(1,0,0,0)
        valueLbl.Size = UDim2.fromOffset(80,16); valueLbl.TextXAlignment=Enum.TextXAlignment.Right

        local bar = Instance.new("Frame", row)
        bar.Position = UDim2.fromOffset(0,22); bar.Size = UDim2.new(1,0,0,12)
        bar.BackgroundColor3 = Color3.fromRGB(32,34,46)
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)
        local fill = Instance.new("Frame", bar)
        fill.BackgroundColor3 = Color3.fromRGB(0,200,255); fill.Size = UDim2.fromScale(0,1)
        fill.BorderSizePixel = 0; Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

        local dragging = false; local val = default or min
        local function setTo(px)
            local a = clamp((px - bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
            local v = min + a*(max-min)
            if increment and increment>0 then v = math.floor(v/increment+0.5)*increment end
            v = clamp(v, min, max); val = v
            fill.Size = UDim2.fromScale((v-min)/(max-min),1)
            valueLbl.Text = tostring(v)
            if cb then pcall(cb, v) end
        end
        bar.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                dragging=true; setTo(i.Position.X)
            end
        end)
        bar.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                setTo(i.Position.X)
            end
        end)
        task.defer(function()
            if bar.AbsoluteSize.X>0 then
                setTo(bar.AbsolutePosition.X + clamp((val-min)/(max-min),0,1)*bar.AbsoluteSize.X)
            end
        end)
        return { Set=function(v) setTo(bar.AbsolutePosition.X + clamp((v-min)/(max-min),0,1)*bar.AbsoluteSize.X) end, Get=function() return val end }
    end

    function inst:Button(parent, text, cb)
        local b = Instance.new("TextButton", parent)
        b.AutoButtonColor = true; b.Text = text
        b.Font = Enum.Font.GothamBold; b.TextSize = 13
        b.TextColor3 = Color3.fromRGB(235,240,255)
        b.BackgroundColor3 = Color3.fromRGB(34,36,48)
        b.Size = UDim2.fromOffset(140,32)
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
        b.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
        return b
    end

    function inst:Input(parent, placeholder, cb)
        local box = Instance.new("TextBox", parent)
        box.PlaceholderText = placeholder or "Type here"
        box.Text = ""
        box.Font = Enum.Font.Gotham
        box.TextSize = 14
        box.TextColor3 = Color3.fromRGB(235,240,255)
        box.BackgroundColor3 = Color3.fromRGB(28,30,42)
        box.Size = UDim2.fromOffset(220,34)
        Instance.new("UICorner", box).CornerRadius = UDim.new(0,8)
        box.FocusLost:Connect(function(enter) if enter and cb then pcall(cb, box.Text) end end)
        return box
    end

    function inst:Dropdown(parent, label, options, currentIndex, cb)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1,0,0,34); row.BackgroundTransparency = 1
        local t = Instance.new("TextLabel", row)
        t.BackgroundTransparency=1; t.Text = label; t.Font=Enum.Font.Gotham; t.TextSize=13
        t.TextColor3=Color3.fromRGB(210,220,240); t.TextXAlignment=Enum.TextXAlignment.Left
        t.Size = UDim2.new(1,-160,1,0)
        local b = Instance.new("TextButton", row)
        b.AnchorPoint=Vector2.new(1,0.5); b.Position=UDim2.new(1,0,0.5,0)
        b.Size = UDim2.fromOffset(150,28); b.Font=Enum.Font.GothamSemibold; b.TextSize=12
        b.BackgroundColor3=Color3.fromRGB(34,36,48); b.TextColor3=Color3.fromRGB(220,230,255)
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)

        local idx = currentIndex or 1
        local function apply(i)
            idx = ((i-1) % #options)+1
            b.Text = tostring(options[idx])
            if cb then pcall(cb, options[idx], idx) end
        end
        b.MouseButton1Click:Connect(function() apply(idx+1) end)
        apply(idx)
        return { SetIndex=apply, GetIndex=function() return idx end }
    end

    function inst:Color(parent, label, default, cb)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1,0,0,28); row.BackgroundTransparency=1
        local t = Instance.new("TextLabel", row)
        t.BackgroundTransparency=1; t.Text=label; t.Font=Enum.Font.Gotham; t.TextSize=13
        t.TextColor3=Color3.fromRGB(210,220,240); t.TextXAlignment=Enum.TextXAlignment.Left
        t.Size = UDim2.new(1,-40,1,0)
        local sw = Instance.new("TextButton", row)
        sw.AnchorPoint=Vector2.new(1,0.5); sw.Position=UDim2.new(1,0,0.5,0)
        sw.Size = UDim2.fromOffset(28,18); sw.Text=""; sw.AutoButtonColor=true
        sw.BackgroundColor3 = default or Color3.fromRGB(255,255,255)
        Instance.new("UICorner", sw).CornerRadius = UDim.new(0,6)
        local val = default or Color3.fromRGB(255,255,255)
        sw.MouseButton1Click:Connect(function()
            local h=select(1,val:ToHSV()); h=(h+0.12)%1
            val=Color3.fromHSV(h,1,1); sw.BackgroundColor3=val
            if cb then pcall(cb,val) end
        end)
        return { Set=function(c) val=c; sw.BackgroundColor3=c; if cb then cb(c) end end, Get=function() return val end }
    end

    function inst:SetToggleKey(keycode)
        self._toggleKey = keycode or Enum.KeyCode.K
    end

    function inst:Destroy()
        if self._gui then self._gui:Destroy() end
        self._pages = {}
    end

    -- window fit + toggle
    local function fitWindow()
        local v = Camera.ViewportSize
        local w = math.clamp(v.X - 16, 520, 980)
        local h = math.clamp(v.Y - 16, 360, 640)
        Window.Size = UDim2.fromOffset(w, h)
    end
    fitWindow()
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitWindow)

    UIS.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == (inst._toggleKey or Enum.KeyCode.K) then
            Window.Visible = not Window.Visible
        end
    end)

    -- expose building blocks too
    inst._makeCard = card

    return inst
end

----------------------------------------------------------------
-- Return library table
----------------------------------------------------------------
return VibeMenu
