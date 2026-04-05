-- SiriusUILib.lua (версия с верхней панелью)
local SiriusUILib = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

-- Цветовая схема (чёрный, белый, градиент)
SiriusUILib.Colors = {
    Background = Color3.fromRGB(0, 0, 0),
    Foreground = Color3.fromRGB(255, 255, 255),
    GradientStart = Color3.fromRGB(255, 255, 255),
    GradientEnd = Color3.fromRGB(100, 100, 100),
    Accent = Color3.fromRGB(200, 200, 200),
    TopBar = Color3.fromRGB(20, 20, 20)
}

-- Настройки
SiriusUILib.Settings = {
    TweenTime = 0.3,
    NotificationDuration = 3,
    EnableSounds = true,
    SoundId = "rbxassetid://255881176"
}

local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
local mainGUI = nil

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
    local offset = Vector2.zero
    
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
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

function SiriusUILib:CreateWindow(title, size)
    if mainGUI then mainGUI:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SiriusUI"
    gui.Parent = guiParent
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Enabled = false

    -- Основной фрейм
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = size or UDim2.new(0, 600, 0, 450)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = SiriusUILib.Colors.Background
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = gui

    -- Градиент фона
    local bgGradient = Instance.new("UIGradient")
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, SiriusUILib.Colors.GradientStart),
        ColorSequenceKeypoint.new(1, SiriusUILib.Colors.GradientEnd)
    })
    bgGradient.Rotation = 135
    bgGradient.Transparency = 0.85
    bgGradient.Parent = mainFrame

    -- Рамка
    local stroke = Instance.new("UIStroke")
    stroke.Color = SiriusUILib.Colors.Foreground
    stroke.Thickness = 1.5
    stroke.Transparency = 0.7
    stroke.Parent = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    -- ========== ВЕРХНЯЯ ПАНЕЛЬ (как в оригинале) ==========
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 50)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = SiriusUILib.Colors.TopBar
    topBar.BackgroundTransparency = 0.15
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame

    local topCorner = Instance.new("UICorner")
    topCorner.CornerRadius = UDim.new(0, 10)
    topCorner.Parent = topBar

    -- Заголовок слева
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = title or "SIRIUS"
    titleLabel.TextColor3 = SiriusUILib.Colors.Foreground
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Position = UDim2.new(0, 15, 0.5, -12)
    titleLabel.Size = UDim2.new(0, 150, 0, 24)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = topBar

    -- Контейнер для кнопок на топбаре
    local topButtonsContainer = Instance.new("Frame")
    topButtonsContainer.Name = "TopButtons"
    topButtonsContainer.Size = UDim2.new(0, 300, 1, 0)
    topButtonsContainer.Position = UDim2.new(0.5, -150, 0, 0)
    topButtonsContainer.BackgroundTransparency = 1
    topButtonsContainer.Parent = topBar

    local buttonsLayout = Instance.new("UIListLayout")
    buttonsLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    buttonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    buttonsLayout.Padding = UDim.new(0, 5)
    buttonsLayout.Parent = topButtonsContainer

    -- Кнопка закрытия справа
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = SiriusUILib.Colors.Foreground
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Size = UDim2.new(0, 45, 1, 0)
    closeBtn.Position = UDim2.new(1, -45, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Parent = topBar
    
    closeBtn.MouseEnter:Connect(function()
        createTween(closeBtn, {TextColor3 = Color3.fromRGB(255, 100, 100)}, 0.2)
    end)
    closeBtn.MouseLeave:Connect(function()
        createTween(closeBtn, {TextColor3 = SiriusUILib.Colors.Foreground}, 0.2)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)

    -- Контейнер для контента (под топбаром)
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 1, -50)
    contentContainer.Position = UDim2.new(0, 0, 0, 50)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame

    -- Контейнер для страниц (табов)
    local pagesContainer = Instance.new("Frame")
    pagesContainer.Name = "Pages"
    pagesContainer.Size = UDim2.new(1, 0, 1, 0)
    pagesContainer.BackgroundTransparency = 1
    pagesContainer.Parent = contentContainer

    -- Список кнопок и страниц
    local topButtons = {}
    local pages = {}
    local activePage = nil

    -- Функция создания кнопки на топбаре
    local function createTopButton(name, callback)
        local btn = Instance.new("TextButton")
        btn.Text = name
        btn.TextColor3 = SiriusUILib.Colors.Foreground
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamSemibold
        btn.Size = UDim2.new(0, 80, 0, 35)
        btn.BackgroundColor3 = SiriusUILib.Colors.Background
        btn.BackgroundTransparency = 0.8
        btn.BorderSizePixel = 0
        btn.Parent = topButtonsContainer

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        btn.MouseEnter:Connect(function()
            createTween(btn, {BackgroundTransparency = 0.5}, 0.2)
        end)
        btn.MouseLeave:Connect(function()
            if activePage ~= name then
                createTween(btn, {BackgroundTransparency = 0.8}, 0.2)
            end
        end)

        btn.MouseButton1Click:Connect(function()
            if callback then callback() end
            for _, b in pairs(topButtons) do
                createTween(b.Button, {BackgroundTransparency = 0.8, TextColor3 = SiriusUILib.Colors.Foreground}, 0.2)
            end
            createTween(btn, {BackgroundTransparency = 0.3, TextColor3 = SiriusUILib.Colors.GradientStart}, 0.2)
            activePage = name
            playSound(gui)
        end)

        table.insert(topButtons, {Name = name, Button = btn})
        return btn
    end

    -- API окна
    local self = {}

    function self:CreateTab(name)
        -- Создаём страницу
        local page = Instance.new("ScrollingFrame")
        page.Name = name
        page.Size = UDim2.new(1, -20, 1, -20)
        page.Position = UDim2.new(0, 10, 0, 10)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 6
        page.ScrollBarImageColor3 = SiriusUILib.Colors.Foreground
        page.ScrollBarImageTransparency = 0.7
        page.Parent = pagesContainer
        page.Visible = false

        local uiList = Instance.new("UIListLayout")
        uiList.Padding = UDim.new(0, 10)
        uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        uiList.Parent = page

        -- Создаём кнопку на топбаре
        local button = createTopButton(name, function()
            if activePage then
                local prevPage = pagesContainer:FindFirstChild(activePage)
                if prevPage then prevPage.Visible = false end
            end
            page.Visible = true
        end)

        table.insert(pages, {Name = name, Page = page, Button = button})

        -- Активируем первую страницу
        if #pages == 1 then
            page.Visible = true
            activePage = name
            createTween(button, {BackgroundTransparency = 0.3, TextColor3 = SiriusUILib.Colors.GradientStart}, 0.2)
        end

        local tabApi = {}

        function tabApi:CreateButton(text, callback)
            local btn = Instance.new("TextButton")
            btn.Text = text
            btn.TextColor3 = SiriusUILib.Colors.Foreground
            btn.TextSize = 14
            btn.Font = Enum.Font.Gotham
            btn.Size = UDim2.new(0, 220, 0, 38)
            btn.BackgroundColor3 = SiriusUILib.Colors.Background
            btn.BackgroundTransparency = 0.75
            btn.BorderSizePixel = 0
            btn.Parent = page

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = btn

            local btnStroke = Instance.new("UIStroke")
            btnStroke.Color = SiriusUILib.Colors.Foreground
            btnStroke.Thickness = 0.8
            btnStroke.Transparency = 0.8
            btnStroke.Parent = btn

            btn.MouseEnter:Connect(function()
                createTween(btn, {BackgroundTransparency = 0.5}, 0.2)
                createTween(btnStroke, {Transparency = 0.5}, 0.2)
            end)
            btn.MouseLeave:Connect(function()
                createTween(btn, {BackgroundTransparency = 0.75}, 0.2)
                createTween(btnStroke, {Transparency = 0.8}, 0.2)
            end)

            btn.MouseButton1Click:Connect(function()
                playSound(gui)
                if callback then callback() end
            end)

            return btn
        end

        function tabApi:CreateToggle(text, default, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 220, 0, 38)
            frame.BackgroundTransparency = 1
            frame.Parent = page

            local label = Instance.new("TextLabel")
            label.Text = text
            label.TextColor3 = SiriusUILib.Colors.Foreground
            label.TextSize = 13
            label.Font = Enum.Font.Gotham
            label.Size = UDim2.new(0, 160, 1, 0)
            label.Position = UDim2.new(0, 5, 0, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.BackgroundTransparency = 1
            label.Parent = frame

            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Text = default and "ON" or "OFF"
            toggleBtn.TextColor3 = SiriusUILib.Colors.Background
            toggleBtn.TextSize = 12
            toggleBtn.Font = Enum.Font.GothamBold
            toggleBtn.Size = UDim2.new(0, 45, 0, 28)
            toggleBtn.Position = UDim2.new(1, -50, 0.5, -14)
            toggleBtn.BackgroundColor3 = default and SiriusUILib.Colors.Foreground or Color3.fromRGB(60, 60, 60)
            toggleBtn.BorderSizePixel = 0
            toggleBtn.Parent = frame

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = toggleBtn

            local state = default
            toggleBtn.MouseButton1Click:Connect(function()
                state = not state
                toggleBtn.Text = state and "ON" or "OFF"
                toggleBtn.BackgroundColor3 = state and SiriusUILib.Colors.Foreground or Color3.fromRGB(60, 60, 60)
                toggleBtn.TextColor3 = state and SiriusUILib.Colors.Background or SiriusUILib.Colors.Foreground
                playSound(gui)
                if callback then callback(state) end
            end)

            return toggleBtn
        end

        function tabApi:CreateSlider(text, min, max, default, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 220, 0, 65)
            frame.BackgroundTransparency = 1
            frame.Parent = page

            local label = Instance.new("TextLabel")
            label.Text = text
            label.TextColor3 = SiriusUILib.Colors.Foreground
            label.TextSize = 12
            label.Font = Enum.Font.Gotham
            label.Size = UDim2.new(1, 0, 0, 20)
            label.BackgroundTransparency = 1
            label.Parent = frame

            local valueLabel = Instance.new("TextLabel")
            valueLabel.Text = tostring(default)
            valueLabel.TextColor3 = SiriusUILib.Colors.Foreground
            valueLabel.TextSize = 12
            valueLabel.Font = Enum.Font.GothamBold
            valueLabel.Size = UDim2.new(0, 40, 0, 20)
            valueLabel.Position = UDim2.new(1, -40, 0, 0)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.BackgroundTransparency = 1
            valueLabel.Parent = frame

            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(1, 0, 0, 4)
            barBg.Position = UDim2.new(0, 0, 0, 30)
            barBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            barBg.BorderSizePixel = 0
            barBg.Parent = frame

            local barFill = Instance.new("Frame")
            barFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            barFill.BackgroundColor3 = SiriusUILib.Colors.Foreground
            barFill.BorderSizePixel = 0
            barFill.Parent = barBg

            local sliderBtn = Instance.new("TextButton")
            sliderBtn.Text = ""
            sliderBtn.Size = UDim2.new(0, 14, 0, 14)
            sliderBtn.Position = UDim2.new((default - min) / (max - min), -7, 0, -5)
            sliderBtn.BackgroundColor3 = SiriusUILib.Colors.Foreground
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
                sliderBtn.Position = UDim2.new(relativeX, -7, 0, -5)
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
        end

        function tabApi:CreateInput(placeholder, callback)
            local inputBox = Instance.new("TextBox")
            inputBox.PlaceholderText = placeholder
            inputBox.Text = ""
            inputBox.TextColor3 = SiriusUILib.Colors.Foreground
            inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
            inputBox.TextSize = 13
            inputBox.Font = Enum.Font.Gotham
            inputBox.Size = UDim2.new(0, 220, 0, 38)
            inputBox.BackgroundColor3 = SiriusUILib.Colors.Background
            inputBox.BackgroundTransparency = 0.75
            inputBox.BorderSizePixel = 0
            inputBox.Parent = page

            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, 8)
            inputCorner.Parent = inputBox

            local inputStroke = Instance.new("UIStroke")
            inputStroke.Color = SiriusUILib.Colors.Foreground
            inputStroke.Thickness = 0.8
            inputStroke.Transparency = 0.8
            inputStroke.Parent = inputBox

            inputBox.FocusLost:Connect(function(enterPressed)
                if enterPressed and callback then
                    callback(inputBox.Text)
                    playSound(gui)
                end
            end)

            return inputBox
        end

        function tabApi:CreateLabel(text)
            local label = Instance.new("TextLabel")
            label.Text = text
            label.TextColor3 = SiriusUILib.Colors.Foreground
            label.TextSize = 12
            label.Font = Enum.Font.Gotham
            label.Size = UDim2.new(0, 220, 0, 25)
            label.BackgroundTransparency = 1
            label.Parent = page
            return label
        end

        function tabApi:CreateSeparator()
            local sep = Instance.new("Frame")
            sep.Size = UDim2.new(0, 220, 0, 1)
            sep.BackgroundColor3 = SiriusUILib.Colors.Foreground
            sep.BackgroundTransparency = 0.8
            sep.BorderSizePixel = 0
            sep.Parent = page
            return sep
        end

        return tabApi
    end

    function self:Notify(title, description, duration)
        duration = duration or SiriusUILib.Settings.NotificationDuration

        local notifFrame = Instance.new("Frame")
        notifFrame.Size = UDim2.new(0, 320, 0, 65)
        notifFrame.Position = UDim2.new(1, 20, 1, -85)
        notifFrame.AnchorPoint = Vector2.new(1, 1)
        notifFrame.BackgroundColor3 = SiriusUILib.Colors.Background
        notifFrame.BackgroundTransparency = 0.15
        notifFrame.BorderSizePixel = 0
        notifFrame.Parent = gui

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
        titleLabel.Position = UDim2.new(0, 12, 0, 8)
        titleLabel.Size = UDim2.new(1, -24, 0, 20)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.BackgroundTransparency = 1
        titleLabel.Parent = notifFrame

        local descLabel = Instance.new("TextLabel")
        descLabel.Text = description or ""
        descLabel.TextColor3 = SiriusUILib.Colors.Foreground
        descLabel.TextSize = 12
        descLabel.Font = Enum.Font.Gotham
        descLabel.Position = UDim2.new(0, 12, 0, 30)
        descLabel.Size = UDim2.new(1, -24, 0, 30)
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.BackgroundTransparency = 1
        descLabel.Parent = notifFrame

        notifFrame.Position = UDim2.new(1, 20, 1, -85)
        createTween(notifFrame, {Position = UDim2.new(1, -340, 1, -85)}, 0.4)
        playSound(gui)

        task.delay(duration, function()
            createTween(notifFrame, {Position = UDim2.new(1, 20, 1, -85), BackgroundTransparency = 1}, 0.4)
            task.wait(0.5)
            notifFrame:Destroy()
        end)

        return notifFrame
    end

    function self:Show()
        gui.Enabled = true
    end

    function self:Hide()
        gui.Enabled = false
    end

    function self:Toggle()
        gui.Enabled = not gui.Enabled
    end

    -- Делаем топбар перетаскиваемым
    makeDraggable(topBar)

    mainGUI = gui
    return self
