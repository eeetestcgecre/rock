-- Neverlose Style GUI Library
-- Версия: 3.0.0
-- Стиль: Neverlose UI
-- Фичи: светлая/тёмная тема, анимации, современный дизайн

local NeverloseLib = {}
NeverloseLib.__index = NeverloseLib

-- Сервисы
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Константы
local THEMES = {
    Dark = {
        Background = Color3.fromRGB(20, 20, 20),
        Window = Color3.fromRGB(28, 28, 28),
        Accent = Color3.fromRGB(80, 160, 255),
        Element = Color3.fromRGB(40, 40, 40),
        Text = Color3.fromRGB(240, 240, 240),
        Border = Color3.fromRGB(50, 50, 50),
        Hover = Color3.fromRGB(60, 60, 60),
        Success = Color3.fromRGB(80, 200, 120),
        Danger = Color3.fromRGB(220, 80, 80)
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 240),
        Window = Color3.fromRGB(250, 250, 250),
        Accent = Color3.fromRGB(60, 140, 255),
        Element = Color3.fromRGB(230, 230, 230),
        Text = Color3.fromRGB(30, 30, 30),
        Border = Color3.fromRGB(200, 200, 200),
        Hover = Color3.fromRGB(220, 220, 220),
        Success = Color3.fromRGB(70, 180, 100),
        Danger = Color3.fromRGB(200, 70, 70)
    }
}

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- Вспомогательные функции
local function tween(instance, properties)
    local tween = TweenService:Create(instance, TWEEN_INFO, properties)
    tween:Play()
    return tween
end

local function createRoundedFrame(parent, size, position)
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = THEMES.Dark.Element
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = THEMES.Dark.Border
    stroke.Thickness = 1
    stroke.Parent = frame
    
    if parent then
        frame.Parent = parent
    end
    
    return frame
end

local function createTextLabel(parent, text, size, position)
    local label = Instance.new("TextLabel")
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEMES.Dark.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    if parent then
        label.Parent = parent
    end
    
    return label
end

-- Основной класс
function NeverloseLib.new(options)
    options = options or {}
    local self = setmetatable({}, NeverloseLib)
    
    self.player = Players.LocalPlayer
    self.currentTheme = options.Theme or "Dark"
    self.theme = THEMES[self.currentTheme]
    
    -- Создание интерфейса
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "NeverloseUI"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.screenGui.Parent = self.player:WaitForChild("PlayerGui")
    
    -- Главное окно
    self.mainFrame = createRoundedFrame(self.screenGui, 
        options.Size or UDim2.new(0, 500, 0, 450),
        options.Position or UDim2.new(0.5, -250, 0.5, -225)
    )
    self.mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    self.mainFrame.BackgroundColor3 = self.theme.Window
    
    -- Заголовок
    self.header = createRoundedFrame(self.mainFrame, UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 10))
    self.header.BackgroundColor3 = self.theme.Background
    
    self.title = createTextLabel(self.header, options.Title or "Neverlose UI", 
        UDim2.new(1, -40, 1, 0), UDim2.new(0, 15, 0, 0)
    )
    self.title.TextSize = 16
    self.title.Font = Enum.Font.GothamBold
    
    -- Кнопка переключения темы
    self.themeButton = Instance.new("TextButton")
    self.themeButton.Size = UDim2.new(0, 30, 0, 30)
    self.themeButton.Position = UDim2.new(1, -40, 0.5, -15)
    self.themeButton.BackgroundColor3 = self.theme.Accent
    self.themeButton.BorderSizePixel = 0
    self.themeButton.Text = self.currentTheme == "Dark" and "☀️" or "🌙"
    self.themeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.themeButton.Font = Enum.Font.GothamBold
    self.themeButton.TextSize = 14
    self.themeButton.Parent = self.header
    
    local themeCorner = Instance.new("UICorner")
    themeCorner.CornerRadius = UDim.new(0, 4)
    themeCorner.Parent = self.themeButton
    
    -- Контейнер вкладок
    self.tabContainer = Instance.new("Frame")
    self.tabContainer.Size = UDim2.new(1, -20, 0, 40)
    self.tabContainer.Position = UDim2.new(0, 10, 0, 60)
    self.tabContainer.BackgroundTransparency = 1
    self.tabContainer.Parent = self.mainFrame
    
    self.tabLayout = Instance.new("UIListLayout")
    self.tabLayout.FillDirection = Enum.FillDirection.Horizontal
    self.tabLayout.Padding = UDim.new(0, 8)
    self.tabLayout.Parent = self.tabContainer
    
    -- Контейнер контента
    self.contentContainer = createRoundedFrame(self.mainFrame, 
        UDim2.new(1, -20, 1, -110), UDim2.new(0, 10, 0, 110)
    )
    self.contentContainer.BackgroundColor3 = self.theme.Background
    self.contentContainer.ClipsDescendants = true
    
    self.tabs = {}
    self.currentTab = nil
    
    -- Обработчики событий
    self.themeButton.MouseButton1Click:Connect(function()
        self:toggleTheme()
    end)
    
    -- Перетаскивание
    self:draggable(self.header)
    
    return self
