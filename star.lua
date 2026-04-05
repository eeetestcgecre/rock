-- SiriusUILib.lua
-- Черно-белая библиотека для создания GUI (Roblox)

local SiriusUILib = {}
SiriusUILib.__index = SiriusUILib

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Цветовая схема (черный, белый, градиент)
SiriusUILib.Colors = {
    Background = Color3.fromRGB(0, 0, 0),      -- Черный
    Foreground = Color3.fromRGB(255, 255, 255), -- Белый
    GradientStart = Color3.fromRGB(255, 255, 255), -- Белый для градиента
    GradientEnd = Color3.fromRGB(150, 150, 150),   -- Серый
    Accent = Color3.fromRGB(200, 200, 200)         -- Светло-серый
}

-- Настройки UI
SiriusUILib.Settings = {
    TweenTime = 0.3,
    NotificationDuration = 3,
    EnableSounds = true,
    SoundId = "rbxassetid://255881176" -- стандартный звук уведомления
}

-- Глобальные переменные
local guiParent = gethui and gethui() or game:GetService("CoreGui")
local mainGUI = nil
local activeWindows = {}
local notifications = {}
local currentKeybindListeners = {}

-- Вспомогательные функции
local function createTween(object, properties, duration)
    duration = duration or SiriusUILib.Settings.TweenTime
    local tween = TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

local function playSound(parent)
    if not SiriusUILib.Settings.EnableSounds then return end
    local sound = Instance.new("Sound")
    sound.SoundId = SiriusUILib.Settings.SoundId
    sound.Volume = 0.5
    sound.Parent = parent or mainGUI
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
    task.delay(1, function() if sound then sound:Destroy() end end)
end