end

function SiriusUILib:Notify(title, description, duration)
    if not mainGUI then return end
    duration = duration or SiriusUILib.Settings.NotificationDuration

    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, 320, 0, 65)
    notifFrame.Position = UDim2.new(1, 20, 1, -85)
    notifFrame.AnchorPoint = Vector2.new(1, 1)
    notifFrame.BackgroundColor3 = SiriusUILib.Colors.Background
    notifFrame.BackgroundTransparency = 0.15
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
    titleLabel.Position = UDim2.new(0, 12, 0, 8)
    titleLabel.Size = UDim2.new(1, -24, 0, 20)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = notifFrame

    local descLabel = Instance.new("TextLabel")
    descLabel.Text = description or ""
    descLabel.TextColor3 = SiriusUILib.Colors.Foreground
    descLabel.TextSize = 12
    descLabel.Font = Enum.Font.Gotham
    descLabel.Position = UDim2.new(0, 12, 0, 30)
    descLabel.Size = UDim2.new(1, -24, 0, 30)
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.BackgroundTransparency = 1
    descLabel.Parent = notifFrame

    createTween(notifFrame, {Position = UDim2.new(1, -340, 1, -85)}, 0.4)
    playSound(mainGUI)

    task.delay(duration, function()
        createTween(notifFrame, {Position = UDim2.new(1, 20, 1, -85), BackgroundTransparency = 1}, 0.4)
        task.wait(0.5)
        notifFrame:Destroy()
    end)

    return notifFrame
end

function SiriusUILib:SetTheme(colors)
    for k, v in pairs(colors) do
        if SiriusUILib.Colors[k] then
            SiriusUILib.Colors[k] = v
        end
    end
end

return SiriusUILib
