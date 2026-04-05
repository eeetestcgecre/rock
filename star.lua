-- ============================================================
--  RockstarUI Library  |  Roblox Luau  |  LocalScript
--  Inspired by Rockstar Client's ClickGUI aesthetic
--  Dark theme · Smooth animations · Clean API
-- ============================================================

local RockstarUI = {}
RockstarUI.__index = RockstarUI

-- ── Services ────────────────────────────────────────────────
local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ── Theme ────────────────────────────────────────────────────
local Theme = {
    Background   = Color3.fromRGB(18,  18,  20),   -- main window bg
    Panel        = Color3.fromRGB(25,  25,  28),   -- panel/section bg
    Accent       = Color3.fromRGB(200, 60,  60),   -- red accent (Rockstar red)
    AccentDark   = Color3.fromRGB(140, 30,  30),
    Text         = Color3.fromRGB(230, 230, 230),
    TextDim      = Color3.fromRGB(140, 140, 145),
    Toggle_ON    = Color3.fromRGB(200, 60,  60),
    Toggle_OFF   = Color3.fromRGB(50,  50,  55),
    Slider_Track = Color3.fromRGB(40,  40,  45),
    Border       = Color3.fromRGB(45,  45,  50),
    Notif_BG     = Color3.fromRGB(22,  22,  25),
    Shadow       = Color3.fromRGB(0,   0,   0),
}

-- ── Tween helper ─────────────────────────────────────────────
local function Tween(obj, props, duration, style, dir)
    style    = style or Enum.EasingStyle.Quart
    dir      = dir   or Enum.EasingDirection.Out
    duration = duration or 0.18
    return TweenService:Create(obj,
        TweenInfo.new(duration, style, dir), props):Play()
end

-- ── Utility: make a rounded frame ───────────────────────────
local function RoundFrame(parent, size, pos, color, radius, name)
    local f = Instance.new("Frame")
    f.Name            = name or "Frame"
    f.Size            = size
    f.Position        = pos
    f.BackgroundColor3 = color
    f.BorderSizePixel = 0
    f.Parent          = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = f
    return f
end

local function Label(parent, text, size, pos, color, fontSize, bold)
    local l = Instance.new("TextLabel")
    l.Size              = size
    l.Position          = pos
    l.Text              = text
    l.TextColor3        = color or Theme.Text
    l.BackgroundTransparency = 1
    l.Font              = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize          = fontSize or 13
    l.TextXAlignment    = Enum.TextXAlignment.Left
    l.Parent            = parent
    return l
end

-- ── Dragging helper ─────────────────────────────────────────
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ════════════════════════════════════════════════════════════
--  NOTIFICATION SYSTEM
-- ════════════════════════════════════════════════════════════
local NotifHolder  -- initialized in CreateWindow
local notifQueue = {}

local function SpawnNotif(title, message, duration, ntype)
    if not NotifHolder then return end
    duration = duration or 3

    local color = ({
        info    = Color3.fromRGB(60, 120, 200),
        success = Color3.fromRGB(60, 180, 80),
        warning = Color3.fromRGB(210, 160, 30),
        error   = Color3.fromRGB(200, 55, 55),
    })[ntype] or Theme.Accent

    -- container
    local card = RoundFrame(NotifHolder,
        UDim2.new(1, 0, 0, 64), UDim2.new(0, 0, 0, 0),
        Theme.Notif_BG, 8, "Notif")
    card.ClipsDescendants = true

    -- left accent bar
    local bar = Instance.new("Frame")
    bar.Size              = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3  = color
    bar.BorderSizePixel   = 0
    bar.Parent            = card
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)

    -- timer bar at bottom
    local timerBar = Instance.new("Frame")
    timerBar.Size             = UDim2.new(1, -3, 0, 2)
    timerBar.Position         = UDim2.new(0, 3, 1, -2)
    timerBar.BackgroundColor3 = color
    timerBar.BorderSizePixel  = 0
    timerBar.Parent           = card

    Label(card, title,   UDim2.new(1,-16,0,20), UDim2.new(0,14,0,6),  color,    13, true)
    Label(card, message, UDim2.new(1,-16,0,18), UDim2.new(0,14,0,28), Theme.TextDim, 11, false)

    -- slide in
    card.Position = UDim2.new(1, 10, 0, 0)
    Tween(card, {Position = UDim2.new(0, 0, 0, 0)}, 0.25)

    -- timer bar shrink
    TweenService:Create(timerBar,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {Size = UDim2.new(0, 0, 0, 2)}):Play()

    -- auto dismiss
    task.delay(duration, function()
        Tween(card, {Position = UDim2.new(1, 10, 0, 0)}, 0.2)
        task.wait(0.25)
        card:Destroy()
    end)