local function makeDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local screenGui = frame:FindFirstAncestorWhichIsA("ScreenGui")
    local offset = Vector2.zero
    if screenGui and screenGui.IgnoreGuiInset then
        offset = GuiService:GetGuiInset()
    end
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y + offset.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Функция для создания главного окна
function SiriusUILib:CreateWindow(title, size)
    if mainGUI then mainGUI:Destroy() end
    
    -- Создание ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "SiriusUI"
    gui.Parent = guiParent
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Enabled = false
    
    -- Основной фрейм
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = size or UDim2.new(0, 600, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = SiriusUILib.Colors.Background
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = gui
    
    -- Тень / градиент
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, SiriusUILib.Colors.GradientStart),
        ColorSequenceKeypoint.new(1, SiriusUILib.Colors.GradientEnd)
    })
    gradient.Rotation = 90
    gradient.Parent = mainFrame
    
    -- UIStroke для рамки
    local stroke = Instance.new("UIStroke")
    stroke.Color = SiriusUILib.Colors.Foreground
    stroke.Thickness = 1
    stroke.Transparency = 0.8
    stroke.Parent = mainFrame
    
    -- UIGradient для рамки
    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, SiriusUILib.Colors.GradientStart),
        ColorSequenceKeypoint.new(1, SiriusUILib.Colors.GradientEnd)
    })
    strokeGradient.Rotation = 90
    strokeGradient.Parent = stroke
    
    -- UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Заголовок окна
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.BackgroundColor3 = SiriusUILib.Colors.Background
    titleBar.BackgroundTransparency = 0.5
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = title or "Sirius UI"
    titleLabel.TextColor3 = SiriusUILib.Colors.Foreground
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Position = UDim2.new(0, 15, 0.5, -10)
    titleLabel.Size = UDim2.new(0, 200, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = titleBar
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = SiriusUILib.Colors.Foreground
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Size = UDim2.new(0, 35, 1, 0)
    closeBtn.Position = UDim2.new(1, -35, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)
    
    makeDraggable(titleBar)
    
    -- Контейнер для табов
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0, 120, 1, -35)
    tabContainer.Position = UDim2.new(0, 0, 0, 35)
    tabContainer.BackgroundColor3 = SiriusUILib.Colors.Background
    tabContainer.BackgroundTransparency = 0.2
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 0)
    tabCorner.Parent = tabContainer
    
    -- Контейнер для контента
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -120, 1, -35)
    contentContainer.Position = UDim2.new(0, 120, 0, 35)
    contentContainer.BackgroundColor3 = SiriusUILib.Colors.Background
    contentContainer.BackgroundTransparency = 0.1
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = mainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 0)
    contentCorner.Parent = contentContainer
    
    -- Список табов
    local tabs = {}
    local activeTab = nil
    
    -- Функция для создания таба
    local function createTabButton(tabName, callback)
        local button = Instance.new("TextButton")
        button.Text = tabName
        button.TextColor3 = SiriusUILib.Colors.Foreground
        button.TextSize = 14
        button.Font = Enum.Font.Gotham
        button.Size = UDim2.new(1, -10, 0, 40)
        button.Position = UDim2.new(0, 5, 0, #tabs * 45 + 5)
        button.BackgroundColor3 = SiriusUILib.Colors.Background
        button.BackgroundTransparency = 0.8
        button.BorderSizePixel = 0
        button.Parent = tabContainer
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button
        
        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Color = SiriusUILib.Colors.Foreground
        buttonStroke.Thickness = 0.5
        buttonStroke.Transparency = 0.7
        buttonStroke.Parent = button
        
        button.MouseButton1Click:Connect(function()
            if callback then callback() end
            for _, btn in pairs(tabs) do
                btn.Button.BackgroundTransparency = 0.8
                btn.Button.TextColor3 = SiriusUILib.Colors.Foreground
                if btn.Content then btn.Content.Visible = false end
            end
            button.BackgroundTransparency = 0.3
            button.TextColor3 = SiriusUILib.Colors.GradientStart
            if activeTab and activeTab.Content then
                activeTab.Content.Visible = false
            end
        end)
        
        return button
    end
    
    -- API для создания таба
    function self:CreateTab(name)
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = name .. "Content"
        tabContent.Size = UDim2.new(1, -20, 1, -20)
        tabContent.Position = UDim2.new(0, 10, 0, 10)
        tabContent.BackgroundTransparency = 1
        tabContent.BorderSizePixel = 0
        tabContent.ScrollBarThickness = 6
        tabContent.ScrollBarImageColor3 = SiriusUILib.Colors.Foreground
        tabContent.ScrollBarImageTransparency = 0.7
        tabContent.Parent = contentContainer
        tabContent.Visible = false
        
        local uiList = Instance.new("UIListLayout")
        uiList.Padding = UDim.new(0, 8)
        uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        uiList.Parent = tabContent
        
        local button = createTabButton(name, function()
            tabContent.Visible = true
            activeTab = {Name = name, Content = tabContent, Button = button}
        end)
        
        table.insert(tabs, {Name = name, Content = tabContent, Button = button})
        
        if #tabs == 1 then
            button.BackgroundTransparency = 0.3
            button.TextColor3 = SiriusUILib.Colors.GradientStart
            tabContent.Visible = true
            activeTab = tabs[1]
        end
        
        -- Возвращаем объект для добавления элементов
        return {
            _content = tabContent,
            _listLayout = uiList,
            
            CreateButton = function(self, text, callback)
                local btn = Instance.new("TextButton")
                btn.Text = text
                btn.TextColor3 = SiriusUILib.Colors.Foreground
                btn.TextSize = 14
                btn.Font = Enum.Font.Gotham
                btn.Size = UDim2.new(0, 200, 0, 35)
                btn.BackgroundColor3 = SiriusUILib.Colors.Background
                btn.BackgroundTransparency = 0.7
                btn.BorderSizePixel = 0
                btn.Parent = tabContent
                
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 6)
                btnCorner.Parent = btn
                
                local btnStroke = Instance.new("UIStroke")
                btnStroke.Color = SiriusUILib.Colors.Foreground
                btnStroke.Thickness = 0.5
                btnStroke.Transparency = 0.8
                btnStroke.Parent = btn
                
                btn.MouseEnter:Connect(function()
                    createTween(btn, {BackgroundTransparency = 0.4}, 0.2)
                end)
                btn.MouseLeave:Connect(function()
                    createTween(btn, {BackgroundTransparency = 0.7}, 0.2)
                end)
                
                btn.MouseButton1Click:Connect(function()
                    playSound(mainGUI)
                    if callback then callback() end
                end)
                
                return btn
            end,
            
            CreateToggle = function(self, text, default, callback)
                local toggleFrame = Instance.new("Frame")
                toggleFrame.Size = UDim2.new(0, 250, 0, 35)
                toggleFrame.BackgroundTransparency = 1
                toggleFrame.Parent = tabContent
                
                local label = Instance.new("TextLabel")
                label.Text = text
                label.TextColor3 = SiriusUILib.Colors.Foreground
                label.TextSize = 14
                label.Font = Enum.Font.Gotham
                label.Size = UDim2.new(0, 180, 1, 0)
                label.Position = UDim2.new(0, 5, 0, 0)
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.BackgroundTransparency = 1
                label.Parent = toggleFrame
                
                local toggleBtn = Instance.new("TextButton")
                toggleBtn.Text = default and "ON" or "OFF"
                toggleBtn.TextColor3 = SiriusUILib.Colors.Foreground
                toggleBtn.TextSize = 12
                toggleBtn.Font = Enum.Font.GothamBold
                toggleBtn.Size = UDim2.new(0, 50, 1, 0)
                toggleBtn.Position = UDim2.new(1, -55, 0, 0)
                toggleBtn.BackgroundColor3 = default and SiriusUILib.Colors.Foreground or SiriusUILib.Colors.Background
                toggleBtn.BackgroundTransparency = default and 0.3 or 0.7
                toggleBtn.BorderSizePixel = 0
                toggleBtn.Parent = toggleFrame
                
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 4)
                btnCorner.Parent = toggleBtn
                
                local state = default
                toggleBtn.MouseButton1Click:Connect(function()
                    state = not state
                    toggleBtn.Text = state and "ON" or "OFF"
                    toggleBtn.BackgroundColor3 = state and SiriusUILib.Colors.Foreground or SiriusUILib.Colors.Background
                    toggleBtn.BackgroundTransparency = state and 0.3 or 0.7
                    playSound(mainGUI)
                    if callback then callback(state) end
                end)
                
                return toggleBtn
            end,
            
            CreateSlider = function(self, text, min, max, default, callback)
                local sliderFrame = Instance.new("Frame")
                sliderFrame.Size = UDim2.new(0, 250, 0, 55)
                sliderFrame.BackgroundTransparency = 1
                sliderFrame.Parent = tabContent
                
                local label = Instance.new("TextLabel")
                label.Text = text
                label.TextColor3 = SiriusUILib.Colors.Foreground
                label.TextSize = 12
                label.Font = Enum.Font.Gotham
                label.Size = UDim2.new(1, 0, 0, 20)
                label.BackgroundTransparency = 1
                label.Parent = sliderFrame
                
                local valueLabel = Instance.new("TextLabel")
                valueLabel.Text = tostring(default)
                valueLabel.TextColor3 = SiriusUILib.Colors.Foreground
                valueLabel.TextSize = 12
                valueLabel.Font = Enum.Font.GothamBold
                valueLabel.Size = UDim2.new(0, 50, 0, 20)
                valueLabel.Position = UDim2.new(1, -50, 0, 0)
                valueLabel.TextXAlignment = Enum.TextXAlignment.Right
                valueLabel.BackgroundTransparency = 1
                valueLabel.Parent = sliderFrame
                
                local barBg = Instance.new("Frame")
                barBg.Size = UDim2.new(1, 0, 0, 4)
                barBg.Position = UDim2.new(0, 0, 0, 25)
                barBg.BackgroundColor3 = SiriusUILib.Colors.Foreground
                barBg.BackgroundTransparency = 0.8
                barBg.BorderSizePixel = 0
                barBg.Parent = sliderFrame
                
                local barFill = Instance.new("Frame")
                barFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
                barFill.BackgroundColor3 = SiriusUILib.Colors.Foreground
                barFill.BackgroundTransparency = 0.3
                barFill.BorderSizePixel = 0
                barFill.Parent = barBg
                
                local sliderBtn = Instance.new("TextButton")
                sliderBtn.Text = ""
                sliderBtn.Size = UDim2.new(0, 12, 0, 12)
                sliderBtn.Position = UDim2.new((default - min) / (max - min), -6, 0, -4)
                sliderBtn.BackgroundColor3 = SiriusUILib.Colors.Foreground
                sliderBtn.BackgroundTransparency = 0.2
                sliderBtn.BorderSizePixel = 0
                sliderBtn.Parent = barBg
                
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(1, 0)
                btnCorner.Parent = sliderBtn
                
                local dragging = false
                local value = default
                
                local function updateSlider(input)
                    local relativeX = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                    value = math.floor(min + (max - min) * relativeX + 0.5)
                    valueLabel.Text = tostring(value)
                    barFill.Size = UDim2.new(relativeX, 0, 1, 0)
                    sliderBtn.Position = UDim2.new(relativeX, -6, 0, -4)
                    if callback then callback(value) end
                end
                
                sliderBtn.MouseButton1Down:Connect(function()
                    dragging = true
                    updateSlider(UserInputService:GetMouseLocation())
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateSlider(input)
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                return sliderBtn
            end,
            
            CreateInput = function(self, placeholder, callback)
                local inputBox = Instance.new("TextBox")
                inputBox.PlaceholderText = placeholder
                inputBox.Text = ""
                inputBox.TextColor3 = SiriusUILib.Colors.Foreground
                inputBox.PlaceholderColor3 = SiriusUILib.Colors.Foreground
                inputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
                inputBox.TextSize = 14
                inputBox.Font = Enum.Font.Gotham
                inputBox.Size = UDim2.new(0, 250, 0, 35)
                inputBox.BackgroundColor3 = SiriusUILib.Colors.Background
                inputBox.BackgroundTransparency = 0.7
                inputBox.BorderSizePixel = 0
                inputBox.Parent = tabContent
                
                local inputCorner = Instance.new("UICorner")
                inputCorner.CornerRadius = UDim.new(0, 6)
                inputCorner.Parent = inputBox
                
                local inputStroke = Instance.new("UIStroke")
                inputStroke.Color = SiriusUILib.Colors.Foreground
                inputStroke.Thickness = 0.5
                inputStroke.Transparency = 0.8
                inputStroke.Parent = inputBox
                
                inputBox.FocusLost:Connect(function(enterPressed)
                    if enterPressed and callback then
                        callback(inputBox.Text)
                        playSound(mainGUI)
                    end
                end)
                
                return inputBox
            end,
            
            CreateLabel = function(self, text)
                local label = Instance.new("TextLabel")
                label.Text = text
                label.TextColor3 = SiriusUILib.Colors.Foreground
                label.TextSize = 13
                label.Font = Enum.Font.Gotham
                label.Size = UDim2.new(0, 250, 0, 25)
                label.BackgroundTransparency = 1
                label.Parent = tabContent
                return label
            end,
            
            CreateSeparator = function(self)
                local sep = Instance.new("Frame")
                sep.Size = UDim2.new(0, 250, 0, 1)
                sep.BackgroundColor3 = SiriusUILib.Colors.Foreground
                sep.BackgroundTransparency = 0.8
                sep.BorderSizePixel = 0
                sep.Parent = tabContent
                return sep
            end
        }
    end
    
    -- API для уведомлений
    function self:Notify(title, description, duration)
        duration = duration or SiriusUILib.Settings.NotificationDuration
        
        local notifFrame = Instance.new("Frame")
        notifFrame.Size = UDim2.new(0, 300, 0, 60)
        notifFrame.Position = UDim2.new(1, 20, 1, -80)
        notifFrame.AnchorPoint = Vector2.new(1, 1)
        notifFrame.BackgroundColor3 = SiriusUILib.Colors.Background
        notifFrame.BackgroundTransparency = 0.2
        notifFrame.BorderSizePixel = 0
        notifFrame.Parent = mainGUI or gui
        
        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 8)
        notifCorner.Parent = notifFrame
        
        local notifStroke = Instance.new("UIStroke")
        notifStroke.Color = SiriusUILib.Colors.Foreground
        notifStroke.Thickness = 1
        notifStroke.Transparency = 0.7
        notifStroke.Parent = notifFrame
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Text = title or "Уведомление"
        titleLabel.TextColor3 = SiriusUILib.Colors.Foreground
        titleLabel.TextSize = 14
        titleLabel.Font = Enum.Font.GothamSemibold
        titleLabel.Position = UDim2.new(0, 10, 0, 5)
        titleLabel.Size = UDim2.new(1, -20, 0, 20)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.BackgroundTransparency = 1
        titleLabel.Parent = notifFrame
        
        local descLabel = Instance.new("TextLabel")
        descLabel.Text = description or ""
        descLabel.TextColor3 = SiriusUILib.Colors.Foreground
        descLabel.TextSize = 12
        descLabel.Font = Enum.Font.Gotham
        descLabel.Position = UDim2.new(0, 10, 0, 25)
        descLabel.Size = UDim2.new(1, -20, 0, 30)
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.BackgroundTransparency = 1
        descLabel.Parent = notifFrame
        
        notifFrame.Position = UDim2.new(1, 20, 1, -80)
        createTween(notifFrame, {Position = UDim2.new(1, -320, 1, -80)}, 0.4)
        
        playSound(mainGUI or gui)
        
        task.delay(duration, function()
            createTween(notifFrame, {Position = UDim2.new(1, 20, 1, -80), BackgroundTransparency = 1}, 0.4)
            task.wait(0.5)
            notifFrame:Destroy()
        end)
        
        return notifFrame
    end
    
    -- API для показа/скрытия окна
    function self:Show()
        gui.Enabled = true
    end
    
    function self:Hide()
        gui.Enabled = false
    end
    
    function self:Toggle()
        gui.Enabled = not gui.Enabled
    end
    
    mainGUI = gui
    
    return self
