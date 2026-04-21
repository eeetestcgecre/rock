-- ╔══════════════════════════════════════════════════════╗
-- ║              ModernLib  v1.0                         ║
-- ║  Linoria-compatible API · Modern visual skin         ║
-- ║  Works on Solara / Medium                            ║
-- ╚══════════════════════════════════════════════════════╝
--
-- USAGE (same as Linoria):
--   local Lib     = loadstring(game:HttpGet("<raw url>"))()
--   local Window  = Lib:CreateWindow({ Title = "My Script", SubTitle = "v1" })
--   local Tab     = Window:AddTab("Main")
--   local LGrp    = Tab:AddLeftGroupbox("Settings")
--   LGrp:AddToggle("myToggle", { Text = "ESP", Default = false, Callback = function(v) end })
--   LGrp:AddSlider("mySlider", { Text = "Speed", Min = 0, Max = 100, Default = 50, Callback = function(v) end })
--   LGrp:AddButton({ Text = "Teleport", Func = function() end })
--   LGrp:AddDropdown("myDrop", { Values = {"Option A","Option B"}, Default = 1, Callback = function(v) end })
--   LGrp:AddKeybind("myKey", { Text = "Toggle UI", Default = Enum.KeyCode.RightShift })
--   Lib.Flags.myToggle.Value  -- access current value anywhere
--   Lib.Flags.myToggle:Set(true)  -- set value anywhere

local ModernLib   = {}
ModernLib.__index = ModernLib
ModernLib.Flags   = {}

-- ─────────────────────────────────────────────────────────
-- Services
-- ─────────────────────────────────────────────────────────
local UIS         = game:GetService("UserInputService")
local TweenSvc    = game:GetService("TweenService")
local Players     = game:GetService("Players")

-- ─────────────────────────────────────────────────────────
-- Theme  (from your config)
-- ─────────────────────────────────────────────────────────
local T = {
    Background  = Color3.fromHex("141414"),
    Main        = Color3.fromHex("1c1c1c"),
    Accent      = Color3.fromHex("bb9cb8"),
    Outline     = Color3.fromHex("323232"),
    Text        = Color3.fromHex("ffffff"),
    SubText     = Color3.fromHex("999999"),
    Danger      = Color3.fromHex("e06c75"),

    Font        = Enum.Font.GothamBold,
    FontSm      = Enum.Font.Gotham,

    R8          = UDim.new(0, 8),   -- main panels
    R5          = UDim.new(0, 5),   -- buttons / dropdowns
    R4          = UDim.new(0, 4),   -- small chips
    RFull       = UDim.new(1, 0),   -- pills

    ShadowImg   = "rbxassetid://6015897843",
    ShadowSlice = Rect.new(49, 49, 450, 450),
}

-- ─────────────────────────────────────────────────────────
-- Utility helpers
-- ─────────────────────────────────────────────────────────
local function Tween(obj, t, props)
    TweenSvc:Create(obj,
        TweenInfo.new(t or 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        props
    ):Play()
end

local function New(cls, props, children)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" and k ~= "Children" then
            o[k] = v
        end
    end
    for _, c in pairs(children or {}) do c.Parent = o end
    if props and props.Parent then o.Parent = props.Parent end
    return o
end

local function Corner(p, r)
    return New("UICorner", { CornerRadius = r or T.R8, Parent = p })
end

local function Stroke(p, col, thick, trans)
    return New("UIStroke", {
        Color        = col   or T.Outline,
        Thickness    = thick or 1,
        Transparency = trans or 0,
        Parent       = p,
    })
end

local function Pad(p, t, b, l, r)
    return New("UIPadding", {
        PaddingTop    = UDim.new(0, t or 6),
        PaddingBottom = UDim.new(0, b or 6),
        PaddingLeft   = UDim.new(0, l or 8),
        PaddingRight  = UDim.new(0, r or 8),
        Parent        = p,
    })
end

local function ListLayout(p, dir, pad, ha, va)
    return New("UIListLayout", {
        FillDirection       = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = ha  or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = va  or Enum.VerticalAlignment.Top,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Padding             = UDim.new(0, pad or 4),
        Parent              = p,
    })
end

-- Soft drop-shadow using 9-slice image
local function Shadow(p, alpha, yOff, szExtra)
    return New("ImageLabel", {
        Name               = "_Shadow",
        AnchorPoint        = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position           = UDim2.new(0.5, 0, 0.5, yOff or 5),
        Size               = UDim2.new(1, szExtra or 28, 1, szExtra or 28),
        ZIndex             = math.max(1, (p.ZIndex or 2) - 1),
        Image              = T.ShadowImg,
        ImageColor3        = Color3.new(0, 0, 0),
        ImageTransparency  = alpha or 0.4,
        ScaleType          = Enum.ScaleType.Slice,
        SliceCenter        = T.ShadowSlice,
        Parent             = p,
    })
end

-- Accent glow halo (same 9-slice, accent color)
local function Glow(p, col, alpha)
    return New("ImageLabel", {
        Name               = "_Glow",
        AnchorPoint        = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position           = UDim2.new(0.5, 0, 0.5, 0),
        Size               = UDim2.new(1, 18, 1, 18),
        ZIndex             = math.max(1, (p.ZIndex or 2) - 1),
        Image              = T.ShadowImg,
        ImageColor3        = col   or T.Accent,
        ImageTransparency  = alpha or 0.72,
        ScaleType          = Enum.ScaleType.Slice,
        SliceCenter        = T.ShadowSlice,
        Parent             = p,
    })
end

-- Drag logic
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, startMousePos, startFramePos

    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging      = true
            startMousePos = i.Position
            startFramePos = frame.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = i
        end
    end)

    UIS.InputChanged:Connect(function(i)
        if i == dragInput and dragging then
            local d = i.Position - startMousePos
            frame.Position = UDim2.new(
                startFramePos.X.Scale, startFramePos.X.Offset + d.X,
                startFramePos.Y.Scale, startFramePos.Y.Offset + d.Y
            )
        end
    end)