end

function NeverloseLib:toggleTheme()
    self.currentTheme = self.currentTheme == "Dark" and "Light" or "Dark"
    self.theme = THEMES[self.currentTheme]
    self.themeButton.Text = self.currentTheme == "Dark" and "☀️" or "🌙"
    
    self:updateTheme()
end

function NeverloseLib:updateTheme()
    self.mainFrame.BackgroundColor3 = self.theme.Window
    self.header.BackgroundColor3 = self.theme.Background
    self.contentContainer.BackgroundColor3 = self.theme.Background
    self.title.TextColor3 = self.theme.Text
    self.themeButton.BackgroundColor3 = self.theme.Accent
    
    -- Обновляем все элементы
    for _, tab in pairs(self.tabs) do
        for _, element in pairs(tab.elements) do
            if element:IsA("Frame") then
                element.BackgroundColor3 = self.theme.Element
                if element:FindFirstChild("UIStroke") then
                    element.UIStroke.Color = self.theme.Border
                end
            elseif element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
                element.TextColor3 = self.theme.Text
            end
        end
    end
end

function NeverloseLib:draggable(frame)
    local dragging, dragStart, startPos
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function NeverloseLib:Tab(name)
    local tabButton = Instance.new("TextButton")
    tabButton.Size = UDim2.new(0, 100, 1, 0)
    tabButton.BackgroundColor3 = self.theme.Element
    tabButton.BorderSizePixel = 0
    tabButton.Text = name
    tabButton.TextColor3 = self.theme.Text
    tabButton.Font = Enum.Font.Gotham
    tabButton.TextSize = 14
    tabButton.Parent = self.tabContainer
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = tabButton
    
    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Size = UDim2.new(1, -20, 1, -20)
    tabContent.Position = UDim2.new(0, 10, 0, 10)
    tabContent.BackgroundTransparency = 1
    tabContent.ScrollBarThickness = 6
    tabContent.Visible = false
    tabContent.Parent = self.contentContainer
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = tabContent
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    padding.Parent = tabContent
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabContent.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    
    local tab = {
        name = name,
        button = tabButton,
        content = tabContent,
        elements = {}
    }
    
    tabButton.MouseButton1Click:Connect(function()
        self:switchTab(tab)
    end)
    
    table.insert(self.tabs, tab)
    
    if #self.tabs == 1 then
        self:switchTab(tab)
    end
    
    return setmetatable({}, {
        __index = function(_, method)
            return function(_, ...)
                return self:addElement(tab, method, ...)
            end
        end
    })
end

function NeverloseLib:switchTab(tab)
    if self.currentTab == tab then return end
    
    if self.currentTab then
        self.currentTab.content.Visible = false
        tween(self.currentTab.button, {BackgroundColor3 = self.theme.Element})
    end
    
    self.currentTab = tab
    tab.content.Visible = true
    tween(tab.button, {BackgroundColor3 = self.theme.Accent})
end

