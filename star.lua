--[[
	HALO UI LIBRARY
	High-contrast black/white Roblox executor UI
	Optimized, modular, clean
--]]

local Halo = {}
Halo.__index = Halo

-- // Services
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- // Theme
local C = {
	Bg         = Color3.fromRGB(10,  10,  10),
	Surface    = Color3.fromRGB(20,  20,  20),
	SurfaceAlt = Color3.fromRGB(28,  28,  28),
	Border     = Color3.fromRGB(45,  45,  45),
	Text       = Color3.fromRGB(255, 255, 255),
	TextDim    = Color3.fromRGB(140, 140, 140),
	Accent     = Color3.fromRGB(255, 255, 255),
	ToggleOn   = Color3.fromRGB(255, 255, 255),
	ToggleOff  = Color3.fromRGB(40,  40,  40),
}

-- // Tween helpers
local TI_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_MED  = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function Tween(obj, props, info)
	TweenService:Create(obj, info or TI_FAST, props):Play()
end

-- // Instance factory
local function New(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local function Corner(r, parent)
	return New("UICorner", { CornerRadius = UDim.new(0, r) }, parent)
end

local function Stroke(color, thick, parent)
	return New("UIStroke", { Color = color, Thickness = thick, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
end

local function ListLayout(dir, halign, valign, pad, parent)
	return New("UIListLayout", {
		FillDirection       = dir or Enum.FillDirection.Vertical,
		HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
		VerticalAlignment   = valign or Enum.VerticalAlignment.Top,
		Padding             = UDim.new(0, pad or 0),
		SortOrder           = Enum.SortOrder.LayoutOrder,
	}, parent)
end

-- // Icon lookup (Lucide + FontAwesome asset IDs)
Halo.Icons = {
	-- Lucide
	["lucide-home"]        = "rbxassetid://10723407389",
	["lucide-settings"]    = "rbxassetid://10734950309",
	["lucide-sword"]       = "rbxassetid://10734975486",
	["lucide-swords"]      = "rbxassetid://10734975692",
	["lucide-target"]      = "rbxassetid://10734977012",
	["lucide-crosshair"]   = "rbxassetid://10709818534",
	["lucide-activity"]    = "rbxassetid://10709752035",
	["lucide-shield"]      = "rbxassetid://10734951847",
	["lucide-user"]        = "rbxassetid://10747373176",
	["lucide-folder"]      = "rbxassetid://10723387563",
	["lucide-zap"]         = "rbxassetid://10723345749",
	["lucide-eye"]         = "rbxassetid://10723346959",
	["lucide-eye-off"]     = "rbxassetid://10723346871",
	["lucide-move"]        = "rbxassetid://10734900011",
	["lucide-mouse"]       = "rbxassetid://10734898592",
	["lucide-sliders"]     = "rbxassetid://10734963400",
	["lucide-skull"]       = "rbxassetid://10734962068",
	["lucide-alert-triangle"] = "rbxassetid://10709753149",
	["lucide-check"]       = "rbxassetid://10709790644",
	["lucide-x"]           = "rbxassetid://10747384394",
	["lucide-chevron-down"] = "rbxassetid://10709790948",
	["lucide-chevron-right"] = "rbxassetid://10709791437",
	-- FontAwesome
	["fa-crosshairs"]      = "rbxassetid://133441774847498",
	["fa-skull"]           = "rbxassetid://99276754296574",
	["fa-shield"]          = "rbxassetid://73441026473893",
	["fa-gear"]            = "rbxassetid://137945854328407",
	["fa-house"]           = "rbxassetid://86540166012974",
	["fa-user"]            = "rbxassetid://98376828270066",
	["fa-bolt"]            = "rbxassetid://89858717966393",
	["fa-eye"]             = "rbxassetid://95235861336970",
}

local function GetIcon(name)
	return Halo.Icons[name] or ""
end

-- // Flags registry (global, for config save/load)
local Flags = {}
Halo.Flags = Flags

-- ============================================================
-- CONFIG MANAGER
-- ============================================================
local ConfigMgr = {}
ConfigMgr.__index = ConfigMgr

function Halo:ConfigManager(opts)
	local self  = setmetatable({}, ConfigMgr)
	self.Dir    = (opts.Directory or "Halo") .. "/" .. (opts.Config or "Configs") .. "/"
	if not isfolder(opts.Directory or "Halo") then
		makefolder(opts.Directory or "Halo")
	end
	if not isfolder(self.Dir) then
		makefolder(self.Dir)
	end
	return self
end

function ConfigMgr:WriteConfig(opts)
	local snapshot = {}
	for flag, elem in pairs(Flags) do
		snapshot[flag] = elem.Value
	end
	writefile(self.Dir .. (opts.Name or "config") .. ".json", HttpService:JSONEncode({
		Name    = opts.Name,
		Author  = opts.Author or LocalPlayer.Name,
		Created = os.date("%Y-%m-%d %H:%M"),
		Flags   = snapshot,
	}))
end

function ConfigMgr:LoadConfig(name)
	local path = self.Dir .. name .. ".json"
	if not isfile(path) then return end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(path))
	if not ok then return end
	for flag, val in pairs(data.Flags or {}) do
		if Flags[flag] and Flags[flag].SetValue then
			Flags[flag]:SetValue(val)
		end
	end
end

function ConfigMgr:DeleteConfig(name)
	local path = self.Dir .. name .. ".json"
	if isfile(path) then delfile(path) end
end

function ConfigMgr:GetConfigs()
	local out = {}
	for _, f in ipairs(listfiles(self.Dir)) do
		table.insert(out, f:gsub(self.Dir, ""):gsub(".json", ""))
	end
	return out
end

function ConfigMgr:ReadInfo(name)
	local path = self.Dir .. name .. ".json"
	if not isfile(path) then return nil end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(path))
	return ok and { Author = data.Author, Created = data.Created } or nil
end

Halo.Directory = ""

-- ============================================================
-- WINDOW
-- ============================================================
local Window = {}
Window.__index = Window

function Halo.new(opts)
	local self       = setmetatable({}, Window)
	self.Name        = opts.Name    or "HALO"
	self.Keybind     = opts.Keybind or "RightShift"
	self.Tabs        = {}
	self.ActiveTab   = nil
	self._open       = false
	self._gui        = nil
	self:_Build()
	self:_BindKey()
	return self
end

function Window:_Build()
	-- ScreenGui
	local gui = New("ScreenGui", {
		Name             = "HaloUI",
		ResetOnSpawn     = false,
		ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset   = true,
	})
	pcall(function() gui.Parent = game:GetService("CoreGui") end)
	if not gui.Parent then gui.Parent = PlayerGui end
	self._gui = gui

	-- Panel (anchored bottom-center, slides up above taskbar)
	local panel = New("Frame", {
		Name            = "Panel",
		AnchorPoint     = Vector2.new(0.5, 1),
		Position        = UDim2.new(0.5, 0, 1, -60),
		Size            = UDim2.new(0, 600, 0, 0),
		BackgroundColor3 = C.Bg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible         = false,
		Parent          = gui,
	})
	Corner(12, panel)
	Stroke(C.Border, 1, panel)
	self._panel = panel

	-- Panel header bar
	local header = New("Frame", {
		Name            = "Header",
		Size            = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = C.Surface,
		BorderSizePixel = 0,
		Parent          = panel,
	})
	Corner(12, header)
	-- Bottom corners fill fix
	New("Frame", {
		Size            = UDim2.new(1, 0, 0, 12),
		Position        = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = C.Surface,
		BorderSizePixel = 0,
		Parent          = header,
	})

	New("TextLabel", {
		Size            = UDim2.new(1, -16, 1, 0),
		Position        = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text            = self.Name,
		TextColor3      = C.Text,
		TextSize        = 13,
		Font            = Enum.Font.MontserratBold,
		TextXAlignment  = Enum.TextXAlignment.Left,
		Parent          = header,
	})

	-- SubNav (for container tabs - second row)
	local subNav = New("Frame", {
		Name            = "SubNav",
		Size            = UDim2.new(1, 0, 0, 32),
		Position        = UDim2.new(0, 0, 0, 38),
		BackgroundColor3 = C.SurfaceAlt,
		BorderSizePixel = 0,
		Visible         = false,
		Parent          = panel,
	})
	ListLayout(Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center, 4, subNav)
	New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, subNav)
	self._subNav = subNav

	-- Content area
	local content = New("Frame", {
		Name            = "Content",
		Size            = UDim2.new(1, 0, 1, -38),
		Position        = UDim2.new(0, 0, 0, 38),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent          = panel,
	})
	self._content = content

	-- Taskbar
	local taskbar = New("Frame", {
		Name            = "Taskbar",
		AnchorPoint     = Vector2.new(0.5, 1),
		Position        = UDim2.new(0.5, 0, 1, -10),
		Size            = UDim2.new(0, 600, 0, 44),
		BackgroundColor3 = C.Bg,
		BorderSizePixel = 0,
		Parent          = gui,
	})
	Corner(14, taskbar)
	Stroke(C.Border, 1, taskbar)
	self._taskbar = taskbar

	-- Taskbar inner layout
	local tabRow = New("Frame", {
		Name            = "TabRow",
		AnchorPoint     = Vector2.new(0.5, 0.5),
		Position        = UDim2.new(0.5, 0, 0.5, 0),
		Size            = UDim2.new(1, -16, 0, 32),
		BackgroundTransparency = 1,
		Parent          = taskbar,
	})
	ListLayout(Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center, 4, tabRow)
	self._tabRow = tabRow

	-- Collapse arrow (sits between panel and taskbar)
	local arrow = New("TextButton", {
		Name            = "Arrow",
		AnchorPoint     = Vector2.new(0.5, 1),
		Position        = UDim2.new(0.5, 0, 1, -60),
		Size            = UDim2.new(0, 52, 0, 14),
		BackgroundColor3 = C.Surface,
		BorderSizePixel = 0,
		Text            = "⌃",
		TextColor3      = C.TextDim,
		TextSize        = 10,
		Font            = Enum.Font.Montserrat,
		AutoButtonColor = false,
		Parent          = gui,
	})
	Corner(6, arrow)
	self._arrow = arrow

	arrow.MouseButton1Click:Connect(function() self:Toggle() end)