end

-- ─────────────────────────────────────────────────────────
-- ScreenGui creation  (tries CoreGui first, falls back)
-- ─────────────────────────────────────────────────────────
local ScreenGui
local ok = pcall(function()
    ScreenGui = New("ScreenGui", {
        Name           = "ModernLib",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent         = game:GetService("CoreGui"),
    })
end)
if not ok then
    ScreenGui = New("ScreenGui", {
        Name           = "ModernLib",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent         = Players.LocalPlayer:WaitForChild("PlayerGui"),
    })
end

-- ─────────────────────────────────────────────────────────
-- Window
-- ─────────────────────────────────────────────────────────
function ModernLib:CreateWindow(cfg)
    cfg = cfg or {}
    local title    = cfg.Title    or "ModernLib"
    local subtitle = cfg.SubTitle or ""
    local sz       = cfg.Size     or Vector2.new(540, 440)
    local center   = cfg.Center   ~= false
    local autoShow = cfg.AutoShow ~= false

    local win = { _tabs = {}, _current = nil }

    -- ── Root ──────────────────────────────────────────────
    local Root = New("Frame", {
        Name             = "Window_" .. title,
        Size             = UDim2.fromOffset(sz.X, sz.Y),
        Position         = center
            and UDim2.new(0.5, -sz.X/2, 0.5, -sz.Y/2)
            or  UDim2.fromOffset(80, 80),
        BackgroundColor3 = T.Background,
        BorderSizePixel  = 0,
        ZIndex           = 10,
        Visible          = autoShow,
        Parent           = ScreenGui,
    })
    Corner(Root)
    Stroke(Root, T.Outline, 1)
    Shadow(Root, 0.3, 10, 40)

    -- ── Title bar ─────────────────────────────────────────
    local TBar = New("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = T.Main,
        BorderSizePixel  = 0,
        ZIndex           = 11,
        Parent           = Root,
    })
    Corner(TBar)
    -- fill bottom corners so they're square (the root already provides bottom rounding)
    New("Frame", {
        Size             = UDim2.new(1, 0, 0, 12),
        Position         = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = T.Main,
        BorderSizePixel  = 0,
        ZIndex           = 11,
        Parent           = TBar,
    })

    New("TextLabel", {
        Text           = title,
        Font           = T.Font,
        TextSize       = 14,
        TextColor3     = T.Text,
        BackgroundTransparency = 1,
        Position       = UDim2.fromOffset(14, 0),
        Size           = UDim2.new(0.6, -14, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex         = 12,
        Parent         = TBar,
    })

    if subtitle ~= "" then
        New("TextLabel", {
            Text           = subtitle,
            Font           = T.FontSm,
            TextSize       = 11,
            TextColor3     = T.SubText,
            BackgroundTransparency = 1,
            AnchorPoint    = Vector2.new(1, 0.5),
            Position       = UDim2.new(1, -14, 0.5, 0),
            Size           = UDim2.new(0.4, -14, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex         = 12,
            Parent         = TBar,
        })
    end

    -- Accent stripe under title bar
    local AccentLine = New("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 12,
        Parent           = TBar,
    })
    Glow(AccentLine, T.Accent, 0.6)

    MakeDraggable(Root, TBar)

    -- ── Tab strip ─────────────────────────────────────────
    local TabStrip = New("Frame", {
        Name             = "TabStrip",
        Size             = UDim2.new(1, 0, 0, 34),
        Position         = UDim2.new(0, 0, 0, 44),
        BackgroundColor3 = T.Main,
        BorderSizePixel  = 0,
        ZIndex           = 11,
        Parent           = Root,
    })
    -- fill bottom corners
    New("Frame", {
        Size             = UDim2.new(1, 0, 0, 10),
        Position         = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = T.Main,
        BorderSizePixel  = 0,
        ZIndex           = 11,
        Parent           = TabStrip,
    })
    ListLayout(TabStrip, Enum.FillDirection.Horizontal, 3,
        Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    Pad(TabStrip, 0, 0, 10, 10)

    -- thin separator
    New("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 0, 78),
        BackgroundColor3 = T.Outline,
        BorderSizePixel  = 0,
        ZIndex           = 11,
        Parent           = Root,
    })

    -- ── Content area ──────────────────────────────────────
    local ContentArea = New("Frame", {
        Name             = "Content",
        Size             = UDim2.new(1, 0, 1, -80),
        Position         = UDim2.new(0, 0, 0, 80),
        BackgroundTransparency = 1,
        ZIndex           = 11,
        Parent           = Root,
    })

    win._root    = Root
    win._strip   = TabStrip
    win._content = ContentArea

    -- ── AddTab ────────────────────────────────────────────
    function win:AddTab(name)
        local tab = { _name = name, _groups = {} }

        -- Tab button
        local Btn = New("TextButton", {
            Name             = "Tab_" .. name,
            Text             = name,
            Font             = T.FontSm,
            TextSize         = 12,
            TextColor3       = T.SubText,
            BackgroundColor3 = T.Background,
            BackgroundTransparency = 1,
            AutomaticSize    = Enum.AutomaticSize.X,
            Size             = UDim2.fromOffset(0, 26),
            ZIndex           = 12,
            Parent           = TabStrip,
        })
        Corner(Btn, T.R4)
        Pad(Btn, 4, 4, 10, 10)

        -- Active underline
        local Underline = New("Frame", {
            Name             = "Underline",
            AnchorPoint      = Vector2.new(0.5, 1),
            Position         = UDim2.new(0.5, 0, 1, 1),
            Size             = UDim2.new(0.7, 0, 0, 2),
            BackgroundColor3 = T.Accent,
            BorderSizePixel  = 0,
            ZIndex           = 13,
            Visible          = false,
            Parent           = Btn,
        })
        Corner(Underline, UDim.new(1, 0))
        Glow(Underline, T.Accent, 0.55)

        -- Tab body
        local Body = New("Frame", {
            Name             = name .. "_Body",
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible          = false,
            ZIndex           = 11,
            Parent           = ContentArea,
        })

        -- Two scrolling columns
        local function makeCol(anchor, pos)
            local sc = New("ScrollingFrame", {
                AnchorPoint          = Vector2.new(anchor, 0),
                Position             = pos,
                Size                 = UDim2.new(0.5, -7, 1, -8),
                BackgroundTransparency = 1,
                ScrollBarThickness   = 2,
                ScrollBarImageColor3 = T.Accent,
                BorderSizePixel      = 0,
                CanvasSize           = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize  = Enum.AutomaticSize.Y,
                ZIndex               = 11,
                Parent               = Body,
            })
            ListLayout(sc, Enum.FillDirection.Vertical, 6)
            Pad(sc, 4, 4, 0, 0)
            return sc
        end

        tab._left  = makeCol(0, UDim2.new(0, 6, 0, 4))
        tab._right = makeCol(0, UDim2.new(0.5, 2, 0, 4))
        tab._body  = Body
        tab._btn   = Btn
        tab._line  = Underline

        local function switchTo()
            for _, t in ipairs(win._tabs) do
                t._body.Visible = false
                Tween(t._btn, 0.12, { TextColor3 = T.SubText, BackgroundTransparency = 1 })
                t._line.Visible = false
            end
            Body.Visible    = true
            Underline.Visible = true
            Tween(Btn, 0.12, { TextColor3 = T.Text, BackgroundTransparency = 0 })
            win._current = tab
        end

        Btn.MouseButton1Click:Connect(switchTo)
        table.insert(win._tabs, tab)
        if #win._tabs == 1 then switchTo() end

        -- ── Groupbox factory ────────────────────────────
        local function makeGroupbox(gbName, col)
            local gb = {}

            local GBRoot = New("Frame", {
                Name             = gbName,
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundColor3 = T.Main,
                BorderSizePixel  = 0,
                ZIndex           = 12,
                Parent           = col,
            })
            Corner(GBRoot)
            Stroke(GBRoot, T.Outline, 1)
            Shadow(GBRoot, 0.5, 4, 20)

            -- Group label
            local GBLabel = New("TextLabel", {
                Text           = gbName,
                Font           = T.Font,
                TextSize       = 11,
                TextColor3     = T.Accent,
                BackgroundTransparency = 1,
                Size           = UDim2.new(1, 0, 0, 26),
                Position       = UDim2.new(0, 0, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex         = 13,
                Parent         = GBRoot,
            })
            Pad(GBLabel, 0, 0, 10, 10)

            -- Thin accent rule under group title
            New("Frame", {
                Size             = UDim2.new(1, -20, 0, 1),
                Position         = UDim2.new(0, 10, 0, 26),
                BackgroundColor3 = T.Outline,
                BorderSizePixel  = 0,
                ZIndex           = 13,
                Parent           = GBRoot,
            })

            -- Item container
            local Items = New("Frame", {
                Name          = "Items",
                BackgroundTransparency = 1,
                Size          = UDim2.new(1, 0, 0, 0),
                Position      = UDim2.new(0, 0, 0, 29),
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex        = 13,
                Parent        = GBRoot,
            })
            ListLayout(Items, Enum.FillDirection.Vertical, 2)
            Pad(Items, 4, 8, 8, 8)

            gb._root  = GBRoot
            gb._items = Items

            -- ────────────────────────────────────────────
            -- Shared row helper
            -- ────────────────────────────────────────────
            local function Row(h)
                return New("Frame", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, 0, 0, h or 28),
                    ZIndex                 = 14,
                    Parent                 = Items,
                })
            end

            local function HoverLabel(lbl)
                lbl.MouseEnter:Connect(function()
                    Tween(lbl, 0.1, { TextColor3 = T.Accent })
                end)
                lbl.MouseLeave:Connect(function()
                    Tween(lbl, 0.1, { TextColor3 = T.Text })
                end)
            end

            -- ────────────────────────────────────────────
            -- Toggle
            -- ────────────────────────────────────────────
            function gb:AddToggle(id, cfg)
                cfg = cfg or {}
                local text     = cfg.Text    or id
                local default  = cfg.Default or false
                local callback = cfg.Callback or function() end

                local state = default
                local flag  = { Value = state }
                ModernLib.Flags[id] = flag

                local R = Row(28)

                local Lbl = New("TextLabel", {
                    Text           = text,
                    Font           = T.FontSm,
                    TextSize       = 12,
                    TextColor3     = T.Text,
                    BackgroundTransparency = 1,
                    Size           = UDim2.new(1, -46, 1, 0),
                    ZIndex         = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent         = R,
                })
                HoverLabel(Lbl)

                -- Pill track
                local Track = New("Frame", {
                    AnchorPoint      = Vector2.new(1, 0.5),
                    Position         = UDim2.new(1, 0, 0.5, 0),
                    Size             = UDim2.new(0, 36, 0, 18),
                    BackgroundColor3 = state and T.Accent or T.Outline,
                    ZIndex           = 14,
                    Parent           = R,
                })
                Corner(Track, T.RFull)
                if state then Glow(Track, T.Accent, 0.65) end

                -- Knob
                local Knob = New("Frame", {
                    AnchorPoint      = Vector2.new(0, 0.5),
                    Position         = state
                        and UDim2.new(1, -16, 0.5, 0)
                        or  UDim2.new(0,  2,  0.5, 0),
                    Size             = UDim2.new(0, 14, 0, 14),
                    BackgroundColor3 = T.Text,
                    ZIndex           = 15,
                    Parent           = Track,
                })
                Corner(Knob, T.RFull)

                local function setVal(v, noCallback)
                    state = v
                    flag.Value = v
                    Tween(Track, 0.18, { BackgroundColor3 = v and T.Accent or T.Outline })
                    Tween(Knob,  0.18, {
                        Position = v
                            and UDim2.new(1, -16, 0.5, 0)
                            or  UDim2.new(0,  2,  0.5, 0)
                    })
                    local g = Track:FindFirstChild("_Glow")
                    if v and not g then
                        Glow(Track, T.Accent, 0.65)
                    elseif not v and g then
                        g:Destroy()
                    end
                    if not noCallback then callback(v) end
                end

                flag.Set = setVal

                R.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        setVal(not state)
                    end
                end)

                return flag
            end

            -- ────────────────────────────────────────────
            -- Slider
            -- ────────────────────────────────────────────
            function gb:AddSlider(id, cfg)
                cfg = cfg or {}
                local text     = cfg.Text     or id
                local min      = cfg.Min      or 0
                local max      = cfg.Max      or 100
                local default  = cfg.Default  or min
                local rounding = cfg.Rounding or 1
                local suffix   = cfg.Suffix   or ""
                local callback = cfg.Callback or function() end

                local value = math.clamp(default, min, max)
                local flag  = { Value = value }
                ModernLib.Flags[id] = flag

                local R = Row(40)

                -- Label row
                local TopRow = New("Frame", {
                    BackgroundTransparency = 1,
                    Size   = UDim2.new(1, 0, 0, 16),
                    ZIndex = 14,
                    Parent = R,
                })
                New("TextLabel", {
                    Text           = text,
                    Font           = T.FontSm,
                    TextSize       = 12,
                    TextColor3     = T.Text,
                    BackgroundTransparency = 1,
                    Size           = UDim2.new(0.65, 0, 1, 0),
                    ZIndex         = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent         = TopRow,
                })
                local ValLbl = New("TextLabel", {
                    Text           = tostring(value) .. suffix,
                    Font           = T.Font,
                    TextSize       = 11,
                    TextColor3     = T.Accent,
                    BackgroundTransparency = 1,
                    AnchorPoint    = Vector2.new(1, 0),
                    Position       = UDim2.new(1, 0, 0, 0),
                    Size           = UDim2.new(0.35, 0, 1, 0),
                    ZIndex         = 14,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent         = TopRow,
                })

                -- Track background
                local TrackBg = New("Frame", {
                    Position         = UDim2.new(0, 0, 0, 22),
                    Size             = UDim2.new(1, 0, 0, 8),
                    BackgroundColor3 = T.Outline,
                    ZIndex           = 14,
                    Parent           = R,
                })
                Corner(TrackBg, T.RFull)

                local function pct() return (value - min) / (max - min) end

                -- Fill
                local Fill = New("Frame", {
                    Size             = UDim2.new(pct(), 0, 1, 0),
                    BackgroundColor3 = T.Accent,
                    ZIndex           = 15,
                    Parent           = TrackBg,
                })
                Corner(Fill, T.RFull)
                Glow(Fill, T.Accent, 0.72)

                -- Knob
                local Knob = New("Frame", {
                    AnchorPoint      = Vector2.new(0.5, 0.5),
                    Position         = UDim2.new(pct(), 0, 0.5, 0),
                    Size             = UDim2.new(0, 12, 0, 12),
                    BackgroundColor3 = T.Text,
                    ZIndex           = 16,
                    Parent           = TrackBg,
                })
                Corner(Knob, T.RFull)

                local dragging = false

                local function update(x)
                    local p = math.clamp(
                        (x - TrackBg.AbsolutePosition.X) / TrackBg.AbsoluteSize.X,
                        0, 1
                    )
                    local raw  = min + (max - min) * p
                    value = math.clamp(
                        math.floor(raw / rounding + 0.5) * rounding,
                        min, max
                    )
                    flag.Value   = value
                    local np     = pct()
                    Fill.Size    = UDim2.new(np, 0, 1, 0)
                    Knob.Position = UDim2.new(np, 0, 0.5, 0)
                    ValLbl.Text  = tostring(value) .. suffix
                    callback(value)
                end

                TrackBg.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        update(i.Position.X)
                    end
                end)
                UIS.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                        update(i.Position.X)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                flag.Set = function(v)
                    value = math.clamp(v, min, max)
                    flag.Value = value
                    local np   = pct()
                    Fill.Size  = UDim2.new(np, 0, 1, 0)
                    Knob.Position = UDim2.new(np, 0, 0.5, 0)
                    ValLbl.Text = tostring(value) .. suffix
                    callback(value)
                end

                return flag
            end

            -- ────────────────────────────────────────────
            -- Button
            -- ────────────────────────────────────────────
            function gb:AddButton(cfg, func)
                if type(cfg) == "string" then
                    cfg = { Text = cfg, Func = func }
                end
                cfg = cfg or {}
                local text = cfg.Text or "Button"
                local fn   = cfg.Func or function() end

                local Btn = New("TextButton", {
                    Text             = text,
                    Font             = T.FontSm,
                    TextSize         = 12,
                    TextColor3       = T.Text,
                    BackgroundColor3 = T.Background,
                    Size             = UDim2.new(1, 0, 0, 28),
                    ZIndex           = 14,
                    Parent           = Items,
                })
                Corner(Btn, T.R5)
                Stroke(Btn, T.Outline, 1)

                Btn.MouseEnter:Connect(function()
                    Tween(Btn, 0.1, { BackgroundColor3 = T.Main })
                end)
                Btn.MouseLeave:Connect(function()
                    Tween(Btn, 0.1, { BackgroundColor3 = T.Background })
                end)
                Btn.MouseButton1Down:Connect(function()
                    Tween(Btn, 0.07, { BackgroundColor3 = T.Accent, TextColor3 = T.Background })
                end)
                Btn.MouseButton1Up:Connect(function()
                    Tween(Btn, 0.12, { BackgroundColor3 = T.Background, TextColor3 = T.Text })
                    task.spawn(fn)
                end)

                return Btn
            end

            -- ────────────────────────────────────────────
            -- Label / Paragraph
            -- ────────────────────────────────────────────
            function gb:AddLabel(text, wrap)
                local lbl = New("TextLabel", {
                    Text             = text or "",
                    Font             = T.FontSm,
                    TextSize         = 12,
                    TextColor3       = T.SubText,
                    BackgroundTransparency = 1,
                    Size             = UDim2.new(1, 0, 0, 0),
                    AutomaticSize    = Enum.AutomaticSize.Y,
                    TextWrapped      = wrap ~= false,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    ZIndex           = 14,
                    Parent           = Items,
                })
                Pad(lbl, 2, 2, 0, 0)
                return lbl
            end

            -- ────────────────────────────────────────────
            -- Dropdown
            -- ────────────────────────────────────────────
            function gb:AddDropdown(id, cfg)
                cfg = cfg or {}
                local text     = cfg.Text     or id
                local values   = cfg.Values   or {}
                local default  = cfg.Default  or 1
                local multi    = cfg.Multi    or false
                local callback = cfg.Callback or function() end

                local selected = multi and {} or values[default]
                local flag     = { Value = selected }
                ModernLib.Flags[id] = flag

                -- Wrapper grows when open
                local Wrap = New("Frame", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, 0, 0, 28),
                    ZIndex                 = 14,
                    ClipsDescendants       = false,
                    Parent                 = Items,
                })

                local DDBtn = New("TextButton", {
                    Text             = "",
                    BackgroundColor3 = T.Background,
                    Size             = UDim2.new(1, 0, 0, 28),
                    ZIndex           = 14,
                    Parent           = Wrap,
                })
                Corner(DDBtn, T.R5)
                Stroke(DDBtn, T.Outline, 1)

                New("TextLabel", {
                    Text           = text,
                    Font           = T.FontSm,
                    TextSize       = 12,
                    TextColor3     = T.SubText,
                    BackgroundTransparency = 1,
                    Position       = UDim2.fromOffset(10, 0),
                    Size           = UDim2.new(0.48, 0, 1, 0),
                    ZIndex         = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent         = DDBtn,
                })

                local ValLbl = New("TextLabel", {
                    Text           = multi and "None" or (values[default] or "Select"),
                    Font           = T.Font,
                    TextSize       = 11,
                    TextColor3     = T.Text,
                    BackgroundTransparency = 1,
                    Position       = UDim2.new(0.48, 0, 0, 0),
                    Size           = UDim2.new(0.43, 0, 1, 0),
                    ZIndex         = 15,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent         = DDBtn,
                })

                New("TextLabel", {
                    Text           = "▾",
                    Font           = T.Font,
                    TextSize       = 13,
                    TextColor3     = T.Accent,
                    BackgroundTransparency = 1,
                    AnchorPoint    = Vector2.new(1, 0.5),
                    Position       = UDim2.new(1, -8, 0.5, 0),
                    Size           = UDim2.fromOffset(16, 16),
                    ZIndex         = 15,
                    Parent         = DDBtn,
                })

                -- Dropdown list panel
                local isOpen   = false
                local itemH    = 26
                local totalH   = #values * (itemH + 2) + 8

                local DDList = New("Frame", {
                    BackgroundColor3 = T.Main,
                    Position         = UDim2.new(0, 0, 1, 4),
                    Size             = UDim2.new(1, 0, 0, 0),
                    ZIndex           = 20,
                    ClipsDescendants = true,
                    Parent           = Wrap,
                })
                Corner(DDList, T.R5)
                Stroke(DDList, T.Outline)
                Shadow(DDList, 0.45, 5, 16)
                ListLayout(DDList, Enum.FillDirection.Vertical, 2)
                Pad(DDList, 4, 4, 4, 4)

                for _, v in ipairs(values) do
                    local Opt = New("TextButton", {
                        Text             = v,
                        Font             = T.FontSm,
                        TextSize         = 12,
                        TextColor3       = T.Text,
                        BackgroundColor3 = T.Outline,
                        BackgroundTransparency = 1,
                        Size             = UDim2.new(1, 0, 0, itemH),
                        ZIndex           = 21,
                        TextXAlignment   = Enum.TextXAlignment.Left,
                        Parent           = DDList,
                    })
                    Corner(Opt, T.R4)
                    Pad(Opt, 0, 0, 8, 8)

                    Opt.MouseEnter:Connect(function()
                        Tween(Opt, 0.08, { BackgroundTransparency = 0 })
                    end)
                    Opt.MouseLeave:Connect(function()
                        Tween(Opt, 0.08, { BackgroundTransparency = 1 })
                    end)
                    Opt.MouseButton1Click:Connect(function()
                        if multi then
                            selected[v] = not selected[v]
                            local sel = {}
                            for k, on in pairs(selected) do
                                if on then table.insert(sel, k) end
                            end
                            ValLbl.Text = #sel > 0 and table.concat(sel, ", ") or "None"
                            flag.Value  = selected
                            callback(selected)
                        else
                            selected      = v
                            flag.Value    = v
                            ValLbl.Text   = v
                            callback(v)
                            isOpen = false
                            Tween(DDList, 0.14, { Size = UDim2.new(1, 0, 0, 0) })
                            Wrap.Size = UDim2.new(1, 0, 0, 28)
                        end
                    end)
                end

                DDBtn.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        local cap = math.min(totalH, 160)
                        Tween(DDList, 0.18, { Size = UDim2.new(1, 0, 0, cap) })
                        Wrap.Size = UDim2.new(1, 0, 0, 28 + cap + 4)
                    else
                        Tween(DDList, 0.14, { Size = UDim2.new(1, 0, 0, 0) })
                        Wrap.Size = UDim2.new(1, 0, 0, 28)
                    end
                end)

                flag.Set = function(v)
                    selected   = v
                    flag.Value = v
                    ValLbl.Text = type(v) == "string" and v or "Custom"
                    callback(v)
                end

                return flag
            end

            -- ────────────────────────────────────────────
            -- ColorPicker  (compact swatch → opens picker)
            -- ────────────────────────────────────────────
            function gb:AddColorpicker(id, cfg)
                cfg = cfg or {}
                local text     = cfg.Text    or id
                local default  = cfg.Default or Color3.fromRGB(255,255,255)
                local callback = cfg.Callback or function() end

                local color = default
                local flag  = { Value = color }
                ModernLib.Flags[id] = flag

                local R = Row(28)
                New("TextLabel", {
                    Text           = text,
                    Font           = T.FontSm,
                    TextSize       = 12,
                    TextColor3     = T.Text,
                    BackgroundTransparency = 1,
                    Size           = UDim2.new(1, -36, 1, 0),
                    ZIndex         = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent         = R,
                })

                local Swatch = New("TextButton", {
                    Text             = "",
                    BackgroundColor3 = color,
                    AnchorPoint      = Vector2.new(1, 0.5),
                    Position         = UDim2.new(1, 0, 0.5, 0),
                    Size             = UDim2.fromOffset(28, 18),
                    ZIndex           = 14,
                    Parent           = R,
                })
                Corner(Swatch, T.R4)
                Stroke(Swatch, T.Outline)

                -- Minimal HSV picker popup
                local pickerOpen = false
                local PickerFrame = New("Frame", {
                    BackgroundColor3 = T.Main,
                    Position         = UDim2.new(0, 0, 1, 4),
                    Size             = UDim2.new(1, 0, 0, 0),
                    ZIndex           = 22,
                    ClipsDescendants = true,
                    Parent           = R,
                })
                Corner(PickerFrame, T.R5)
                Stroke(PickerFrame, T.Outline)
                Shadow(PickerFrame, 0.45, 4)

                -- R/G/B sliders inside picker
                local function makeRGBSlider(label, yOff, getVal, setVal)
                    local SlRow = New("Frame", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, yOff),
                        Size     = UDim2.new(1, 0, 0, 22),
                        ZIndex   = 23,
                        Parent   = PickerFrame,
                    })
                    New("TextLabel", {
                        Text           = label,
                        Font           = T.FontSm,
                        TextSize       = 10,
                        TextColor3     = T.SubText,
                        BackgroundTransparency = 1,
                        Size           = UDim2.fromOffset(12, 22),
                        ZIndex         = 23,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent         = SlRow,
                    })
                    local SlBg = New("Frame", {
                        BackgroundColor3 = T.Outline,
                        Position         = UDim2.fromOffset(18, 7),
                        Size             = UDim2.new(1, -28, 0, 8),
                        ZIndex           = 23,
                        Parent           = SlRow,
                    })
                    Corner(SlBg, T.RFull)
                    local SlFill = New("Frame", {
                        BackgroundColor3 = T.Accent,
                        Size             = UDim2.new(getVal() / 255, 0, 1, 0),
                        ZIndex           = 24,
                        Parent           = SlBg,
                    })
                    Corner(SlFill, T.RFull)
                    local dragging = false
                    SlBg.InputBegan:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = true
                        end
                    end)
                    UIS.InputChanged:Connect(function(i)
                        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                            local p = math.clamp(
                                (i.Position.X - SlBg.AbsolutePosition.X) / SlBg.AbsoluteSize.X,
                                0, 1
                            )
                            setVal(math.floor(p * 255))
                            SlFill.Size = UDim2.new(p, 0, 1, 0)
                            Swatch.BackgroundColor3 = color
                            flag.Value = color
                            callback(color)
                        end
                    end)
                    UIS.InputEnded:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = false
                        end
                    end)
                end

                local r8, g8, b8 = math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255)
                makeRGBSlider("R", 6,
                    function() return r8 end,
                    function(v) r8 = v; color = Color3.fromRGB(r8, g8, b8) end)
                makeRGBSlider("G", 30,
                    function() return g8 end,
                    function(v) g8 = v; color = Color3.fromRGB(r8, g8, b8) end)
                makeRGBSlider("B", 54,
                    function() return b8 end,
                    function(v) b8 = v; color = Color3.fromRGB(r8, g8, b8) end)

                Swatch.MouseButton1Click:Connect(function()
                    pickerOpen = not pickerOpen
                    Tween(PickerFrame, 0.18, {
                        Size = pickerOpen
                            and UDim2.new(1, 0, 0, 84)
                            or  UDim2.new(1, 0, 0, 0)
                    })
                end)

                flag.Set = function(v)
                    color = v; flag.Value = v
                    Swatch.BackgroundColor3 = v
                    callback(v)
                end

                return flag
            end

            -- ────────────────────────────────────────────
            -- Keybind
            -- ────────────────────────────────────────────
            function gb:AddKeybind(id, cfg)
                cfg = cfg or {}
                local text     = cfg.Text     or id
                local default  = cfg.Default  or Enum.KeyCode.Unknown
                local callback = cfg.Callback or function() end

                local key       = default
                local listening = false
                local flag      = { Value = key }
                ModernLib.Flags[id] = flag

                local R = Row(28)
                New("TextLabel", {
                    Text           = text,
                    Font           = T.FontSm,
                    TextSize       = 12,
                    TextColor3     = T.Text,
                    BackgroundTransparency = 1,
                    Size           = UDim2.new(1, -80, 1, 0),
                    ZIndex         = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent         = R,
                })

                local KBtn = New("TextButton", {
                    Text             = key == Enum.KeyCode.Unknown and "None" or key.Name,
                    Font             = T.Font,
                    TextSize         = 10,
                    TextColor3       = T.Text,
                    BackgroundColor3 = T.Background,
                    AnchorPoint      = Vector2.new(1, 0.5),
                    Position         = UDim2.new(1, 0, 0.5, 0),
                    Size             = UDim2.fromOffset(74, 22),
                    ZIndex           = 14,
                    Parent           = R,
                })
                Corner(KBtn, T.R4)
                Stroke(KBtn, T.Outline)

                KBtn.MouseButton1Click:Connect(function()
                    listening = true
                    KBtn.Text = "[ ... ]"
                    Tween(KBtn, 0.1, { BackgroundColor3 = T.Accent, TextColor3 = T.Background })
                end)

                UIS.InputBegan:Connect(function(i, gpe)
                    if listening and not gpe then
                        listening = false
                        if i.UserInputType == Enum.UserInputType.Keyboard then
                            key = i.KeyCode
                            flag.Value = key
                            KBtn.Text  = key.Name
                        end
                        Tween(KBtn, 0.1, { BackgroundColor3 = T.Background, TextColor3 = T.Text })
                    elseif not listening
                        and i.UserInputType == Enum.UserInputType.Keyboard
                        and i.KeyCode == key
                        and key ~= Enum.KeyCode.Unknown then
                        task.spawn(callback, key)
                    end
                end)

                flag.Set = function(v)
                    key = v; flag.Value = v
                    KBtn.Text = v == Enum.KeyCode.Unknown and "None" or v.Name
                end

                return flag
            end

            -- ────────────────────────────────────────────
            -- Divider
            -- ────────────────────────────────────────────
            function gb:AddDivider()
                New("Frame", {
                    BackgroundColor3 = T.Outline,
                    Size             = UDim2.new(1, 0, 0, 1),
                    ZIndex           = 14,
                    Parent           = Items,
                })
            end

            return gb
        end -- makeGroupbox

        function tab:AddLeftGroupbox(name)
            return makeGroupbox(name, tab._left)
        end

        function tab:AddRightGroupbox(name)
            return makeGroupbox(name, tab._right)
        end

        -- Full-width (single column use) — just uses left
        function tab:AddGroupbox(name)
            return makeGroupbox(name, tab._left)
        end

        return tab
    end -- AddTab

    -- ── Window controls ───────────────────────────────────
    function win:Toggle()
        Root.Visible = not Root.Visible
    end

    function win:Show()
        Root.Visible = true
    end

    function win:Hide()
        Root.Visible = false
    end

    function win:SetTitle(t)
        local lbl = Root:FindFirstChild("TitleBar")
        if lbl then
            local tl = lbl:FindFirstChild("Title")
            if tl then tl.Text = t end
        end
    end

    function win:Destroy()
        ScreenGui:Destroy()
    end

    return win
end

-- ─────────────────────────────────────────────────────────
-- Helper: get flag value anywhere
-- ─────────────────────────────────────────────────────────
function ModernLib:GetFlag(id)
    return ModernLib.Flags[id] and ModernLib.Flags[id].Value
end

function ModernLib:SetFlag(id, v)
    if ModernLib.Flags[id] and ModernLib.Flags[id].Set then
        ModernLib.Flags[id]:Set(v)
    end
end

return ModernLib