function NeverloseLib:addElement(tab, elementType, ...)
    if elementType == "Button" then
        return self:createButton(tab, ...)
    elseif elementType == "Toggle" then
        return self:createToggle(tab, ...)
    elseif elementType == "Slider" then
        return self:createSlider(tab, ...)
    elseif elementType == "Label" then
        return self:createLabel(tab, ...)
    end
end

function NeverloseLib:createButton(tab, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 40)
    button.BackgroundColor3 = self.theme.Element
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = self.theme.Text
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.Parent = tab.content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = self.theme.Border
    stroke.Thickness = 1
    stroke.Parent = button
    
    -- Анимации
    button.MouseEnter:Connect(function()
        tween(button, {BackgroundColor3 = self.theme.Hover})
    end)
    
    button.MouseLeave:Connect(function()
        tween(button, {BackgroundColor3 = self.theme.Element})
    end)
    
    button.MouseButton1Click:Connect(function()
        tween(button, {Size = UDim2.new(0.95, 0, 0, 40)})
        task.wait(0.1)
        tween(button, {Size = UDim2.new(1, 0, 0, 40)})
        if callback then
            pcall(callback)
        end
    end)
    
    table.insert(tab.elements, button)
    return button
end

function NeverloseLib:createToggle(tab, text, default, callback)
    local state = default or false
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(1, 0, 0, 40)
    toggle.BackgroundColor3 = self.theme.Element
    toggle.BorderSizePixel = 0
    toggle.Text = text
    toggle.TextColor3 = self.theme.Text
    toggle.Font = Enum.Font.Gotham
    toggle.TextSize = 14
    toggle.TextXAlignment = Enum.TextXAlignment.Left
    toggle.Parent = tab.content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = toggle
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = self.theme.Border
    stroke.Thickness = 1
    stroke.Parent = toggle
    
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 20, 0, 20)
    indicator.Position = UDim2.new(1, -30, 0.5, -10)
    indicator.BackgroundColor3 = state and self.theme.Success or self.theme.Danger
    indicator.BorderSizePixel = 0
    indicator.Parent = toggle
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 4)
    indicatorCorner.Parent = indicator
    
    local function updateState()
        indicator.BackgroundColor3 = state and self.theme.Success or self.theme.Danger
    end
    
    toggle.MouseButton1Click:Connect(function()
        state = not state
        updateState()
        if callback then
            pcall(callback, state)
        end
    end)
    
    updateState()
    table.insert(tab.elements, toggle)
    
    return {
        Set = function(value)
            state = value
            updateState()
        end,
        Get = function()
            return state
        end
    }
end

function NeverloseLib:createSlider(tab, text, min, max, default, callback)
    local value = math.clamp(default or min, min, max)
    
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(1, 0, 0, 60)
    slider.BackgroundTransparency = 1
    slider.Parent = tab.content
    
    local label = createTextLabel(slider, text, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0))
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0, 30)
    track.BackgroundColor3 = self.theme.Element
    track.BorderSizePixel = 0
    track.Parent = slider
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 3)
    trackCorner.Parent = track
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = self.theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = fill
    
    local valueText = createTextLabel(slider, tostring(value), UDim2.new(0, 50, 0, 20), UDim2.new(1, -50, 0, 40))
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    
    local dragging = false
    
    local function updateValue(newValue)
        value = math.clamp(newValue, min, max)
        local ratio = (value - min) / (max - min)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        valueText.Text = tostring(value)
        if callback then
            pcall(callback, value)
        end
    end
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local relativeX = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
            updateValue(min + (max - min) * relativeX)
        end
    end)
    
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativeX = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
            updateValue(min + (max - min) * relativeX)
        end
    end)
    
    table.insert(tab.elements, slider)
    
    return {
        Set = updateValue,
        Get = function()
            return value
        end
    }
end

function NeverloseLib:createLabel(tab, text)
    local label = createTextLabel(tab.content, text, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0))
    label.TextSize = 12
    label.TextColor3 = self.theme.Text
    table.insert(tab.elements, label)
    return label
end

function NeverloseLib:Destroy()
    self.screenGui:Destroy()
end

return NeverloseLib