end

function Window:_BindKey()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if tostring(input.KeyCode):find(self.Keybind) then
			self:Toggle()
		end
	end)
end

function Window:Toggle()
	if self._open then self:_Close() else self:_Open() end
end

function Window:_Open()
	self._open = true
	self._panel.Visible = true
	self._panel.Size = UDim2.new(0, 600, 0, 0)
	Tween(self._panel, { Size = UDim2.new(0, 600, 0, 390) }, TI_MED)
	self._arrow.Text = "⌄"
end

function Window:_Close()
	self._open = false
	Tween(self._panel, { Size = UDim2.new(0, 600, 0, 0) }, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
	task.delay(0.18, function() self._panel.Visible = false end)
	self._arrow.Text = "⌃"
end

function Window:_SelectTab(tab)
	-- Deselect all
	for _, t in ipairs(self.Tabs) do
		if t._page then t._page.Visible = false end
		Tween(t._btn, { BackgroundColor3 = C.Surface })
		if t._btnIcon then Tween(t._btnIcon, { ImageColor3 = C.TextDim }) end
	end

	self.ActiveTab = tab
	tab._page.Visible = true
	Tween(tab._btn, { BackgroundColor3 = C.SurfaceAlt })
	if tab._btnIcon then Tween(tab._btnIcon, { ImageColor3 = C.Accent }) end

	-- Container subtabs: show subnav and offset content
	if tab._isContainer then
		self._subNav.Visible = true
		self._content.Position = UDim2.new(0, 0, 0, 70)
		self._content.Size = UDim2.new(1, 0, 1, -70)
	else
		self._subNav.Visible = false
		self._content.Position = UDim2.new(0, 0, 0, 38)
		self._content.Size = UDim2.new(1, 0, 1, -38)
	end

	if not self._open then self:_Open() end
end

-- Create a taskbar icon button
function Window:_MakeTabBtn(opts)
	local btn = New("TextButton", {
		Name            = opts.Name .. "_Btn",
		Size            = UDim2.new(0, 38, 0, 32),
		BackgroundColor3 = C.Surface,
		BorderSizePixel = 0,
		Text            = "",
		AutoButtonColor = false,
		Parent          = self._tabRow,
	})
	Corner(8, btn)

	local icon = nil
	if opts.Icon and opts.Icon ~= "" then
		local id = GetIcon(opts.Icon)
		if id ~= "" then
			icon = New("ImageLabel", {
				AnchorPoint     = Vector2.new(0.5, 0.5),
				Position        = UDim2.new(0.5, 0, 0.5, 0),
				Size            = UDim2.new(0, 18, 0, 18),
				BackgroundTransparency = 1,
				Image           = id,
				ImageColor3     = C.TextDim,
				Parent          = btn,
			})
		else
			-- Fallback to text label with first letter
			New("TextLabel", {
				Size            = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text            = opts.Icon:sub(1,1):upper(),
				TextColor3      = C.TextDim,
				TextSize        = 13,
				Font            = Enum.Font.MontserratBold,
				Parent          = btn,
			})
		end
	end

	btn.MouseEnter:Connect(function()
		if self.ActiveTab ~= opts._ref then
			Tween(btn, { BackgroundColor3 = C.SurfaceAlt })
		end
	end)
	btn.MouseLeave:Connect(function()
		if self.ActiveTab ~= opts._ref then
			Tween(btn, { BackgroundColor3 = C.Surface })
		end
	end)

	return btn, icon
end

-- ============================================================
-- NORMAL TAB
-- ============================================================
local Tab = {}
Tab.__index = Tab

function Window:DrawTab(opts)
	local tab         = setmetatable({}, Tab)
	tab.Name          = opts.Name
	tab._isContainer  = false
	tab.Sections      = {}
	tab._window       = self

	-- Page
	local page = New("Frame", {
		Name            = opts.Name .. "_Page",
		Size            = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible         = false,
		Parent          = self._content,
	})
	tab._page = page

	-- Two scrolling columns
	local function MakeCol(xPos, xSize)
		local sf = New("ScrollingFrame", {
			Size            = UDim2.new(xSize, -4, 1, -10),
			Position        = UDim2.new(xPos, 2, 0, 5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = C.Border,
			CanvasSize      = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent          = page,
		})
		ListLayout(nil, nil, nil, 6, sf)
		return sf
	end
	tab._left  = MakeCol(0, 0.5)
	tab._right = MakeCol(0.5, 0.5)

	-- Taskbar button
	opts._ref = tab
	local btn, icon = self:_MakeTabBtn(opts)
	tab._btn    = btn
	tab._btnIcon = icon

	btn.MouseButton1Click:Connect(function() self:_SelectTab(tab) end)
	table.insert(self.Tabs, tab)
	return tab
end

-- ============================================================
-- CONTAINER TAB
-- ============================================================
local ContainerTab = {}
ContainerTab.__index = ContainerTab
-- also inherits DrawSection from Tab through SubTab

function Window:DrawContainerTab(opts)
	local ct         = setmetatable({}, ContainerTab)
	ct.Name          = opts.Name
	ct._isContainer  = true
	ct.SubTabs       = {}
	ct._window       = self
	ct._activeSubTab = nil

	-- Page wrapper
	local page = New("Frame", {
		Name            = opts.Name .. "_Page",
		Size            = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible         = false,
		Parent          = self._content,
	})
	ct._page = page

	-- Taskbar button
	opts._ref = ct
	local btn, icon = self:_MakeTabBtn(opts)
	ct._btn     = btn
	ct._btnIcon = icon

	btn.MouseButton1Click:Connect(function() self:_SelectTab(ct) end)
	table.insert(self.Tabs, ct)
	return ct
end

function ContainerTab:DrawTab(opts)
	local subtab         = setmetatable({}, Tab)
	subtab.Name          = opts.Name
	subtab._isContainer  = false
	subtab.Sections      = {}
	subtab._window       = self._window
	subtab._container    = self

	-- Page inside container page
	local page = New("Frame", {
		Name            = opts.Name .. "_SubPage",
		Size            = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible         = false,
		Parent          = self._page,
	})
	subtab._page = page

	local function MakeCol(xPos, xSize)
		local sf = New("ScrollingFrame", {
			Size            = UDim2.new(xSize, -4, 1, -10),
			Position        = UDim2.new(xPos, 2, 0, 5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = C.Border,
			CanvasSize      = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent          = page,
		})
		ListLayout(nil, nil, nil, 6, sf)
		return sf
	end
	subtab._left  = MakeCol(0, 0.5)
	subtab._right = MakeCol(0.5, 0.5)

	-- SubNav pill button
	local navBtn = New("TextButton", {
		Name            = opts.Name .. "_NavBtn",
		AutomaticSize   = Enum.AutomaticSize.X,
		Size            = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = C.Bg,
		BorderSizePixel = 0,
		Text            = opts.Name,
		TextColor3      = C.TextDim,
		TextSize        = 11,
		Font            = Enum.Font.MontserratBold,
		AutoButtonColor = false,
		Parent          = self._window._subNav,
	})
	Corner(6, navBtn)
	New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, navBtn)
	subtab._navBtn = navBtn

	navBtn.MouseButton1Click:Connect(function()
		self:_SelectSubTab(subtab)
	end)

	table.insert(self.SubTabs, subtab)
	if #self.SubTabs == 1 then self:_SelectSubTab(subtab) end
	return subtab
end

function ContainerTab:_SelectSubTab(subtab)
	for _, st in ipairs(self.SubTabs) do
		st._page.Visible = false
		Tween(st._navBtn, { BackgroundColor3 = C.Bg, TextColor3 = C.TextDim })
	end
	subtab._page.Visible = true
	Tween(subtab._navBtn, { BackgroundColor3 = C.SurfaceAlt, TextColor3 = C.Text })
	self._activeSubTab = subtab
end

-- ============================================================
-- SECTION (shared by Tab and ContainerTab subtabs)
-- ============================================================
local Section = {}
Section.__index = Section

local function DrawSection(tab, opts)
	local sec      = setmetatable({}, Section)
	sec.Name       = opts.Name
	sec.Elements   = {}
	sec._tab       = tab
	sec._window    = tab._window
	local col = (opts.Position == "right") and tab._right or tab._left

	local frame = New("Frame", {
		Name            = opts.Name .. "_Section",
		Size            = UDim2.new(1, 0, 0, 0),
		AutomaticSize   = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.Surface,
		BorderSizePixel = 0,
		Parent          = col,
	})
	Corner(8, frame)
	Stroke(C.Border, 1, frame)

	-- Section title
	New("TextLabel", {
		Size            = UDim2.new(1, -12, 0, 26),
		Position        = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text            = opts.Name:upper(),
		TextColor3      = C.TextDim,
		TextSize        = 10,
		Font            = Enum.Font.MontserratBold,
		TextXAlignment  = Enum.TextXAlignment.Left,
		Parent          = frame,
	})

	-- Divider
	New("Frame", {
		Size            = UDim2.new(1, -16, 0, 1),
		Position        = UDim2.new(0, 8, 0, 26),
		BackgroundColor3 = C.Border,
		BorderSizePixel = 0,
		Parent          = frame,
	})

	-- Element list
	local list = New("Frame", {
		Name            = "List",
		Size            = UDim2.new(1, 0, 0, 0),
		Position        = UDim2.new(0, 0, 0, 28),
		AutomaticSize   = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent          = frame,
	})
	ListLayout(nil, nil, nil, 0, list)
	New("UIPadding", { PaddingBottom = UDim.new(0, 6) }, list)

	sec._frame = frame
	sec._list  = list
	return sec
end

Tab.DrawSection = function(self, opts) return DrawSection(self, opts) end
-- ContainerTab subtabs are Tab instances so they inherit this too

-- ============================================================
-- ELEMENT HELPERS
-- ============================================================
local function ElemFrame(list, height, order)
	return New("Frame", {
		Name            = "Elem",
		Size            = UDim2.new(1, 0, 0, height or 32),
		BackgroundTransparency = 1,
		LayoutOrder     = order,
		Parent          = list,
	})
end

local function ElemLabel(text, parent)
	return New("TextLabel", {
		Size            = UDim2.new(1, -52, 1, 0),
		Position        = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text            = text,
		TextColor3      = C.Text,
		TextSize        = 12,
		Font            = Enum.Font.Montserrat,
		TextXAlignment  = Enum.TextXAlignment.Left,
		Parent          = parent,
	})
end

-- Link system factory
local function MakeLink(elem, section)
	local link = {}

	function link:AddKeybind(opts)
		local kb = section:AddKeybind({
			Name     = opts.Name or (elem.Name .. " Key"),
			Default  = opts.Default,
			Flag     = opts.Flag,
			Callback = opts.Callback,
			_linked  = true,
		})
		return kb
	end

	function link:AddColorPicker(opts)
		local cp = section:AddColorPicker({
			Name     = opts.Name or (elem.Name .. " Color"),
			Default  = opts.Default,
			Flag     = opts.Flag,
			Callback = opts.Callback,
			_linked  = true,
		})
		return cp
	end

	function link:AddHelper(opts)
		local f = ElemFrame(section._list, 20, #section.Elements + 1)
		New("TextLabel", {
			Size            = UDim2.new(1, -12, 1, 0),
			Position        = UDim2.new(0, 12, 0, 0),
			BackgroundTransparency = 1,
			Text            = "ℹ " .. (opts.Text or ""),
			TextColor3      = C.TextDim,
			TextSize        = 10,
			Font            = Enum.Font.Montserrat,
			TextXAlignment  = Enum.TextXAlignment.Left,
			Parent          = f,
		})
	end

	return link
end

-- ============================================================
-- TOGGLE
-- ============================================================
function Section:AddToggle(opts)
	local n    = #self.Elements + 1
	local val  = opts.Default or false
	local elem = { Name = opts.Name, Flag = opts.Flag, Value = val }

	local f = ElemFrame(self._list, 32, n)
	ElemLabel(opts.Name, f)

	local track = New("TextButton", {
		AnchorPoint     = Vector2.new(1, 0.5),
		Position        = UDim2.new(1, -10, 0.5, 0),
		Size            = UDim2.new(0, 36, 0, 18),
		BackgroundColor3 = val and C.ToggleOn or C.ToggleOff,
		BorderSizePixel = 0,
		Text            = "",
		AutoButtonColor = false,
		Parent          = f,
	})
	Corner(10, track)

	local knob = New("Frame", {
		AnchorPoint     = Vector2.new(0, 0.5),
		Position        = val and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		Size            = UDim2.new(0, 14, 0, 14),
		BackgroundColor3 = val and C.Bg or C.TextDim,
		BorderSizePixel = 0,
		Parent          = track,
	})
	Corner(10, knob)

	local function SetValue(v)
		elem.Value = v
		Tween(track, { BackgroundColor3 = v and C.ToggleOn or C.ToggleOff })
		Tween(knob,  {
			Position        = v and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			BackgroundColor3 = v and C.Bg or C.TextDim,
		})
		;(opts.Callback or function() end)(v)
	end
	elem.SetValue = SetValue

	track.MouseButton1Click:Connect(function() SetValue(not elem.Value) end)

	if opts.Flag then Flags[opts.Flag] = elem end
	elem.Link = MakeLink(elem, self)
	table.insert(self.Elements, elem)
	return elem
end

-- ============================================================
-- SLIDER
-- ============================================================
function Section:AddSlider(opts)
	local n    = #self.Elements + 1
	local min  = opts.Min or 0
	local max  = opts.Max or 100
	local rnd  = opts.Round or 0
	local val  = math.clamp(opts.Default or min, min, max)
	local elem = { Name = opts.Name, Flag = opts.Flag, Value = val }

	local f = ElemFrame(self._list, 44, n)

	New("TextLabel", {
		Size            = UDim2.new(1, -52, 0, 18),
		Position        = UDim2.new(0, 12, 0, 4),
		BackgroundTransparency = 1,
		Text            = opts.Name,
		TextColor3      = C.Text,
		TextSize        = 12,
		Font            = Enum.Font.Montserrat,
		TextXAlignment  = Enum.TextXAlignment.Left,
		Parent          = f,
	})

	local valLbl = New("TextLabel", {
		Size            = UDim2.new(0, 40, 0, 18),
		Position        = UDim2.new(1, -50, 0, 4),
		BackgroundTransparency = 1,
		Text            = tostring(val),
		TextColor3      = C.TextDim,
		TextSize        = 11,
		Font            = Enum.Font.Montserrat,
		TextXAlignment  = Enum.TextXAlignment.Right,
		Parent          = f,
	})

	local track = New("Frame", {
		Size            = UDim2.new(1, -24, 0, 4),
		Position        = UDim2.new(0, 12, 0, 30),
		BackgroundColor3 = C.Border,
		BorderSizePixel = 0,
		Parent          = f,
	})
	Corner(4, track)

	local pct = (val - min) / (max - min)
	local fill = New("Frame", {
		Size            = UDim2.new(pct, 0, 1, 0),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		Parent          = track,
	})
	Corner(4, fill)

	-- Invisible hit area
	local hit = New("TextButton", {
		Size            = UDim2.new(1, 0, 0, 14),
		Position        = UDim2.new(0, 0, 0.5, -7),
		BackgroundTransparency = 1,
		Text            = "",
		Parent          = track,
	})

	local dragging = false

	local function Calc(inputX)
		local rel = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local raw = min + (max - min) * rel
		local rounded
		if rnd == 0 then
			rounded = math.round(raw)
		else
			local m = 10 ^ rnd
			rounded = math.round(raw * m) / m
		end
		elem.Value = math.clamp(rounded, min, max)
		Tween(fill, { Size = UDim2.new(rel, 0, 1, 0) })
		valLbl.Text = tostring(elem.Value)
		;(opts.Callback or function() end)(elem.Value)
	end

	local function SetValue(v)
		v = math.clamp(v, min, max)
		elem.Value = v
		local rel = (v - min) / (max - min)
		Tween(fill, { Size = UDim2.new(rel, 0, 1, 0) })
		valLbl.Text = tostring(v)
	end
	elem.SetValue = SetValue

	hit.MouseButton1Down:Connect(function(x) dragging = true; Calc(x) end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then Calc(i.Position.X) end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)

	if opts.Flag then Flags[opts.Flag] = elem end
	elem.Link = MakeLink(elem, self)
	table.insert(self.Elements, elem)
	return elem
end

-- ============================================================
-- DROPDOWN
-- ============================================================
function Section:AddDropdown(opts)
	local n     = #self.Elements + 1
	local multi = opts.Multi or false
	local vals  = opts.Values or {}
	local elem  = { Name = opts.Name, Flag = opts.Flag, Multi = multi }
	elem.Value  = multi and (type(opts.Default) == "table" and opts.Default or {}) or (opts.Default or vals[1])

	local f = ElemFrame(self._list, 32, n)
	ElemLabel(opts.Name, f)

	local btn = New("TextButton", {
		AnchorPoint     = Vector2.new(1, 0.5),
		Position        = UDim2.new(1, -10, 0.5, 0),
		Size            = UDim2.new(0.48, 0, 0, 22),
		BackgroundColor3 = C.Bg,
		BorderSizePixel = 0,
		Text            = "",
		AutoButtonColor = false,
		ZIndex          = 5,
		Parent          = f,
	})
	Corner(6, btn)
	Stroke(C.Border, 1, btn)

	local btnTxt = New("TextLabel", {
		Size            = UDim2.new(1, -20, 1, 0),
		Position        = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		Text            = multi and (type(opts.Default) == "table" and table.concat(opts.Default, ", ") or "None") or tostring(opts.Default or vals[1] or ""),
		TextColor3      = C.Text,
		TextSize        = 11,
		Font            = Enum.Font.Montserrat,
		TextXAlignment  = Enum.TextXAlignment.Left,
		TextTruncate    = Enum.TextTruncate.AtEnd,
		ZIndex          = 5,
		Parent          = btn,
	})

	-- Chevron
	New("ImageLabel", {
		AnchorPoint     = Vector2.new(1, 0.5),
		Position        = UDim2.new(1, -4, 0.5, 0),
		Size            = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1,
		Image           = GetIcon("lucide-chevron-down"),
		ImageColor3     = C.TextDim,
		ZIndex          = 5,
		Parent          = btn,
	})

	-- Dropdown list
	local list = New("Frame", {
		AnchorPoint     = Vector2.new(1, 0),
		Position        = UDim2.new(1, -10, 1, 2),
		Size            = UDim2.new(0.48, 0, 0, 0),
		BackgroundColor3 = C.SurfaceAlt,
		BorderSizePixel = 0,
		Visible         = false,
		ZIndex          = 20,
		ClipsDescendants = true,
		Parent          = f,
	})
	Corner(6, list)
	Stroke(C.Border, 1, list)
	ListLayout(nil, nil, nil, 0, list)

	local open = false

	local function Refresh()
		btnTxt.Text = multi and (#elem.Value > 0 and table.concat(elem.Value, ", ") or "None") or tostring(elem.Value)
	end

	local function Build()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for i, v in ipairs(vals) do
			local selected = multi and table.find(elem.Value, v) or (elem.Value == v)
			local item = New("TextButton", {
				Size            = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				Text            = (selected and "✓  " or "    ") .. v,
				TextColor3      = selected and C.Accent or C.Text,
				TextSize        = 11,
				Font            = Enum.Font.Montserrat,
				TextXAlignment  = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				LayoutOrder     = i,
				ZIndex          = 21,
				Parent          = list,
			})
			New("UIPadding", { PaddingLeft = UDim.new(0, 8) }, item)
			item.MouseButton1Click:Connect(function()
				if multi then
					local idx = table.find(elem.Value, v)
					if idx then table.remove(elem.Value, idx) else table.insert(elem.Value, v) end
					;(opts.Callback or function() end)(elem.Value)
				else
					elem.Value = v
					open = false
					Tween(list, { Size = UDim2.new(0.48, 0, 0, 0) })
					task.delay(0.15, function() list.Visible = false end)
					;(opts.Callback or function() end)(v)
				end
				Refresh()
				if list.Visible then Build() end
			end)
			item.MouseEnter:Connect(function() Tween(item, { BackgroundColor3 = C.Border }) end)
			item.MouseLeave:Connect(function() Tween(item, { BackgroundTransparency = 1 }) end)
		end
	end

	btn.MouseButton1Click:Connect(function()
		open = not open
		if open then
			Build()
			list.Visible = true
			local h = math.min(#vals * 24, 130)
			Tween(list, { Size = UDim2.new(0.48, 0, 0, h) })
		else
			Tween(list, { Size = UDim2.new(0.48, 0, 0, 0) })
			task.delay(0.15, function() list.Visible = false end)
		end
	end)

	local function SetValue(v)
		elem.Value = v
		Refresh()
	end
	elem.SetValue = SetValue

	if opts.Flag then Flags[opts.Flag] = elem end
	elem.Link = MakeLink(elem, self)
	table.insert(self.Elements, elem)
	return elem
end

-- ============================================================
-- KEYBIND
-- ============================================================
function Section:AddKeybind(opts)
	local n     = #self.Elements + 1
	local elem  = { Name = opts.Name, Flag = opts.Flag, Value = Enum.KeyCode.Unknown, Listening = false }

	if opts.Default then
		pcall(function() elem.Value = Enum.KeyCode[opts.Default] end)
	end

	local f = ElemFrame(self._list, 32, n)
	if not opts._linked then ElemLabel(opts.Name, f) end

	local btn = New("TextButton", {
		AnchorPoint     = Vector2.new(1, 0.5),
		Position        = UDim2.new(1, -10, 0.5, 0),
		Size            = UDim2.new(0, 64, 0, 20),
		BackgroundColor3 = C.Bg,
		BorderSizePixel = 0,
		Text            = opts.Default or "NONE",
		TextColor3      = C.TextDim,
		TextSize        = 11,
		Font            = Enum.Font.MontserratBold,
		AutoButtonColor = false,
		Parent          = f,
	})
	Corner(6, btn)
	Stroke(C.Border, 1, btn)

	btn.MouseButton1Click:Connect(function()
		elem.Listening = true
		btn.Text = "..."
		btn.TextColor3 = C.Accent
	end)

	UserInputService.InputBegan:Connect(function(input)
		if not elem.Listening then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		elem.Listening = false
		elem.Value = input.KeyCode
		local name = input.KeyCode.Name
		btn.Text = #name > 9 and name:sub(1,8) .. "." or name
		btn.TextColor3 = C.TextDim
		;(opts.Callback or function() end)(input.KeyCode)
	end)

	local function SetValue(kc)
		elem.Value = kc
		btn.Text = kc.Name
	end
	elem.SetValue = SetValue

	if opts.Flag then Flags[opts.Flag] = elem end
	elem.Link = MakeLink(elem, self)
	table.insert(self.Elements, elem)
	return elem
end

-- ============================================================
-- COLOR PICKER  (hue-bar + brightness bar, no external deps)
-- ============================================================
function Section:AddColorPicker(opts)
	local n    = #self.Elements + 1
	local elem = { Name = opts.Name, Flag = opts.Flag, Value = opts.Default or Color3.fromRGB(255, 255, 255) }
	local h, s, v = 0, 0, 1
	do h, s, v = Color3.toHSV(elem.Value) end

	local f = ElemFrame(self._list, 32, n)
	if not opts._linked then ElemLabel(opts.Name, f) end

	local swatch = New("TextButton", {
		AnchorPoint     = Vector2.new(1, 0.5),
		Position        = UDim2.new(1, -10, 0.5, 0),
		Size            = UDim2.new(0, 38, 0, 20),
		BackgroundColor3 = elem.Value,
		BorderSizePixel = 0,
		Text            = "",
		AutoButtonColor = false,
		Parent          = f,
	})
	Corner(6, swatch)
	Stroke(C.Border, 1, swatch)

	-- Picker popup
	local popup = New("Frame", {
		AnchorPoint     = Vector2.new(1, 0),
		Position        = UDim2.new(1, -10, 1, 4),
		Size            = UDim2.new(0, 160, 0, 66),
		BackgroundColor3 = C.SurfaceAlt,
		BorderSizePixel = 0,
		Visible         = false,
		ZIndex          = 30,
		Parent          = f,
	})
	Corner(8, popup)
	Stroke(C.Border, 1, popup)

	-- Hue bar
	local hueBar = New("ImageLabel", {
		Position        = UDim2.new(0, 8, 0, 8),
		Size            = UDim2.new(1, -16, 0, 18),
		Image           = "rbxassetid://698052001",   -- rainbow gradient
		BorderSizePixel = 0,
		ZIndex          = 31,
		Parent          = popup,
	})
	Corner(4, hueBar)

	local hueKnob = New("Frame", {
		AnchorPoint     = Vector2.new(0.5, 0.5),
		Position        = UDim2.new(h, 0, 0.5, 0),
		Size            = UDim2.new(0, 6, 1, 0),
		BackgroundColor3 = C.Text,
		BorderSizePixel = 0,
		ZIndex          = 32,
		Parent          = hueBar,
	})
	Corner(2, hueKnob)

	-- Brightness bar
	local brtBar = New("Frame", {
		Position        = UDim2.new(0, 8, 0, 34),
		Size            = UDim2.new(1, -16, 0, 18),
		BorderSizePixel = 0,
		ZIndex          = 31,
		Parent          = popup,
	})
	Corner(4, brtBar)
	New("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(0,0,0), Color3.fromRGB(255,255,255)),
	}, brtBar)

	local brtKnob = New("Frame", {
		AnchorPoint     = Vector2.new(0.5, 0.5),
		Position        = UDim2.new(v, 0, 0.5, 0),
		Size            = UDim2.new(0, 6, 1, 0),
		BackgroundColor3 = C.Bg,
		BorderSizePixel = 0,
		ZIndex          = 32,
		Parent          = brtBar,
	})
	Corner(2, brtKnob)

	local function Apply()
		elem.Value = Color3.fromHSV(h, 1, v)
		swatch.BackgroundColor3 = elem.Value
		brtBar.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		;(opts.Callback or function() end)(elem.Value)
	end

	local function DragBar(bar, knob, inputX, setter)
		local rel = math.clamp((inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		Tween(knob, { Position = UDim2.new(rel, 0, 0.5, 0) })
		setter(rel)
		Apply()
	end

	local draggingHue, draggingBrt = false, false

	hueBar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingHue = true
			DragBar(hueBar, hueKnob, i.Position.X, function(r) h = r end)
		end
	end)
	brtBar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingBrt = true
			DragBar(brtBar, brtKnob, i.Position.X, function(r) v = r end)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		if draggingHue then DragBar(hueBar, hueKnob, i.Position.X, function(r) h = r end) end
		if draggingBrt then DragBar(brtBar, brtKnob, i.Position.X, function(r) v = r end) end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingHue = false; draggingBrt = false
		end
	end)

	local popOpen = false
	swatch.MouseButton1Click:Connect(function()
		popOpen = not popOpen
		popup.Visible = popOpen
	end)

	local function SetColor(c)
		elem.Value = c
		h, s, v = Color3.toHSV(c)
		swatch.BackgroundColor3 = c
		Tween(hueKnob, { Position = UDim2.new(h, 0, 0.5, 0) })
		Tween(brtKnob, { Position = UDim2.new(v, 0, 0.5, 0) })
		;(opts.Callback or function() end)(c)
	end
	elem.SetValue  = SetColor
	elem.SetColor  = SetColor

	if opts.Flag then Flags[opts.Flag] = elem end
	elem.Link = MakeLink(elem, self)
	table.insert(self.Elements, elem)
	return elem
end

-- ============================================================
-- BUTTON
-- ============================================================
function Section:AddButton(opts)
	local n    = #self.Elements + 1
	local elem = { Name = opts.Name }
	local f    = ElemFrame(self._list, 32, n)

	local btn = New("TextButton", {
		Size            = UDim2.new(1, -20, 0, 22),
		Position        = UDim2.new(0, 10, 0.5, -11),
		BackgroundColor3 = C.Border,
		BorderSizePixel = 0,
		Text            = opts.Name,
		TextColor3      = C.Text,
		TextSize        = 11,
		Font            = Enum.Font.MontserratBold,
		AutoButtonColor = false,
		Parent          = f,
	})
	Corner(6, btn)

	btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = C.SurfaceAlt }) end)
	btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = C.Border }) end)
	btn.MouseButton1Click:Connect(function()
		Tween(btn, { BackgroundColor3 = C.Accent })
		task.delay(0.08, function() Tween(btn, { BackgroundColor3 = C.Border }) end)
		;(opts.Callback or function() end)()
	end)

	table.insert(self.Elements, elem)
	return elem
