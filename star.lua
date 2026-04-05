-- Загружаем библиотеку
local SiriusUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/eeetestcgecre/rock/refs/heads/main/star.lua"))()

-- Создаём окно
local mainWindow = SiriusUI:CreateWindow("SIRIUS MENU", UDim2.new(0, 550, 0, 450))

-- Создаём вкладки (кнопки появятся на верхней панели)
local homeTab = mainWindow:CreateTab("Главная")
local scriptsTab = mainWindow:CreateTab("Скрипты")
local settingsTab = mainWindow:CreateTab("Настройки")

-- Главная вкладка
homeTab:CreateButton("Тестовая кнопка", function()
    SiriusUI:Notify("Успех", "Кнопка сработала!", 2)
    print("Кнопка нажата!")
end)

homeTab:CreateToggle("Включить режим", false, function(state)
    print("Режим:", state)
    SiriusUI:Notify("Режим", state and "Включён" or "Выключен", 2)
end)

homeTab:CreateSlider("Скорость игрока", 16, 300, 16, function(value)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = value
    end
end)

homeTab:CreateSeparator()
homeTab:CreateLabel("Добро пожаловать в Sirius UI!")

-- Вкладка скриптов
scriptsTab:CreateInput("Введите команду", function(text)
    print("Введено:", text)
    SiriusUI:Notify("Ввод", "Вы ввели: " .. text, 3)
end)

scriptsTab:CreateButton("Выполнить скрипт", function()
    SiriusUI:Notify("Скрипт", "Скрипт выполняется...", 2)
end)

-- Вкладка настроек
settingsTab:CreateToggle("Звуки UI", true, function(state)
    SiriusUI.Settings.EnableSounds = state
end)

settingsTab:CreateSlider("Длительность уведомлений", 1, 10, 3, function(value)
    SiriusUI.Settings.NotificationDuration = value
end)

-- Показываем окно
mainWindow:Show()

-- Хоткей Insert
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        mainWindow:Toggle()
    end
end)

-- Приветствие
SiriusUI:Notify("Sirius UI", "Загружено! Нажми Insert", 3)