end

-- ════════════════════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════════════════════
function RockstarUI:CreateWindow(opts)
    opts = opts or {}
    local Title    = opts.Title    or "RockstarUI"
    local Width    = opts.Width    or 540
    local TabWidth = opts.TabWidth or 120
    local KeyBind  = opts.KeyBind  -- Enum.KeyCode, optional

    -- ── ScreenGui ──────────────────────────────────────────
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name            = "RockstarUI"
    ScreenGui.ResetOnSpawn    = false
    ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset  = true
    ScreenGui.Parent          = LocalPlayer.PlayerGui

    -- ── Notification holder (bottom-right) ─────────────────
    local nh = Instance.new("Frame")
    nh.Name               = "NotifHolder"
    nh.Size               = UDim2.new(0, 260, 0, 400)
    nh.Position           = UDim2.new(1,-270, 1,-410)
    nh.BackgroundTransparency = 1
    nh.Parent             = ScreenGui
    local nhLayout = Instance.new("UIListLayout", nh)
    nhLayout.FillDirection  = Enum.FillDirection.Vertical
    nhLayout.SortOrder      = Enum.SortOrder.LayoutOrder
    nhLayout.Padding        = UDim.new(0, 6)
    nhLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifHolder = nh

    -- ── Main frame ─────────────────────────────────────────
    local Main = RoundFrame(ScreenGui,
        UDim2.new(0, Width, 0, 380),
        UDim2.new(0.5, -Width/2, 0.5, -190),
        Theme.Background, 10, "Main")
    Main.ClipsDescendants = true

    -- shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Image              = "rbxassetid://7912134082"
    shadow.ImageColor3        = Theme.Shadow
    shadow.ImageTransparency  = 0.55
    shadow.Size               = UDim2.new(1, 30, 1, 30)
    shadow.Position           = UDim2.new(0,-15, 0,-15)
    shadow.BackgroundTransparency = 1
    shadow.ZIndex             = 0
    shadow.Parent             = Main

    -- ── Title bar ──────────────────────────────────────────
    local TitleBar = RoundFrame(Main,
        UDim2.new(1, 0, 0, 36),
        UDim2.new(0, 0, 0, 0),
        Theme.Panel, 0, "TitleBar")
    -- bottom corners only via a cover
    local TBCover = Instance.new("Frame")
    TBCover.Size             = UDim2.new(1,0,0,8)
    TBCover.Position         = UDim2.new(0,0,1,-8)
    TBCover.BackgroundColor3 = Theme.Panel
    TBCover.BorderSizePixel  = 0
    TBCover.Parent           = TitleBar

    -- accent strip
    local strip = Instance.new("Frame")
    strip.Size             = UDim2.new(1,0,0,2)
    strip.Position         = UDim2.new(0,0,1,-2)
    strip.BackgroundColor3 = Theme.Accent
    strip.BorderSizePixel  = 0
    strip.Parent           = TitleBar

    -- logo dot
    local dot = Instance.new("Frame")
    dot.Size              = UDim2.new(0,8,0,8)
    dot.Position          = UDim2.new(0,12,0.5,-4)
    dot.BackgroundColor3  = Theme.Accent
    dot.BorderSizePixel   = 0
    dot.Parent            = TitleBar
    Instance.new("UICorner",dot).CornerRadius = UDim.new(1,0)

    Label(TitleBar, Title, UDim2.new(0,120,1,0), UDim2.new(0,26,0,0),
        Theme.Text, 14, true)

    -- close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size              = UDim2.new(0,30,0,30)
    closeBtn.Position          = UDim2.new(1,-34,0.5,-15)
    closeBtn.Text              = "✕"
    closeBtn.TextColor3        = Theme.TextDim
    closeBtn.BackgroundTransparency = 1
    closeBtn.Font              = Enum.Font.GothamBold
    closeBtn.TextSize          = 13
    closeBtn.Parent            = TitleBar
    closeBtn.MouseButton1Click:Connect(function()
        Tween(Main, {Size = UDim2.new(0,Width,0,0),
                     Position = UDim2.new(0.5,-Width/2,0.5,0)}, 0.2)
        task.wait(0.22)
        Main.Visible = false
        Main.Size     = UDim2.new(0,Width,0,380)
        Main.Position = UDim2.new(0.5,-Width/2,0.5,-190)
    end)

    MakeDraggable(Main, TitleBar)

    -- ── Tab sidebar ────────────────────────────────────────
    local SideBar = RoundFrame(Main,
        UDim2.new(0, TabWidth, 1, -36),
        UDim2.new(0, 0, 0, 36),
        Theme.Panel, 0, "SideBar")
    local SBCover = Instance.new("Frame")
    SBCover.Size             = UDim2.new(0,6,1,0)
    SBCover.Position         = UDim2.new(1,-6,0,0)
    SBCover.BackgroundColor3 = Theme.Panel
    SBCover.BorderSizePixel  = 0
    SBCover.Parent           = SideBar

    local SideList = Instance.new("UIListLayout", SideBar)
    SideList.SortOrder = Enum.SortOrder.LayoutOrder
    SideList.Padding   = UDim.new(0, 2)

    local SidePad = Instance.new("UIPadding", SideBar)
    SidePad.PaddingTop    = UDim.new(0,8)
    SidePad.PaddingLeft   = UDim.new(0,6)
    SidePad.PaddingRight  = UDim.new(0,6)

    -- ── Content area ───────────────────────────────────────
    local ContentArea = Instance.new("Frame")
    ContentArea.Name              = "ContentArea"
    ContentArea.Size              = UDim2.new(1,-TabWidth,1,-36)
    ContentArea.Position          = UDim2.new(0,TabWidth,0,36)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ClipsDescendants  = true
    ContentArea.Parent            = Main

    -- ── Toggle open/close ─────────────────────────────────
    if KeyBind then
        UserInputService.InputBegan:Connect(function(input, gpe)
            if not gpe and input.KeyCode == KeyBind then
                Main.Visible = not Main.Visible
                if Main.Visible then
                    Main.Size = UDim2.new(0,Width,0,0)
                    Tween(Main, {Size = UDim2.new(0,Width,0,380)}, 0.22)
                end
            end
        end)
    end

    -- ── Animate on open ────────────────────────────────────
    Main.Size = UDim2.new(0,Width,0,0)
    Tween(Main, {Size = UDim2.new(0,Width,0,380)}, 0.25)

    -- ── Window object ──────────────────────────────────────
    local Window = {
        _tabs       = {},
        _activeTab  = nil,
        _sideBar    = SideBar,
        _content    = ContentArea,
        _tabWidth   = TabWidth,
        Notify      = SpawnNotif,
    }

    -- ── AddTab ─────────────────────────────────────────────
    function Window:AddTab(tabName, icon)
        icon = icon or ""

        -- sidebar button
        local btn = Instance.new("TextButton")
        btn.Name              = tabName
        btn.Size              = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3  = Theme.Background
        btn.BorderSizePixel   = 0
        btn.Text              = (icon ~= "" and icon.." " or "")..tabName
        btn.TextColor3        = Theme.TextDim
        btn.Font              = Enum.Font.Gotham
        btn.TextSize          = 12
        btn.TextXAlignment    = Enum.TextXAlignment.Left
        btn.LayoutOrder       = #self._tabs + 1
        btn.Parent            = self._sideBar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
        local bPad = Instance.new("UIPadding", btn)
        bPad.PaddingLeft = UDim.new(0,8)

        -- content scroll frame
        local page = Instance.new("ScrollingFrame")
        page.Name                = tabName.."Page"
        page.Size                = UDim2.new(1,0,1,0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel     = 0
        page.ScrollBarThickness  = 2
        page.ScrollBarImageColor3 = Theme.Accent
        page.Visible             = false
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.CanvasSize          = UDim2.new(0,0,0,0)
        page.Parent              = self._content

        local pageList = Instance.new("UIListLayout", page)
        pageList.SortOrder      = Enum.SortOrder.LayoutOrder
        pageList.Padding        = UDim.new(0,4)
        local pagePad = Instance.new("UIPadding", page)
        pagePad.PaddingTop    = UDim.new(0,8)
        pagePad.PaddingLeft   = UDim.new(0,10)
        pagePad.PaddingRight  = UDim.new(0,10)
        pagePad.PaddingBottom = UDim.new(0,8)

        local Tab = {_page = page, _btn = btn, _window = self}
        table.insert(self._tabs, Tab)

        -- activate
        local function Activate()
            if self._activeTab then
                self._activeTab._page.Visible = false
                Tween(self._activeTab._btn, {BackgroundColor3 = Theme.Background,
                    TextColor3 = Theme.TextDim}, 0.12)
            end
            self._activeTab = Tab
            page.Visible = true
            Tween(btn, {BackgroundColor3 = Theme.Accent,
                TextColor3 = Theme.Text}, 0.15)
        end

        btn.MouseButton1Click:Connect(Activate)
        if #self._tabs == 1 then Activate() end

        -- ── Section ────────────────────────────────────────
        function Tab:AddSection(sectionName)
            local sectionOrder = #{page:GetChildren()} + 1

            -- header
            local header = Instance.new("Frame")
            header.Name             = "Section_"..sectionName
            header.Size             = UDim2.new(1,0,0,22)
            header.BackgroundTransparency = 1
            header.LayoutOrder      = sectionOrder
            header.Parent           = page

            Label(header, sectionName:upper(),
                UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
                Theme.TextDim, 10, true)

            local divLine = Instance.new("Frame")
            divLine.Size             = UDim2.new(1,0,0,1)
            divLine.Position         = UDim2.new(0,0,1,-1)
            divLine.BackgroundColor3 = Theme.Border
            divLine.BorderSizePixel  = 0
            divLine.Parent           = header

            local Section = {_page = page, _order = sectionOrder}

            -- ── Toggle ─────────────────────────────────────
            function Section:AddToggle(opts2)
                opts2 = opts2 or {}
                local label    = opts2.Label    or "Toggle"
                local default  = opts2.Default  or false
                local callback = opts2.Callback or function() end
                local state    = default

                local row = RoundFrame(page,
                    UDim2.new(1,0,0,36),
                    UDim2.new(0,0,0,0),
                    Theme.Panel, 6, "Toggle_"..label)
                row.LayoutOrder = sectionOrder + 0.1

                Label(row, label,
                    UDim2.new(1,-54,1,0), UDim2.new(0,10,0,0),
                    Theme.Text, 12)

                -- pill toggle
                local pill = Instance.new("Frame")
                pill.Size             = UDim2.new(0,36,0,18)
                pill.Position         = UDim2.new(1,-46,0.5,-9)
                pill.BackgroundColor3 = state and Theme.Toggle_ON or Theme.Toggle_OFF
                pill.BorderSizePixel  = 0
                pill.Parent           = row
                Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

                local knob = Instance.new("Frame")
                knob.Size             = UDim2.new(0,12,0,12)
                knob.Position         = UDim2.new(0, state and 21 or 3, 0.5,-6)
                knob.BackgroundColor3 = Theme.Text
                knob.BorderSizePixel  = 0
                knob.Parent           = pill
                Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

                local btn2 = Instance.new("TextButton")
                btn2.Size              = UDim2.new(1,0,1,0)
                btn2.BackgroundTransparency = 1
                btn2.Text              = ""
                btn2.Parent            = row

                local Toggle = {}
                function Toggle:Set(val)
                    state = val
                    Tween(pill, {BackgroundColor3 = state and Theme.Toggle_ON or Theme.Toggle_OFF}, 0.15)
                    Tween(knob, {Position = UDim2.new(0, state and 21 or 3, 0.5,-6)}, 0.15)
                    callback(state)
                end
                function Toggle:Get() return state end

                btn2.MouseButton1Click:Connect(function() Toggle:Set(not state) end)
                callback(state)
                return Toggle
            end

            -- ── Slider ─────────────────────────────────────
            function Section:AddSlider(opts2)
                opts2 = opts2 or {}
                local label    = opts2.Label    or "Slider"
                local min      = opts2.Min      or 0
                local max      = opts2.Max      or 100
                local default  = opts2.Default  or min
                local suffix   = opts2.Suffix   or ""
                local callback = opts2.Callback or function() end
                local value    = math.clamp(default, min, max)

                local row = RoundFrame(page,
                    UDim2.new(1,0,0,46),
                    UDim2.new(0,0,0,0),
                    Theme.Panel, 6, "Slider_"..label)
                row.LayoutOrder = sectionOrder + 0.2

                local valLabel = Label(row, tostring(value)..suffix,
                    UDim2.new(0,60,0,16), UDim2.new(1,-68,0,8),
                    Theme.Accent, 12, true)
                valLabel.TextXAlignment = Enum.TextXAlignment.Right

                Label(row, label,
                    UDim2.new(1,-80,0,16), UDim2.new(0,10,0,8),
                    Theme.Text, 12)

                local track = RoundFrame(row,
                    UDim2.new(1,-20,0,4),
                    UDim2.new(0,10,1,-12),
                    Theme.Slider_Track, 2, "Track")

                local fill = RoundFrame(track,
                    UDim2.new((value-min)/(max-min),0,1,0),
                    UDim2.new(0,0,0,0),
                    Theme.Accent, 2, "Fill")

                local Slider = {}
                local sliding = false

                local function UpdateSlider(inputX)
                    local trackAbs = track.AbsoluteSize.X
                    local trackPos = track.AbsolutePosition.X
                    local pct = math.clamp((inputX - trackPos) / trackAbs, 0, 1)
                    value = math.floor(pct * (max - min) + min)
                    Tween(fill, {Size = UDim2.new(pct,0,1,0)}, 0.05)
                    valLabel.Text = tostring(value)..suffix
                    callback(value)
                end

                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = true
                        UpdateSlider(input.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateSlider(input.Position.X)
                    end
                end)

                function Slider:Set(val)
                    value = math.clamp(val, min, max)
                    local pct = (value-min)/(max-min)
                    Tween(fill, {Size = UDim2.new(pct,0,1,0)}, 0.12)
                    valLabel.Text = tostring(value)..suffix
                    callback(value)
                end
                function Slider:Get() return value end
                callback(value)
                return Slider
            end

            -- ── Dropdown ───────────────────────────────────
            function Section:AddDropdown(opts2)
                opts2 = opts2 or {}
                local label    = opts2.Label    or "Dropdown"
                local items    = opts2.Items    or {}
                local default  = opts2.Default  or (items[1] or "")
                local callback = opts2.Callback or function() end
                local selected = default
                local open     = false

                local row = RoundFrame(page,
                    UDim2.new(1,0,0,36),
                    UDim2.new(0,0,0,0),
                    Theme.Panel, 6, "Drop_"..label)
                row.LayoutOrder = sectionOrder + 0.3
                row.ClipsDescendants = false

                Label(row, label,
                    UDim2.new(0.5,0,1,0), UDim2.new(0,10,0,0),
                    Theme.Text, 12)

                local selectedLabel = Label(row, selected,
                    UDim2.new(0.45,0,1,0), UDim2.new(0.5,-4,0,0),
                    Theme.Accent, 12, true)
                selectedLabel.TextXAlignment = Enum.TextXAlignment.Right

                local arrow = Label(row, "▾",
                    UDim2.new(0,16,1,0), UDim2.new(1,-20,0,0),
                    Theme.TextDim, 14)
                arrow.TextXAlignment = Enum.TextXAlignment.Center

                -- dropdown list (rendered above other elements)
                local listFrame = RoundFrame(page.Parent or page,
                    UDim2.new(0, row.AbsoluteSize.X, 0, 0),
                    UDim2.new(0,0,0,0),
                    Theme.Panel, 6, "DropList")
                listFrame.ZIndex = 10
                listFrame.ClipsDescendants = true
                listFrame.Visible = false
                listFrame.BorderSizePixel = 0

                local listLayout = Instance.new("UIListLayout", listFrame)
                listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                local listPad = Instance.new("UIPadding", listFrame)
                listPad.PaddingTop    = UDim.new(0,4)
                listPad.PaddingBottom = UDim.new(0,4)

                for i, item in ipairs(items) do
                    local opt = Instance.new("TextButton")
                    opt.Size              = UDim2.new(1,0,0,26)
                    opt.BackgroundTransparency = 1
                    opt.Text              = item
                    opt.TextColor3        = Theme.Text
                    opt.Font              = Enum.Font.Gotham
                    opt.TextSize          = 12
                    opt.LayoutOrder       = i
                    opt.Parent            = listFrame
                    opt.MouseButton1Click:Connect(function()
                        selected = item
                        selectedLabel.Text = selected
                        open = false
                        listFrame.Visible = false
                        callback(selected)
                    end)
                    opt.MouseEnter:Connect(function()
                        Tween(opt, {TextColor3 = Theme.Accent}, 0.1)
                    end)
                    opt.MouseLeave:Connect(function()
                        Tween(opt, {TextColor3 = Theme.Text}, 0.1)
                    end)
                end

                local itemH    = 26
                local padH     = 8
                local totalH   = #items * itemH + padH

                local openBtn = Instance.new("TextButton")
                openBtn.Size             = UDim2.new(1,0,1,0)
                openBtn.BackgroundTransparency = 1
                openBtn.Text             = ""
                openBtn.Parent           = row
                openBtn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        -- position below the row
                        local abs = row.AbsolutePosition
                        local scrAbs = ContentArea.AbsolutePosition
                        listFrame.Position = UDim2.new(0,
                            abs.X - scrAbs.X,
                            0,
                            abs.Y - scrAbs.Y + 38)
                        listFrame.Size    = UDim2.new(0, row.AbsoluteSize.X, 0, 0)
                        listFrame.Visible = true
                        listFrame.Parent  = ContentArea
                        Tween(listFrame, {Size = UDim2.new(0, row.AbsoluteSize.X, 0, totalH)}, 0.18)
                        Tween(arrow, {Rotation = 180}, 0.15)
                    else
                        Tween(listFrame, {Size = UDim2.new(0, row.AbsoluteSize.X, 0, 0)}, 0.15)
                        Tween(arrow, {Rotation = 0}, 0.15)
                        task.wait(0.16)
                        listFrame.Visible = false
                    end
                end)

                local Dropdown = {}
                function Dropdown:Set(val)
                    selected = val
                    selectedLabel.Text = val
                    callback(selected)
                end
                function Dropdown:Get() return selected end
                callback(selected)
                return Dropdown
            end

            -- ── Button ─────────────────────────────────────
            function Section:AddButton(opts2)
                opts2 = opts2 or {}
                local label    = opts2.Label    or "Button"
                local callback = opts2.Callback or function() end

                local row = RoundFrame(page,
                    UDim2.new(1,0,0,34),
                    UDim2.new(0,0,0,0),
                    Theme.Accent, 6, "Btn_"..label)
                row.LayoutOrder = sectionOrder + 0.4

                local lbl = Label(row, label,
                    UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
                    Theme.Text, 12, true)
                lbl.TextXAlignment = Enum.TextXAlignment.Center

                local btn3 = Instance.new("TextButton")
                btn3.Size              = UDim2.new(1,0,1,0)
                btn3.BackgroundTransparency = 1
                btn3.Text              = ""
                btn3.Parent            = row
                btn3.MouseButton1Click:Connect(function()
                    Tween(row, {BackgroundColor3 = Theme.AccentDark}, 0.08)
                    task.delay(0.08, function()
                        Tween(row, {BackgroundColor3 = Theme.Accent}, 0.12)
                    end)
                    callback()
                end)
                btn3.MouseEnter:Connect(function()
                    Tween(row, {BackgroundColor3 = Theme.AccentDark}, 0.1)
                end)
                btn3.MouseLeave:Connect(function()
                    Tween(row, {BackgroundColor3 = Theme.Accent}, 0.1)
                end)
            end

            -- ── Textbox ────────────────────────────────────
            function Section:AddTextbox(opts2)
                opts2 = opts2 or {}
                local label    = opts2.Label       or "Input"
                local placeholder = opts2.Placeholder or "Type here..."
                local default  = opts2.Default     or ""
                local callback = opts2.Callback    or function() end

                local row = RoundFrame(page,
                    UDim2.new(1,0,0,36),
                    UDim2.new(0,0,0,0),
                    Theme.Panel, 6, "TB_"..label)
                row.LayoutOrder = sectionOrder + 0.5

                Label(row, label,
                    UDim2.new(0.38,0,1,0), UDim2.new(0,10,0,0),
                    Theme.Text, 12)

                local inputBG = RoundFrame(row,
                    UDim2.new(0.55,0,0,22),
                    UDim2.new(0.42,0,0.5,-11),
                    Theme.Background, 4, "InputBG")

                local tb = Instance.new("TextBox")
                tb.Size              = UDim2.new(1,-8,1,0)
                tb.Position          = UDim2.new(0,4,0,0)
                tb.BackgroundTransparency = 1
                tb.Text              = default
                tb.PlaceholderText   = placeholder
                tb.PlaceholderColor3 = Theme.TextDim
                tb.TextColor3        = Theme.Text
                tb.Font              = Enum.Font.Gotham
                tb.TextSize          = 12
                tb.ClearTextOnFocus  = false
                tb.TextXAlignment    = Enum.TextXAlignment.Left
                tb.Parent            = inputBG

                tb.Focused:Connect(function()
                    Tween(inputBG, {BackgroundColor3 = Theme.Panel}, 0.1)
                end)
                tb.FocusLost:Connect(function(enter)
                    Tween(inputBG, {BackgroundColor3 = Theme.Background}, 0.1)
                    callback(tb.Text, enter)
                end)
            end

            return Section
        end -- AddSection

        return Tab
    end -- AddTab

    return Window