end

-- ============================================================
-- PARAGRAPH
-- ============================================================
function Section:AddParagraph(opts)
	local n    = #self.Elements + 1
	local elem = { Name = opts.Title }
	local f    = New("Frame", {
		Name            = "Paragraph",
		Size            = UDim2.new(1, 0, 0, 0),
		AutomaticSize   = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder     = n,
		Parent          = self._list,
	})
	New("TextLabel", {
		Size            = UDim2.new(1, -20, 0, 0),
		Position        = UDim2.new(0, 10, 0, 6),
		AutomaticSize   = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		RichText        = true,
		Text            = "<b>" .. (opts.Title or "") .. "</b>\n<font color='#8c8c8c'>" .. (opts.Content or "") .. "</font>",
		TextColor3      = C.Text,
		TextSize        = 11,
		Font            = Enum.Font.Montserrat,
		TextXAlignment  = Enum.TextXAlignment.Left,
		TextWrapped     = true,
		Parent          = f,
	})
	table.insert(self.Elements, elem)
	return elem
end

-- ============================================================
-- CONFIG TAB  (built-in shortcut)
-- ============================================================
function Window:DrawConfig(opts)
	local tab = self:DrawTab({ Name = opts.Name, Icon = opts.Icon })
	local sec = tab:DrawSection({ Name = "Configs", Position = "left" })

	local function RefreshList(listSec)
		if not opts.Config then return end
		for _, e in ipairs(listSec.Elements) do
			if e._configEntry and e._frame then e._frame:Destroy() end
		end
		for _, name in ipairs(opts.Config:GetConfigs()) do
			listSec:AddButton({
				Name     = "Load: " .. name,
				Callback = function() opts.Config:LoadConfig(name) end,
			})
		end
	end

	sec:AddButton({
		Name = "Save Config",
		Callback = function()
			if opts.Config then
				local name = "Config_" .. os.time()
				opts.Config:WriteConfig({ Name = name, Author = LocalPlayer.Name })
			end
		end,
	})

	local listSec = tab:DrawSection({ Name = "Saved", Position = "right" })
	sec:AddButton({
		Name = "Refresh List",
		Callback = function() RefreshList(listSec) end,
	})

	if opts.Init then opts.Init() end
	return tab
end

return Halo