end

-- Функция для создания отдельного уведомления без окна
function SiriusUILib:Notify(title, description, duration)
    if not mainGUI then return end
    
    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, 300, 0, 60)
    notifFrame.Position = UDim2.new(1, 20, 1, -80)
    notifFrame.AnchorPoint = Vector2.new(1, 1)
    notifFrame.BackgroundColor3 = SiriusUILib.Colors.Background
    notifFrame.BackgroundTransparency = 0.2
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = mainGUI
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notifFrame
    
    local notifStroke = Instance.new("UIStroke")
    notifStroke.Color = SiriusUILib.Colors.Foreground
    notifStroke.Thickness = 1
    notifStroke.Transparency = 0.7
    notifStroke.Parent = notifFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = title or "Уведомление"
    titleLabel.TextColor3 = SiriusUILib.Colors.Foreground
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = notifFrame
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Text = description or ""
    descLabel.TextColor3 = SiriusUILib.Colors.Foreground
    descLabel.TextSize = 12
    descLabel.Font = Enum.Font.Gotham
    descLabel.Position = UDim2.new(0, 10, 0, 25)
    descLabel.Size = UDim2.new(1, -20, 0, 30)
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.BackgroundTransparency = 1
    descLabel.Parent = notifFrame
    
    createTween(notifFrame, {Position = UDim2.new(1, -320, 1, -80)}, 0.4)
    playSound(mainGUI)
    
    task.delay(duration or 3, function()
        createTween(notifFrame, {Position = UDim2.new(1, 20, 1, -80), BackgroundTransparency = 1}, 0.4)
        task.wait(0.5)
        notifFrame:Destroy()
    end)
    
    return notifFrame
end

-- Функция для установки темы
function SiriusUILib:SetTheme(colors)
    for k, v in pairs(colors) do
        if SiriusUILib.Colors[k] then
            SiriusUILib.Colors[k] = v
        end
    end
end

return SiriusUILib