end -- CreateWindow

-- ════════════════════════════════════════════════════════════
--  ARRAYLIST  (module list overlay, top-right)
-- ════════════════════════════════════════════════════════════
function RockstarUI:CreateArrayList(screenGui)
    local holder = Instance.new("Frame")
    holder.Name               = "ArrayList"
    holder.Size               = UDim2.new(0, 160, 1, 0)
    holder.Position           = UDim2.new(1,-164,0,8)
    holder.BackgroundTransparency = 1
    holder.Parent             = screenGui

    local layout = Instance.new("UIListLayout", holder)
    layout.SortOrder         = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Padding           = UDim.new(0,2)

    local ArrayList = {_holder = holder, _items = {}}

    function ArrayList:Add(name, color)
        color = color or Theme.Accent
        local lbl = Instance.new("TextLabel")
        lbl.Name              = name
        lbl.Size              = UDim2.new(0,0,0,16)
        lbl.AutomaticSize     = Enum.AutomaticSize.X
        lbl.BackgroundTransparency = 1
        lbl.Text              = name.." "
        lbl.TextColor3        = color
        lbl.Font              = Enum.Font.GothamBold
        lbl.TextSize          = 12
        lbl.TextXAlignment    = Enum.TextXAlignment.Right
        lbl.Parent            = holder

        -- right accent bar
        local bar = Instance.new("Frame")
        bar.Size             = UDim2.new(0,2,1,0)
        bar.Position         = UDim2.new(1,0,0,0)
        bar.BackgroundColor3 = color
        bar.BorderSizePixel  = 0
        bar.Parent           = lbl

        table.insert(self._items, {name=name, lbl=lbl})
        -- slide in
        lbl.TextTransparency = 1
        Tween(lbl, {TextTransparency = 0}, 0.2)
    end

    function ArrayList:Remove(name)
        for i, v in ipairs(self._items) do
            if v.name == name then
                Tween(v.lbl, {TextTransparency=1}, 0.15)
                task.wait(0.16) v.lbl:Destroy()
                table.remove(self._items, i)
                break
            end
        end
    end

    return ArrayList
end

-- ════════════════════════════════════════════════════════════
--  WATERMARK
-- ════════════════════════════════════════════════════════════
function RockstarUI:CreateWatermark(screenGui, clientName, ver)
    local wm = RoundFrame(screenGui,
        UDim2.new(0,160,0,26),
        UDim2.new(0,8,0,8),
        Theme.Panel, 6, "Watermark")

    local accent = Instance.new("Frame")
    accent.Size             = UDim2.new(0,3,1,0)
    accent.BackgroundColor3 = Theme.Accent
    accent.BorderSizePixel  = 0
    accent.Parent           = wm
    Instance.new("UICorner",accent).CornerRadius = UDim.new(0,2)

    Label(wm, clientName or "Rockstar",
        UDim2.new(0.6,0,1,0), UDim2.new(0,10,0,0),
        Theme.Text, 13, true)
    Label(wm, ver or "v2.0",
        UDim2.new(0.35,0,1,0), UDim2.new(1,-40,0,0),
        Theme.Accent, 11, false)

    -- fps counter
    local fpsLabel = Label(wm, "0 fps",
        UDim2.new(0.35,0,1,0), UDim2.new(1,-90,0,0),
        Theme.TextDim, 11)

    local lastTime = tick()
    local frameCount = 0
    RunService.RenderStepped:Connect(function()
        frameCount += 1
        if tick() - lastTime >= 1 then
            fpsLabel.Text = frameCount.." fps"
            frameCount = 0
            lastTime = tick()
        end
    end)
end

-- ════════════════════════════════════════════════════════════
return RockstarUI
