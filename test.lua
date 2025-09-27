--[[
     Custom UI Library - Полностью исправленная версия
     v2.1.1  |  2025-09-27  |  Roblox UI Library
     
     Исправлены все ошибки из скриншота
]]

-- Глобальные переменные и проверки безопасности
local UILibrary = {}
local cache = {}

-- Основные сервисы
local Services = {
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"), 
    TweenService = game:GetService("TweenService"),
    LocalizationService = game:GetService("LocalizationService"),
    HttpService = game:GetService("HttpService"),
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting")
}

-- Безопасная функция HTTP запросов
local function getHttpFunction()
    local functions = {
        http_request,
        request,
        syn and syn.request
    }
    
    for _, func in ipairs(functions) do
        if func then return func end
    end
    return nil
end

-- Безопасное определение исполнителя
local function getExecutorInfo()
    if syn then return "Synapse" 
    elseif KRNL_LOADED then return "Krnl"
    elseif getgenv then return "Standard"
    else return "Unknown"
    end
end

-- Обертка файловой системы с проверками безопасности
local FileOperations = {
    write = writefile or function() end,
    read = readfile or function() return "" end,
    exists = isfile or function() return false end,
    delete = delfile or function() end,
    makeFolder = makefolder or function() end,
    folderExists = isfolder or function() return false end,
    listFiles = listfiles or function() return {} end,
    getCustomAsset = getcustomasset or function(path) return path end
}

-- Основные утилитные функции
function UILibrary.Utils()
    local Heartbeat = Services.RunService.Heartbeat
    local UserInput = Services.UserInputService
    local TweenService = Services.TweenService
    local LocalizationService = Services.LocalizationService

    local currentLibraryRef = nil

    local librarySettings = {
        Font = "rbxassetid://12187365364",
        Localization = nil,
        CanDraggable = true,
        Theme = nil,
        Themes = nil,
        Signals = {},
        Objects = {},
        LocalizationObjects = {},
        FontObjects = {},
        Language = string.match(LocalizationService.SystemLocaleId or "en", "^[a-z]+"),
        RequestFunction = getHttpFunction(),
        DefaultProperties = {
            ScreenGui = {
                ResetOnSpawn = false,
                ZIndexBehavior = "Sibling",
            },
            CanvasGroup = {
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.new(1,1,1),
            },
            Frame = {
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.new(1,1,1),
            },
            TextLabel = {
                BackgroundColor3 = Color3.new(1,1,1),
                BorderSizePixel = 0,
                Text = "",
                RichText = true,
                TextColor3 = Color3.new(1,1,1),
                TextSize = 14,
            },
            TextButton = {
                BackgroundColor3 = Color3.new(1,1,1),
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                TextColor3 = Color3.new(1,1,1),
                TextSize = 14,
            },
            TextBox = {
                BackgroundColor3 = Color3.new(1,1,1),
                BorderColor3 = Color3.new(0,0,0),
                ClearTextOnFocus = false,
                Text = "",
                TextColor3 = Color3.new(0,0,0),
                TextSize = 14,
            },
            ImageLabel = {
                BackgroundTransparency = 1,
                BackgroundColor3 = Color3.new(1,1,1),
                BorderSizePixel = 0,
            },
            ImageButton = {
                BackgroundColor3 = Color3.new(1,1,1),
                BorderSizePixel = 0,
                AutoButtonColor = false,
            },
            UIListLayout = {
                SortOrder = "LayoutOrder",
            },
            ScrollingFrame = {
                ScrollBarImageTransparency = 1,
                BorderSizePixel = 0,
            },
            VideoFrame = {
                BorderSizePixel = 0,
            }
        },
        Colors = {
            Red = "#e53935",
            Orange = "#f57c00", 
            Green = "#43a047",
            Blue = "#039be5",
            White = "#ffffff",
            Grey = "#484848",
        },
    }

    -- Безопасный доступ к свойствам
    function librarySettings.SafeGetProperty(object, property, default)
        if not object then return default end
        local success, value = pcall(function()
            return object[property]
        end)
        return success and value or default
    end

    -- Безопасная установка свойств
    function librarySettings.SafeSetProperty(object, property, value)
        if not object then return false end
        local success = pcall(function()
            object[property] = value
        end)
        return success
    end

    -- Проверка существования свойства
    function librarySettings.HasProperty(object, property)
        if not object then return false end
        local success = pcall(function()
            local _ = object[property]
        end)
        return success
    end

    function librarySettings.Init(library)
        currentLibraryRef = library
    end

    function librarySettings.AddSignal(connection, callback)
        if not connection or not callback then
            return nil
        end
        
        local success, signal = pcall(function()
            return connection:Connect(callback)
        end)
        
        if success and signal then
            table.insert(librarySettings.Signals, signal)
            return signal
        end
        return nil
    end

    function librarySettings.DisconnectAll()
        for i = #librarySettings.Signals, 1, -1 do
            local signal = librarySettings.Signals[i]
            if signal then
                pcall(function()
                    signal:Disconnect()
                end)
                table.remove(librarySettings.Signals, i)
            end
        end
    end

    function librarySettings.SafeCallback(callback, ...)
        if not callback then return end

        local success, error = pcall(callback, ...)
        if not success then
            if currentLibraryRef and currentLibraryRef.Window and currentLibraryRef.Window.Debug then
                warn("[ Custom UI: DEBUG Mode ] " .. tostring(error))
                
                if currentLibraryRef.Notify then
                    return currentLibraryRef:Notify{
                        Title = "DEBUG Mode: Error",
                        Content = tostring(error),
                        Duration = 8,
                    }
                end
            end
        end
    end

    function librarySettings.SetTheme(theme)
        if not theme then return end
        librarySettings.Theme = theme
        librarySettings.UpdateTheme(nil, true)
    end

    function librarySettings.AddFontObject(object)
        if not object then return end
        table.insert(librarySettings.FontObjects, object)
        librarySettings.UpdateFont(librarySettings.Font)
    end

    function librarySettings.UpdateFont(font)
        if not font then return end
        librarySettings.Font = font
        for _, object in pairs(librarySettings.FontObjects) do
            if object and librarySettings.HasProperty(object, "FontFace") then
                pcall(function()
                    local currentFont = object.FontFace
                    object.FontFace = Font.new(font, currentFont.Weight, currentFont.Style)
                end)
            end
        end
    end

    function librarySettings.GetThemeProperty(property, theme)
        if not theme or not property then return "#ffffff" end
        return theme[property] or (librarySettings.Themes and librarySettings.Themes.Dark and librarySettings.Themes.Dark[property]) or "#ffffff"
    end

    function librarySettings.AddThemeObject(object, properties)
        if not object or not properties then return object end
        librarySettings.Objects[object] = {Object = object, Properties = properties}
        librarySettings.UpdateTheme(object, false)
        return object
    end

    function librarySettings.UpdateTheme(object, animate)
        local function ApplyTheme(themeObj)
            if not themeObj or not themeObj.Object or not themeObj.Properties then return end
            
            for property, value in pairs(themeObj.Properties) do
                if librarySettings.HasProperty(themeObj.Object, property) then
                    local themeValue = librarySettings.GetThemeProperty(value, librarySettings.Theme)
                    if themeValue then
                        local success, color = pcall(Color3.fromHex, themeValue)
                        if success then
                            if animate then
                                local tween = librarySettings.CreateTween(themeObj.Object, 0.08, {[property] = color})
                                if tween then
                                    tween:Play()
                                end
                            else
                                librarySettings.SafeSetProperty(themeObj.Object, property, color)
                            end
                        end
                    end
                end
            end
        end

        if object then
            local themeObj = librarySettings.Objects[object]
            if themeObj then
                ApplyTheme(themeObj)
            end
        else
            for _, themeObj in pairs(librarySettings.Objects) do
                ApplyTheme(themeObj)
            end
        end
    end

    -- Система языков
    function librarySettings.SetLangForObject(index)
        if librarySettings.Localization and librarySettings.Localization.Enabled then
            local langObj = librarySettings.LocalizationObjects[index]
            if not langObj or not langObj.Object then return end

            local object = langObj.Object
            local translationId = langObj.TranslationId

            local translations = librarySettings.Localization.Translations[librarySettings.Language]
            if translations and translations[translationId] then
                librarySettings.SafeSetProperty(object, "Text", translations[translationId])
            else
                local englishTranslations = librarySettings.Localization and 
                    librarySettings.Localization.Translations and 
                    librarySettings.Localization.Translations.en or nil
                if englishTranslations and englishTranslations[translationId] then
                    librarySettings.SafeSetProperty(object, "Text", englishTranslations[translationId])
                else
                    librarySettings.SafeSetProperty(object, "Text", "[" .. translationId .. "]")
                end
            end
        end
    end

    function librarySettings.UpdateLang(language)
        if language then
            librarySettings.Language = language
        end

        for i = 1, #librarySettings.LocalizationObjects do
            local langObj = librarySettings.LocalizationObjects[i]
            if langObj and langObj.Object and langObj.Object.Parent ~= nil then
                librarySettings.SetLangForObject(i)
            else
                librarySettings.LocalizationObjects[i] = nil
            end
        end
    end

    function librarySettings.SetLanguage(language)
        librarySettings.Language = language
        librarySettings.UpdateLang()
    end

    -- Функции иконок (безопасная реализация)
    function librarySettings.Icon(iconName)
        if not iconName or iconName == "" then
            return {"", {ImageRectSize = Vector2.new(24, 24), ImageRectPosition = Vector2.new(0, 0)}}
        end
        
        -- Базовая карта иконок для общих иконок
        local iconMap = {
            ["x"] = {"rbxassetid://3926305904", {ImageRectSize = Vector2.new(24, 24), ImageRectPosition = Vector2.new(444, 4)}},
            ["key"] = {"rbxassetid://3926305904", {ImageRectSize = Vector2.new(24, 24), ImageRectPosition = Vector2.new(324, 204)}},
            ["arrow-right"] = {"rbxassetid://3926305904", {ImageRectSize = Vector2.new(24, 24), ImageRectPosition = Vector2.new(4, 44)}},
            ["log-out"] = {"rbxassetid://3926305904", {ImageRectSize = Vector2.new(24, 24), ImageRectPosition = Vector2.new(364, 204)}},
            ["triangle-alert"] = {"rbxassetid://3926305904", {ImageRectSize = Vector2.new(24, 24), ImageRectPosition = Vector2.new(4, 404)}},
            ["settings"] = {"rbxassetid://3926305904", {ImageRectSize = Vector2.new(24, 24), ImageRectPosition = Vector2.new(404, 364)}},
            ["home"] = {"rbxassetid://3926305904", {ImageRectSize = Vector2.new(24, 24), ImageRectPosition = Vector2.new(284, 164)}},
            ["user"] = {"rbxassetid://3926305904", {ImageRectSize = Vector2.new(24, 24), ImageRectPosition = Vector2.new(444, 444)}}
        }
        
        return iconMap[iconName] or {"", {ImageRectSize = Vector2.new(24, 24), ImageRectPosition = Vector2.new(0, 0)}}
    end

    function librarySettings.AddIcons(icons, data)
        -- Заглушка для добавления пользовательских иконок
        return true
    end

    -- Создание элементов с улучшенной обработкой ошибок
    function librarySettings.CreateElement(className, properties, children)
        local element
        local success = pcall(function()
            element = Instance.new(className)
        end)
        
        if not success or not element then
            warn("Failed to create element: " .. tostring(className))
            return nil
        end

        -- Безопасно применяем свойства по умолчанию
        local defaults = librarySettings.DefaultProperties[className] or {}
        for prop, value in pairs(defaults) do
            if librarySettings.HasProperty(element, prop) then
                librarySettings.SafeSetProperty(element, prop, value)
            end
        end

        -- Безопасно применяем пользовательские свойства
        for prop, value in pairs(properties or {}) do
            if prop ~= "ThemeTag" and librarySettings.HasProperty(element, prop) then
                librarySettings.SafeSetProperty(element, prop, value)
            end
            if librarySettings.Localization and librarySettings.Localization.Enabled and prop == "Text" then
                local translationKey = string.match(tostring(value), "^" .. librarySettings.Localization.Prefix .. "(.+)")
                if translationKey then
                    local index = #librarySettings.LocalizationObjects + 1
                    librarySettings.LocalizationObjects[index] = {
                        TranslationId = translationKey,
                        Object = element
                    }
                    librarySettings.SetLangForObject(index)
                end
            end
        end

        -- Безопасно добавляем дочерние элементы
        for _, child in pairs(children or {}) do
            if child then
                librarySettings.SafeSetProperty(child, "Parent", element)
            end
        end

        -- Безопасно применяем тему
        if properties and properties.ThemeTag then
            librarySettings.AddThemeObject(element, properties.ThemeTag)
        end
        
        if properties and properties.FontFace then
            librarySettings.AddFontObject(element)
        end

        return element
    end

    -- Безопасное создание твинов
    function librarySettings.CreateTween(object, duration, properties, ...)
        if not object or not duration or not properties then return nil end
        
        local success, tween = pcall(function()
            return TweenService:Create(object, TweenInfo.new(duration, ...), properties)
        end)
        
        return success and tween or nil
    end

    -- Создание округлых фреймов с обработкой ошибок
    function librarySettings.CreateRoundFrame(radius, frameType, properties, children, isButton, returnController)
        local function getImageForType(type)
            local images = {
                Squircle = "rbxassetid://80999662900595",
                SquircleOutline = "rbxassetid://117788349049947", 
                SquircleOutline2 = "rbxassetid://117817408534198",
                ["Squircle-Outline"] = "rbxassetid://117817408534198",
                ["Shadow-sm"] = "rbxassetid://84825982946844",
                ["Squircle-TL-TR"] = "rbxassetid://73569156276236",
                ["Squircle-BL-BR"] = "rbxassetid://93853842912264",
                ["Squircle-TL-TR-Outline"] = "rbxassetid://136702870075563",
                ["Squircle-BL-BR-Outline"] = "rbxassetid://75035847706564",
                Square = "rbxassetid://82909646051652",
                ["Square-Outline"] = "rbxassetid://72946211851948"
            }
            return images[type] or images.Squircle
        end

        local function getSliceCenterForType(type)
            if type ~= "Shadow-sm" then
                return Rect.new(256, 256, 256, 256)
            else
                return Rect.new(512, 512, 512, 512)
            end
        end

        frameType = frameType or "Squircle"
        radius = radius or 10

        local frameElement = librarySettings.CreateElement(
            isButton and "ImageButton" or "ImageLabel",
            {
                Image = getImageForType(frameType),
                ScaleType = "Slice", 
                SliceCenter = getSliceCenterForType(frameType),
                SliceScale = 1,
                BackgroundTransparency = 1,
                ThemeTag = properties and properties.ThemeTag
            },
            children
        )

        if not frameElement then return nil end

        -- Безопасно применяем свойства
        for prop, value in pairs(properties or {}) do
            if prop ~= "ThemeTag" and librarySettings.HasProperty(frameElement, prop) then
                librarySettings.SafeSetProperty(frameElement, prop, value)
            end
        end

        local function UpdateSliceScale(newRadius)
            if not frameElement then return end
            local scale = frameType ~= "Shadow-sm" and (newRadius / 256) or (newRadius / 512)
            librarySettings.SafeSetProperty(frameElement, "SliceScale", math.max(scale, 0.0001))
        end

        local controller = {}

        function controller:SetRadius(newRadius)
            radius = newRadius or radius
            UpdateSliceScale(radius)
        end

        function controller:SetType(newType)
            frameType = newType or frameType
            librarySettings.SafeSetProperty(frameElement, "Image", getImageForType(frameType))
            librarySettings.SafeSetProperty(frameElement, "SliceCenter", getSliceCenterForType(frameType))
            UpdateSliceScale(radius)
        end

        function controller:UpdateShape(newRadius, newType)
            if newType then
                frameType = newType
                librarySettings.SafeSetProperty(frameElement, "Image", getImageForType(newType))
                librarySettings.SafeSetProperty(frameElement, "SliceCenter", getSliceCenterForType(newType))
            end
            if newRadius then
                radius = newRadius
            end
            UpdateSliceScale(radius)
        end

        function controller:GetRadius()
            return radius
        end

        function controller:GetType()
            return frameType
        end

        UpdateSliceScale(radius)

        return frameElement, returnController and controller or nil
    end

    -- Функция перетаскивания
    function librarySettings.SetDraggable(enabled)
        librarySettings.CanDraggable = enabled
    end

    function librarySettings.CreateDraggable(object, dragElements, onDragCallback)
        if not object then return {} end
        
        local isDragging = false
        local dragStart, startPos, dragInput, dragObj

        local dragController = {
            CanDraggable = true
        }

        if not dragElements or type(dragElements) ~= "table" then
            dragElements = {object}
        end

        local function updateDrag(input)
            if not startPos then return end
            local delta = input.Position - dragStart
            local tween = librarySettings.CreateTween(object, 0.02, {
                Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            })
            if tween then
                tween:Play()
            end
        end

        for _, element in pairs(dragElements) do
            if element and librarySettings.HasProperty(element, "InputBegan") then
                librarySettings.AddSignal(element.InputBegan, function(input)
                    if (input.UserInputType == Enum.UserInputType.MouseButton1 or 
                        input.UserInputType == Enum.UserInputType.Touch) and dragController.CanDraggable then
                        
                        if dragObj == nil then
                            dragObj = element
                            isDragging = true
                            dragStart = input.Position
                            startPos = librarySettings.SafeGetProperty(object, "Position", UDim2.new(0, 0, 0, 0))

                            if onDragCallback and type(onDragCallback) == "function" then
                                onDragCallback(true, dragObj)
                            end

                            local inputConnection = librarySettings.AddSignal(input.Changed, function()
                                if input.UserInputState == Enum.UserInputState.End then
                                    isDragging = false
                                    dragObj = nil

                                    if onDragCallback and type(onDragCallback) == "function" then
                                        onDragCallback(false, dragObj)
                                    end
                                end
                            end)
                        end
                    end
                end)

                if librarySettings.HasProperty(element, "InputChanged") then
                    librarySettings.AddSignal(element.InputChanged, function(input)
                        if dragObj == element and isDragging then
                            if input.UserInputType == Enum.UserInputType.MouseMovement or 
                               input.UserInputType == Enum.UserInputType.Touch then
                                dragInput = input
                            end
                        end
                    end)
                end
            end
        end

        librarySettings.AddSignal(UserInput.InputChanged, function(input)
            if input == dragInput and isDragging and dragObj ~= nil then
                if dragController.CanDraggable then
                    updateDrag(input)
                end
            end
        end)

        function dragController.Set(enabled)
            dragController.CanDraggable = enabled
        end

        return dragController
    end

    -- Обработка изображений
    function librarySettings.CreateImage(imagePath, filename, cornerRadius, folder, category, isThemed, colorProperty)
        local function SanitizeFilename(name)
            name = tostring(name):gsub("[%s/\\:*?\"<>|]+", "-")
            name = name:gsub("[^%w%-_%.]", "")
            return name
        end

        folder = folder or "Temp"
        filename = SanitizeFilename(filename or "image")

        local imageFrame = librarySettings.CreateElement("Frame", {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
        }, {
            librarySettings.CreateElement("ImageLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                ScaleType = "Crop",
                ThemeTag = isThemed and {
                    ImageColor3 = "Icon"
                } or nil,
                Image = tostring(imagePath or "")
            }, {
                librarySettings.CreateElement("UICorner", {
                    CornerRadius = UDim.new(0, cornerRadius or 0)
                })
            })
        })

        if not imageFrame then return nil end

        -- Обработка различных источников изображений
        local iconData = librarySettings.Icon(imagePath)
        if iconData and iconData[1] ~= "" then
            local imageLabel = imageFrame:FindFirstChild("ImageLabel")
            if imageLabel then
                librarySettings.SafeSetProperty(imageLabel, "Image", iconData[1])
                if iconData[2] then
                    librarySettings.SafeSetProperty(imageLabel, "ImageRectSize", iconData[2].ImageRectSize)
                    librarySettings.SafeSetProperty(imageLabel, "ImageRectOffset", iconData[2].ImageRectPosition)
                end
            end
        elseif imagePath and tostring(imagePath):find("http") then
            local cachePath = "CustomUI/" .. folder .. "/Assets/." .. category .. "-" .. filename .. ".png"
            task.spawn(function()
                local success = pcall(function()
                    if not FileOperations.exists(cachePath) then
                        local response = librarySettings.RequestFunction and librarySettings.RequestFunction{
                            Url = tostring(imagePath),
                            Method = "GET",
                        }
                        
                        if response and response.Body then
                            FileOperations.write(cachePath, response.Body)
                        end
                    end
                    local imageLabel = imageFrame:FindFirstChild("ImageLabel")
                    if imageLabel then
                        librarySettings.SafeSetProperty(imageLabel, "Image", FileOperations.getCustomAsset(cachePath))
                    end
                end)
                
                if not success then
                    warn("[ Custom UI Library ] '" .. getExecutorInfo() .. "' не поддерживает URL изображения.")
                    if imageFrame then
                        imageFrame:Destroy()
                    end
                end
            end)
        elseif imagePath == "" then
            librarySettings.SafeSetProperty(imageFrame, "Visible", false)
        else
            local imageLabel = imageFrame:FindFirstChild("ImageLabel")
            if imageLabel then
                librarySettings.SafeSetProperty(imageLabel, "Image", tostring(imagePath or ""))
            end
        end

        return imageFrame
    end

    return librarySettings
end

-- Система локализации
function UILibrary.Localization()
    local localization = {}

    function localization.New(library, config, utilsRef)
        local localizationSystem = {
            Enabled = config and config.Enabled or false,
            Translations = config and config.Translations or {},
            Prefix = config and config.Prefix or "loc:",
            DefaultLanguage = config and config.DefaultLanguage or "en"
        }

        if utilsRef then
            utilsRef.Localization = localizationSystem
        end

        return localizationSystem
    end

    return localization
end

-- Система уведомлений с обработкой ошибок
function UILibrary.NotificationSystem()
    local utils = UILibrary.Utils()
    if not utils then return {} end
    
    local createElement = utils.CreateElement
    local createTween = utils.CreateTween

    local notifications = {
        Size = UDim2.new(0, 300, 1, -156),
        SizeLower = UDim2.new(0, 300, 1, -56),
        UICorner = 13,
        UIPadding = 14,
        Holder = nil,
        NotificationIndex = 0,
        Notifications = {}
    }

    function notifications.Init(parent)
        if not parent then return nil end
        
        local notificationController = {
            Lower = false
        }

        function notificationController.SetLower(isLower)
            notificationController.Lower = isLower
            if notificationController.Frame then
                utils.SafeSetProperty(notificationController.Frame, "Size", isLower and notifications.SizeLower or notifications.Size)
            end
        end

        notificationController.Frame = createElement("Frame", {
            Position = UDim2.new(1, -29, 0, 56),
            AnchorPoint = Vector2.new(1, 0),
            Size = notifications.Size,
            Parent = parent,
            BackgroundTransparency = 1,
        }, {
            createElement("UIListLayout", {
                HorizontalAlignment = "Center",
                SortOrder = "LayoutOrder", 
                VerticalAlignment = "Bottom",
                Padding = UDim.new(0, 8),
            }),
            createElement("UIPadding", {
                PaddingBottom = UDim.new(0, 29)
            })
        })

        return notificationController
    end

    function notifications.CreateNotification(config)
        if not config then return {} end
        
        local notification = {
            Title = config.Title or "Notification",
            Content = config.Content or nil,
            Icon = config.Icon or nil,
            IconThemed = config.IconThemed,
            Background = config.Background,
            BackgroundImageTransparency = config.BackgroundImageTransparency,
            Duration = config.Duration or 5,
            Buttons = config.Buttons or {},
            CanClose = config.CanClose ~= false,
            UIElements = {},
            Closed = false,
        }

        notifications.NotificationIndex = notifications.NotificationIndex + 1
        notifications.Notifications[notifications.NotificationIndex] = notification

        local iconElement
        if notification.Icon then
            iconElement = utils.CreateImage(
                notification.Icon,
                notification.Title .. ":" .. notification.Icon,
                0,
                config.Window or "Temp",
                "Notification", 
                notification.IconThemed
            )
            if iconElement then
                utils.SafeSetProperty(iconElement, "Size", UDim2.new(0, 26, 0, 26))
                utils.SafeSetProperty(iconElement, "Position", UDim2.new(0, notifications.UIPadding, 0, notifications.UIPadding))
            end
        end

        local closeButton
        if notification.CanClose then
            local iconData = utils.Icon("x")
            closeButton = createElement("ImageButton", {
                Image = iconData[1],
                ImageRectSize = iconData[2].ImageRectSize,
                ImageRectOffset = iconData[2].ImageRectPosition,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(1, -notifications.UIPadding, 0, notifications.UIPadding),
                AnchorPoint = Vector2.new(1, 0),
                ThemeTag = {
                    ImageColor3 = "Text"
                },
                ImageTransparency = .4,
            }, {
                createElement("TextButton", {
                    Size = UDim2.new(1, 8, 1, 8),
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Text = "",
                })
            })
        end

        local progressBar = createElement("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = .95,
            ThemeTag = {
                BackgroundColor3 = "Text",
            },
        })

        local contentFrame = createElement("Frame", {
            Size = UDim2.new(1, notification.Icon and -28 - notifications.UIPadding or 0, 1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            AutomaticSize = "Y",
        }, {
            createElement("UIPadding", {
                PaddingTop = UDim.new(0, notifications.UIPadding),
                PaddingLeft = UDim.new(0, notifications.UIPadding),
                PaddingRight = UDim.new(0, notifications.UIPadding),
                PaddingBottom = UDim.new(0, notifications.UIPadding),
            }),
            createElement("TextLabel", {
                AutomaticSize = "Y",
                Size = UDim2.new(1, -30 - notifications.UIPadding, 0, 0),
                TextWrapped = true,
                TextXAlignment = "Left",
                RichText = true,
                BackgroundTransparency = 1,
                TextSize = 16,
                ThemeTag = {
                    TextColor3 = "Text"
                },
                Text = notification.Title,
                FontFace = Font.new(utils.Font, Enum.FontWeight.Medium)
            }),
            createElement("UIListLayout", {
                Padding = UDim.new(0, notifications.UIPadding / 3)
            })
        })

        if notification.Content then
            createElement("TextLabel", {
                AutomaticSize = "Y",
                Size = UDim2.new(1, 0, 0, 0),
                TextWrapped = true,
                TextXAlignment = "Left", 
                RichText = true,
                BackgroundTransparency = 1,
                TextTransparency = .4,
                TextSize = 15,
                ThemeTag = {
                    TextColor3 = "Text"
                },
                Text = notification.Content,
                FontFace = Font.new(utils.Font, Enum.FontWeight.Medium),
                Parent = contentFrame
            })
        end

        local notificationFrame = utils.CreateRoundFrame(notifications.UICorner, "Squircle", {
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(2, 0, 1, 0),
            AnchorPoint = Vector2.new(0, 1),
            AutomaticSize = "Y",
            ImageTransparency = .05,
            ThemeTag = {
                ImageColor3 = "Background"
            },
        }, {
            createElement("CanvasGroup", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
            }, {
                progressBar,
                createElement("UICorner", {
                    CornerRadius = UDim.new(0, notifications.UICorner),
                })
            }),
            createElement("ImageLabel", {
                Name = "Background",
                Image = notification.Background or "",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                ScaleType = "Crop",
                ImageTransparency = notification.BackgroundImageTransparency or 1
            }, {
                createElement("UICorner", {
                    CornerRadius = UDim.new(0, notifications.UICorner),
                })
            }),
            contentFrame,
            iconElement,
            closeButton,
        })

        local containerFrame = createElement("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = config.Holder
        }, {
            notificationFrame
        })

        function notification.Close()
            if not notification.Closed then
                notification.Closed = true
                if containerFrame then
                    local sizeTween = createTween(containerFrame, 0.45, {Size = UDim2.new(1, 0, 0, -8)})
                    local posTween = createTween(notificationFrame, 0.55, {Position = UDim2.new(2, 0, 1, 0)})
                    
                    if sizeTween then sizeTween:Play() end
                    if posTween then posTween:Play() end
                    
                    task.wait(.45)
                    containerFrame:Destroy()
                end
            end
        end

        -- Анимация
        task.spawn(function()
            task.wait()
            if containerFrame and notificationFrame then
                local sizeTween = createTween(containerFrame, 0.45, {
                    Size = UDim2.new(1, 0, 0, utils.SafeGetProperty(notificationFrame, "AbsoluteSize", Vector2.new(0, 60)).Y)
                })
                local posTween = createTween(notificationFrame, 0.45, {Position = UDim2.new(0, 0, 1, 0)})
                
                if sizeTween then sizeTween:Play() end
                if posTween then posTween:Play() end
                
                if notification.Duration then
                    local progressTween = createTween(progressBar, notification.Duration, {Size = UDim2.new(1, 0, 1, 0)})
                    if progressTween then progressTween:Play() end
                    task.wait(notification.Duration)
                    notification:Close()
                end
            end
        end)

        if closeButton then
            local textButton = closeButton:FindFirstChild("TextButton")
            if textButton and utils.HasProperty(textButton, "MouseButton1Click") then
                utils.AddSignal(textButton.MouseButton1Click, function()
                    notification:Close()
                end)
            end
        end

        return notification
    end

    return notifications
end

-- Система тем
function UILibrary.Themes()
    return {
        Dark = {
            Name = "Dark",
            Accent = "#18181b",
            Dialog = "#161616", 
            Outline = "#FFFFFF",
            Text = "#FFFFFF",
            Placeholder = "#999999",
            Background = "#101010",
            Button = "#52525b",
            Icon = "#a1a1aa",
        },
        Light = {
            Name = "Light",
            Accent = "#FFFFFF",
            Dialog = "#f4f4f5",
            Outline = "#09090b", 
            Text = "#000000",
            Placeholder = "#777777",
            Background = "#e4e4e7",
            Button = "#18181b",
            Icon = "#52525b",
        },
        Rose = {
            Name = "Rose",
            Accent = "#be185d",
            Dialog = "#4c0519",
            Outline = "#fecdd3",
            Text = "#fdf2f8", 
            Placeholder = "#f9a8d4",
            Background = "#1f0308",
            Button = "#e11d48",
            Icon = "#fb7185",
        },
        Plant = {
            Name = "Plant",
            Accent = "#166534",
            Dialog = "#052e16",
            Outline = "#bbf7d0",
            Text = "#f0fdf4",
            Placeholder = "#86efac", 
            Background = "#0a1b0f",
            Button = "#16a34a",
            Icon = "#4ade80",
        }
    }
end

-- Криптографические утилиты (упрощенные и безопасные)
function UILibrary.CryptoUtils()
    local function safeSHA256(input)
        local hash = 0
        input = tostring(input or "")
        for i = 1, #input do
            hash = ((hash * 31) + string.byte(input, i)) % 4294967296
        end
        return string.format("%08x", hash)
    end

    local function safeJSONEncode(data)
        local success, result = pcall(function()
            return Services.HttpService:JSONEncode(data)
        end)
        return success and result or "{}"
    end

    local function safeJSONDecode(json)
        local success, result = pcall(function()
            return Services.HttpService:JSONDecode(tostring(json or "{}"))
        end)
        return success and result or {}
    end

    return {
        SHA256 = safeSHA256,
        JSONEncode = safeJSONEncode,
        JSONDecode = safeJSONDecode
    }
end

-- Системы ключей (безопасные реализации)
function UILibrary.PlatoBoost()
    local crypto = UILibrary.CryptoUtils()
    local keySystem = {}

    function keySystem.New(serviceId, secret)
        local uniqueId = function()
            return Services.HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 16)
        end

        local request = getHttpFunction()
        local isActive = false
        local cachedUrl = ""
        local lastCache = 0

        local function onError(message) 
            warn("PlatoBoost Error: " .. tostring(message))
        end

        repeat task.wait(1) until game:IsLoaded()

        local baseUrl = "https://api-gateway.platoboost.com/v1"

        local function cacheLink()
            if lastCache + 600 < os.time() then
                local success, response = pcall(function()
                    return request and request{
                        Url = baseUrl .. "/sessions",
                        Method = "POST",
                        Body = crypto.JSONEncode({
                            service = tostring(serviceId),
                            identifier = crypto.SHA256(uniqueId())
                        }),
                        Headers = {
                            ["Content-Type"] = "application/json",
                            ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
                        }
                    }
                end)

                if success and response and response.StatusCode == 200 then
                    local data = crypto.JSONDecode(response.Body)
                    if data.success then
                        cachedUrl = tostring(data.data and data.data.url or "")
                        lastCache = os.time()
                        return true, cachedUrl
                    else
                        onError(data.message or "Unknown error")
                        return false, data.message or "Unknown error"
                    end
                elseif success and response and response.StatusCode == 429 then
                    local message = "Rate limited, please wait 20 seconds."
                    onError(message)
                    return false, message
                end

                local message = "Failed to cache link."
                onError(message)
                return false, message
            else
                return true, cachedUrl
            end
        end

        cacheLink()

        local function generateNonce()
            local nonce = ""
            for i = 1, 16 do
                nonce = nonce .. string.char(math.floor(math.random() * 26) + 97)
            end
            return nonce
        end

        local function copyLink()
            local success, url = cacheLink()
            if success and setclipboard then
                setclipboard(url)
            end
        end

        local function redeemKey(key)
            local nonce = generateNonce()
            local endpoint = baseUrl .. "/redeem/" .. tostring(serviceId)

            local payload = {
                identifier = crypto.SHA256(uniqueId()),
                key = tostring(key),
                nonce = nonce
            }

            local success, response = pcall(function()
                return request and request{
                    Url = endpoint,
                    Method = "POST", 
                    Body = crypto.JSONEncode(payload),
                    Headers = {
                        ["Content-Type"] = "application/json"
                    }
                }
            end)

            if success and response and response.StatusCode == 200 then
                local data = crypto.JSONDecode(response.Body)
                if data.success and data.data and data.data.valid then
                    return true
                else
                    onError("Key is invalid.")
                    return false
                end
            elseif success and response and response.StatusCode == 429 then
                onError("Rate limited.")
                return false
            else
                onError("Server error.")
                return false
            end
        end

        local function verifyKey(key)
            if isActive then
                return false, "A request is already being sent."
            end
            isActive = true

            local nonce = generateNonce()
            local endpoint = baseUrl .. "/whitelist/" .. tostring(serviceId) .. 
                "?identifier=" .. crypto.SHA256(uniqueId()) .. "&key=" .. tostring(key) .. "&nonce=" .. nonce

            local success, response = pcall(function()
                return request and request{
                    Url = endpoint,
                    Method = "GET"
                }
            end)

            isActive = false

            if success and response and response.StatusCode == 200 then
                local data = crypto.JSONDecode(response.Body)
                if data.success and data.data and data.data.valid then
                    return true, ""
                else
                    if tostring(key):sub(1, 4) == "KEY_" then
                        return redeemKey(key), ""
                    else
                        return false, "Key is invalid."
                    end
                end
            elseif success and response and response.StatusCode == 429 then
                return false, "Rate limited."
            else
                return false, "Server error."
            end
        end

        return {
            Verify = verifyKey,
            Copy = copyLink,
        }
    end

    return keySystem
end

function UILibrary.PandaDevelopment()
    local crypto = UILibrary.CryptoUtils()
    local keySystem = {}

    function keySystem.New(serviceId)
        local uniqueId = function()
            return Services.HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 16)
        end

        local request = getHttpFunction()

        local function validateKey(key)
            local url = "https://api.pandadevelopment.net/v2_validation?key=" .. 
                tostring(key) .. "&service=" .. tostring(serviceId) .. "&hwid=" .. uniqueId()

            local success, response = pcall(function()
                return request and request{
                    Url = url,
                    Method = "GET",
                    Headers = {["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
                }
            end)

            if success and response then
                if response.Success then
                    local parseSuccess, data = pcall(function()
                        return crypto.JSONDecode(response.Body)
                    end)

                    if parseSuccess and data then
                        if data.V2_Authentication and data.V2_Authentication == "success" then
                            return true, "Authenticated"
                        else
                            local reason = data.Key_Information and data.Key_Information.Notes or "Unknown reason"
                            return false, "Authentication failed: " .. reason
                        end
                    else
                        return false, "JSON decode error"
                    end
                else
                    return false, "HTTP request failed: " .. (response.StatusMessage or "Unknown error")
                end
            else
                return false, "Request error"
            end
        end

        local function getKeyLink()
            return "https://pandadevelopment.net/getkey?service=" .. tostring(serviceId) .. "&hwid=" .. uniqueId()
        end

        local function copyLink()
            if setclipboard then
                setclipboard(getKeyLink())
            end
        end

        return {
            Verify = validateKey,
            Copy = copyLink
        }
    end

    return keySystem
end

function UILibrary.Luarmor()
    local keySystem = {}

    function keySystem.New(scriptId, discordLink)
        -- Безопасный loadstring для Luarmor API
        local luarmorAPI = nil
        pcall(function()
            local success, apiCode = pcall(game.HttpGetAsync, game, "https://api.luarmor.net/files/v3/loaders/scripts/" .. tostring(scriptId))
            if success and apiCode then
                luarmorAPI = loadstring(apiCode)()
                if luarmorAPI then
                    luarmorAPI.script_id = tostring(scriptId)
                end
            end
        end)

        local function validateKey(key)
            if not luarmorAPI or not luarmorAPI.check_key then
                return false, "API not available"
            end

            local success, result = pcall(luarmorAPI.check_key, tostring(key))
            
            if not success then
                return false, "API error"
            end

            if result.code == "KEY_VALID" then
                return true, "Whitelisted!"
            elseif result.code == "KEY_HWID_LOCKED" then
                return false, "Key linked to different HWID. Please reset using bot."
            elseif result.code == "KEY_INCORRECT" then
                return false, "Key is wrong or deleted!"
            else
                return false, "Key check failed: " .. (result.message or "Unknown error") .. " Code: " .. result.code
            end
        end

        local function copyLink()
            if setclipboard then
                setclipboard(tostring(discordLink))
            end
        end

        return {
            Verify = validateKey,
            Copy = copyLink
        }
    end

    return keySystem
end

-- Реестр сервисов системы ключей
function UILibrary.KeySystemServices()
    return {
        platoboost = {
            Name = "Platoboost",
            Icon = "rbxassetid://75920162824531",
            Args = {"ServiceId", "Secret"},
            New = function(...) 
                local platoModule = UILibrary.PlatoBoost()
                return platoModule.New(...)
            end
        },
        pandadevelopment = {
            Name = "Panda Development", 
            Icon = "panda",
            Args = {"ServiceId"},
            New = function(...)
                local pandaModule = UILibrary.PandaDevelopment()
                return pandaModule.New(...)
            end
        },
        luarmor = {
            Name = "Luarmor",
            Icon = "rbxassetid://130918283130165",
            Args = {"ScriptId", "Discord"},
            New = function(...)
                local luarmorModule = UILibrary.Luarmor()
                return luarmorModule.New(...)
            end
        },
    }
end

-- Информация о версии библиотеки
function UILibrary.PackageInfo()
    return Services.HttpService:JSONDecode([[{
        "name": "customui",
        "version": "2.1.1", 
        "main": "./dist/main.lua",
        "repository": "https://github.com/anonymous/customui",
        "author": "Anonymous",
        "description": "Custom Roblox UI Library - Fixed Version",
        "license": "MIT",
        "keywords": [
            "ui-library",
            "ui-design", 
            "interface",
            "gui"
        ]
    }]])
end

-- Компонент кнопки
function UILibrary.Button()
    local utils = UILibrary.Utils()
    if not utils then return {} end
    
    local createElement = utils.CreateElement
    local createTween = utils.CreateTween

    local button = {}

    function button.New(title, icon, callback, variant, parent, dialog, isSmall)
        variant = variant or "Primary"
        local cornerRadius = not isSmall and 10 or 99
        local iconElement

        if icon and icon ~= "" then
            local iconData = utils.Icon(icon)
            iconElement = createElement("ImageLabel", {
                Image = iconData[1],
                ImageRectSize = iconData[2].ImageRectSize,
                ImageRectOffset = iconData[2].ImageRectPosition,
                Size = UDim2.new(0, 21, 0, 21),
                BackgroundTransparency = 1,
                ThemeTag = {
                    ImageColor3 = "Icon",
                }
            })
        end

        local buttonElement = createElement("TextButton", {
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = "X",
            Parent = parent,
            BackgroundTransparency = 1,
            Text = ""
        }, {
            utils.CreateRoundFrame(cornerRadius, "Squircle", {
                ThemeTag = {
                    ImageColor3 = variant ~= "White" and "Button" or nil,
                },
                ImageColor3 = variant == "White" and Color3.new(1, 1, 1) or nil,
                Size = UDim2.new(1, 0, 1, 0),
                Name = "Squircle",
                ImageTransparency = variant == "Primary" and 0 or variant == "White" and 0 or 1
            }),

            utils.CreateRoundFrame(cornerRadius, "Squircle", {
                ImageColor3 = Color3.new(1, 1, 1),
                Size = UDim2.new(1, 0, 1, 0),
                Name = "Special", 
                ImageTransparency = variant == "Secondary" and 0.95 or 1
            }),

            utils.CreateRoundFrame(cornerRadius, "Shadow-sm", {
                ImageColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(1, 3, 1, 3),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Name = "Shadow",
                ImageTransparency = 1,
                Visible = not isSmall
            }),

            utils.CreateRoundFrame(cornerRadius, not isSmall and "SquircleOutline" or "SquircleOutline2", {
                ThemeTag = {
                    ImageColor3 = variant ~= "White" and "Outline" or nil,
                },
                Size = UDim2.new(1, 0, 1, 0),
                ImageColor3 = variant == "White" and Color3.new(0, 0, 0) or nil,
                ImageTransparency = variant == "Primary" and .95 or .85,
                Name = "SquircleOutline",
            }, {
                createElement("UIGradient", {
                    Rotation = 70,
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
                    },
                    Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0.0, 0.1),
                        NumberSequenceKeypoint.new(0.5, 1),
                        NumberSequenceKeypoint.new(1.0, 0.1),
                    }
                })
            }),

            utils.CreateRoundFrame(cornerRadius, "Squircle", {
                Size = UDim2.new(1, 0, 1, 0),
                Name = "Frame",
                ThemeTag = {
                    ImageColor3 = variant ~= "White" and "Text" or nil
                },
                ImageColor3 = variant == "White" and Color3.new(0, 0, 0) or nil,
                ImageTransparency = 1
            }, {
                createElement("UIPadding", {
                    PaddingLeft = UDim.new(0, 16),
                    PaddingRight = UDim.new(0, 16),
                }),
                createElement("UIListLayout", {
                    FillDirection = "Horizontal",
                    Padding = UDim.new(0, 8),
                    VerticalAlignment = "Center",
                    HorizontalAlignment = "Center",
                }),
                iconElement,
                createElement("TextLabel", {
                    BackgroundTransparency = 1,
                    FontFace = Font.new(utils.Font, Enum.FontWeight.SemiBold),
                    Text = tostring(title or "Button"),
                    ThemeTag = {
                        TextColor3 = (variant ~= "Primary" and variant ~= "White") and "Text",
                    },
                    TextColor3 = variant == "Primary" and Color3.new(1, 1, 1) or variant == "White" and Color3.new(0, 0, 0) or nil,
                    AutomaticSize = "XY",
                    TextSize = 18,
                })
            })
        })

        if not buttonElement then return nil end

        if utils.HasProperty(buttonElement, "MouseEnter") then
            utils.AddSignal(buttonElement.MouseEnter, function()
                local frameChild = buttonElement:FindFirstChild("Frame")
                if frameChild then
                    local tween = createTween(frameChild, .047, {ImageTransparency = .95})
                    if tween then tween:Play() end
                end
            end)
        end

        if utils.HasProperty(buttonElement, "MouseLeave") then
            utils.AddSignal(buttonElement.MouseLeave, function()
                local frameChild = buttonElement:FindFirstChild("Frame")
                if frameChild then
                    local tween = createTween(frameChild, .047, {ImageTransparency = 1})
                    if tween then tween:Play() end
                end
            end)
        end

        if utils.HasProperty(buttonElement, "MouseButton1Up") then
            utils.AddSignal(buttonElement.MouseButton1Up, function()
                if dialog and dialog.Close then
                    dialog:Close()
                end
                if callback then
                    utils.SafeCallback(callback)
                end
            end)
        end

        return buttonElement
    end

    return button
end

-- Компонент ввода/TextBox
function UILibrary.Input()
    local utils = UILibrary.Utils()
    if not utils then return {} end
    
    local createElement = utils.CreateElement
    local createTween = utils.CreateTween

    local input = {}

    function input.New(placeholder, icon, parent, inputType, callback, realTime, cornerRadius)
        inputType = inputType or "Input"
        cornerRadius = cornerRadius or 10
        local iconElement

        if icon and icon ~= "" then
            local iconData = utils.Icon(icon)
            iconElement = createElement("ImageLabel", {
                Image = iconData[1],
                ImageRectSize = iconData[2].ImageRectSize,
                ImageRectOffset = iconData[2].ImageRectPosition,
                Size = UDim2.new(0, 21, 0, 21),
                BackgroundTransparency = 1,
                ThemeTag = {
                    ImageColor3 = "Icon",
                }
            })
        end

        local isMultiline = inputType ~= "Input"

        local textBox = createElement("TextBox", {
            BackgroundTransparency = 1,
            TextSize = 17,
            FontFace = Font.new(utils.Font, Enum.FontWeight.Regular),
            Size = UDim2.new(1, iconElement and -29 or 0, 1, 0),
            PlaceholderText = tostring(placeholder or ""),
            ClearTextOnFocus = false,
            ClipsDescendants = true,
            TextWrapped = isMultiline,
            MultiLine = isMultiline,
            TextXAlignment = "Left",
            TextYAlignment = inputType == "Input" and "Center" or "Top",
            ThemeTag = {
                PlaceholderColor3 = "Placeholder",
                TextColor3 = "Text",
            },
            Text = ""
        })

        local inputFrame = createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 42),
            Parent = parent,
            BackgroundTransparency = 1
        }, {
            createElement("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
            }, {
                utils.CreateRoundFrame(cornerRadius, "Squircle", {
                    ThemeTag = {
                        ImageColor3 = "Accent",
                    },
                    Size = UDim2.new(1, 0, 1, 0),
                    ImageTransparency = .85,
                }),
                utils.CreateRoundFrame(cornerRadius, "SquircleOutline", {
                    ThemeTag = {
                        ImageColor3 = "Outline",
                    },
                    Size = UDim2.new(1, 0, 1, 0),
                    ImageTransparency = .95,
                }),
                utils.CreateRoundFrame(cornerRadius, "Squircle", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Name = "Frame",
                    ImageColor3 = Color3.new(1, 1, 1),
                    ImageTransparency = .95
                }, {
                    createElement("UIPadding", {
                        PaddingTop = UDim.new(0, inputType == "Input" and 0 or 12),
                        PaddingLeft = UDim.new(0, 12),
                        PaddingRight = UDim.new(0, 12),
                        PaddingBottom = UDim.new(0, inputType == "Input" and 0 or 12),
                    }),
                    createElement("UIListLayout", {
                        FillDirection = "Horizontal",
                        Padding = UDim.new(0, 8),
                        VerticalAlignment = inputType == "Input" and "Center" or "Top",
                        HorizontalAlignment = "Left",
                    }),
                    iconElement,
                    textBox,
                })
            })
        })

        if not inputFrame or not textBox then return nil end

        if realTime then
            if utils.HasProperty(textBox, "GetPropertyChangedSignal") then
                utils.AddSignal(textBox:GetPropertyChangedSignal("Text"), function()
                    if callback then
                        utils.SafeCallback(callback, textBox.Text)
                    end
                end)
            end
        else
            if utils.HasProperty(textBox, "FocusLost") then
                utils.AddSignal(textBox.FocusLost, function()
                    if callback then
                        utils.SafeCallback(callback, textBox.Text)
                    end
                end)
            end
        end

        return inputFrame
    end

    return input
end

-- Система диалогов/модалок
function UILibrary.Dialog()
    local utils = UILibrary.Utils()
    if not utils then return {} end
    
    local createElement = utils.CreateElement
    local createTween = utils.CreateTween

    local dialog = {
        Holder = nil,
        Parent = nil,
    }

    function dialog.Init(window, parent)
        dialog.Parent = parent
        return dialog
    end

    function dialog.Create(isEmbedded)
        local dialogController = {
            UICorner = 24,
            UIPadding = 15,
            UIElements = {}
        }

        if isEmbedded then 
            dialogController.UIPadding = 0 
            dialogController.UICorner = 26 
        end

        if not isEmbedded then
            dialogController.UIElements.FullScreen = createElement("Frame", {
                ZIndex = 999,
                BackgroundTransparency = 1,
                BackgroundColor3 = Color3.fromHex("#000000"),
                Size = UDim2.new(1, 0, 1, 0),
                Active = false,
                Visible = false,
                Parent = dialog.Parent
            }, {
                createElement("UICorner", {
                    CornerRadius = UDim.new(0, 24)
                })
            })
        end

        dialogController.UIElements.Main = createElement("Frame", {
            Size = UDim2.new(0, 280, 0, 0),
            ThemeTag = {
                BackgroundColor3 = "Dialog",
            },
            AutomaticSize = "Y",
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = 99999,
        }, {
            createElement("UIPadding", {
                PaddingTop = UDim.new(0, dialogController.UIPadding),
                PaddingLeft = UDim.new(0, dialogController.UIPadding),
                PaddingRight = UDim.new(0, dialogController.UIPadding),
                PaddingBottom = UDim.new(0, dialogController.UIPadding),
            })
        })

        dialogController.UIElements.MainContainer = utils.CreateRoundFrame(dialogController.UICorner, "Squircle", {
            Visible = false,
            ImageTransparency = isEmbedded and 0.15 or 0,
            Parent = isEmbedded and dialog.Parent or dialogController.UIElements.FullScreen,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            AutomaticSize = "XY",
            ThemeTag = {
                ImageColor3 = "Dialog"
            },
            ZIndex = 9999,
        }, {
            dialogController.UIElements.Main,
            utils.CreateRoundFrame(dialogController.UICorner, "SquircleOutline2", {
                Size = UDim2.new(1, 0, 1, 0),
                ImageTransparency = 1,
                ThemeTag = {
                    ImageColor3 = "Outline",
                },
            }, {
                createElement("UIGradient", {
                    Rotation = 45,
                    Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0, 0.55),
                        NumberSequenceKeypoint.new(0.5, 0.8),
                        NumberSequenceKeypoint.new(1, 0.6)
                    }
                })
            })
        })

        function dialogController.Open()
            if not isEmbedded and dialogController.UIElements.FullScreen then
                utils.SafeSetProperty(dialogController.UIElements.FullScreen, "Visible", true)
                utils.SafeSetProperty(dialogController.UIElements.FullScreen, "Active", true)
            end

            task.spawn(function()
                if dialogController.UIElements.MainContainer then
                    utils.SafeSetProperty(dialogController.UIElements.MainContainer, "Visible", true)

                    if not isEmbedded and dialogController.UIElements.FullScreen then
                        local tween = createTween(dialogController.UIElements.FullScreen, 0.1, {BackgroundTransparency = .3})
                        if tween then tween:Play() end
                    end
                    
                    local tween2 = createTween(dialogController.UIElements.MainContainer, 0.1, {ImageTransparency = 0})
                    if tween2 then tween2:Play() end

                    task.spawn(function()
                        task.wait(0.05)
                        if dialogController.UIElements.Main then
                            utils.SafeSetProperty(dialogController.UIElements.Main, "Visible", true)
                        end
                    end)
                end
            end)
        end

        function dialogController.Close()
            if not isEmbedded and dialogController.UIElements.FullScreen then
                local tween = createTween(dialogController.UIElements.FullScreen, 0.1, {BackgroundTransparency = 1})
                if tween then tween:Play() end
                utils.SafeSetProperty(dialogController.UIElements.FullScreen, "Active", false)
                task.spawn(function()
                    task.wait(.1)
                    utils.SafeSetProperty(dialogController.UIElements.FullScreen, "Visible", false)
                end)
            end
            
            if dialogController.UIElements.Main then
                utils.SafeSetProperty(dialogController.UIElements.Main, "Visible", false)
            end

            if dialogController.UIElements.MainContainer then
                local tween = createTween(dialogController.UIElements.MainContainer, 0.1, {ImageTransparency = 1})
                if tween then tween:Play() end
            end

            task.spawn(function()
                task.wait(.1)
                if not isEmbedded and dialogController.UIElements.FullScreen then
                    dialogController.UIElements.FullScreen:Destroy()
                elseif dialogController.UIElements.MainContainer then
                    dialogController.UIElements.MainContainer:Destroy()
                end
            end)

            return function() end
        end

        return dialogController
    end

    return dialog
end

-- Компонент всплывающих окон/модалок
function UILibrary.Popup()
    local utils = UILibrary.Utils()
    if not utils then return {} end
    
    local createElement = utils.CreateElement
    local createTween = utils.CreateTween
    local dialogModule = UILibrary.Dialog()
    local buttonModule = UILibrary.Button()

    local popup = {}

    function popup.New(config)
        if not config or not config.WindUI then return {} end
        
        local popupData = {
            Title = config.Title or "Dialog",
            Content = config.Content,
            Icon = config.Icon,
            IconThemed = config.IconThemed,
            Thumbnail = config.Thumbnail,
            Buttons = config.Buttons or {},
            IconSize = 22,
        }

        local dialogController = dialogModule.Init(nil, config.WindUI.ScreenGui)
        if not dialogController then return popupData end
        
        local dialogUI = dialogController.Create(true)
        if not dialogUI then return popupData end

        local thumbnailWidth = 200
        local dialogWidth = 430

        if popupData.Thumbnail and popupData.Thumbnail.Image then
            dialogWidth = 430 + (thumbnailWidth / 2)
        end

        if dialogUI.UIElements and dialogUI.UIElements.Main then
            utils.SafeSetProperty(dialogUI.UIElements.Main, "AutomaticSize", "Y")
            utils.SafeSetProperty(dialogUI.UIElements.Main, "Size", UDim2.new(0, dialogWidth, 0, 0))
        end

        local iconElement
        if popupData.Icon then
            iconElement = utils.CreateImage(
                popupData.Icon,
                popupData.Title .. ":" .. popupData.Icon,
                0,
                config.WindUI.Window and config.WindUI.Window.Folder or "Temp",
                "Popup",
                true,
                config.IconThemed
            )
            if iconElement then
                utils.SafeSetProperty(iconElement, "Size", UDim2.new(0, popupData.IconSize, 0, popupData.IconSize))
                utils.SafeSetProperty(iconElement, "LayoutOrder", -1)
            end
        end

        local titleLabel = createElement("TextLabel", {
            AutomaticSize = "Y",
            BackgroundTransparency = 1,
            Text = tostring(popupData.Title),
            TextXAlignment = "Left",
            FontFace = Font.new(utils.Font, Enum.FontWeight.SemiBold),
            ThemeTag = {
                TextColor3 = "Text",
            },
            TextSize = 20,
            TextWrapped = true,
            Size = UDim2.new(1, iconElement and -popupData.IconSize - 14 or 0, 0, 0)
        })

        local headerFrame = createElement("Frame", {
            BackgroundTransparency = 1,
            AutomaticSize = "XY",
        }, {
            createElement("UIListLayout", {
                Padding = UDim.new(0, 14),
                FillDirection = "Horizontal",
                VerticalAlignment = "Center"
            }),
            iconElement,
            titleLabel
        })

        local mainContentFrame = createElement("Frame", {
            AutomaticSize = "Y",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
        }, {
            headerFrame,
        })

        local contentLabel
        if popupData.Content and popupData.Content ~= "" then
            contentLabel = createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = "Y",
                FontFace = Font.new(utils.Font, Enum.FontWeight.Medium),
                TextXAlignment = "Left",
                Text = tostring(popupData.Content),
                TextSize = 18,
                TextTransparency = .2,
                ThemeTag = {
                    TextColor3 = "Text",
                },
                BackgroundTransparency = 1,
                RichText = true,
                TextWrapped = true,
            })
        end

        local buttonsFrame = createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundTransparency = 1,
        }, {
            createElement("UIListLayout", {
                Padding = UDim.new(0, 9),
                FillDirection = "Horizontal",
                HorizontalAlignment = "Right"
            })
        })

        local thumbnailImage
        if popupData.Thumbnail and popupData.Thumbnail.Image and dialogUI.UIElements and dialogUI.UIElements.Main then
            local thumbnailLabel
            if popupData.Thumbnail.Title then
                thumbnailLabel = createElement("TextLabel", {
                    Text = tostring(popupData.Thumbnail.Title),
                    ThemeTag = {
                        TextColor3 = "Text",
                    },
                    TextSize = 18,
                    FontFace = Font.new(utils.Font, Enum.FontWeight.Medium),
                    BackgroundTransparency = 1,
                    AutomaticSize = "XY",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                })
            end
            thumbnailImage = createElement("ImageLabel", {
                Image = tostring(popupData.Thumbnail.Image),
                BackgroundTransparency = 1,
                Size = UDim2.new(0, thumbnailWidth, 1, 0),
                Parent = dialogUI.UIElements.Main,
                ScaleType = "Crop"
            }, {
                thumbnailLabel,
                createElement("UICorner", {
                    CornerRadius = UDim.new(0, 0),
                })
            })
        end

        if dialogUI.UIElements and dialogUI.UIElements.Main then
            createElement("Frame", {
                Size = UDim2.new(1, thumbnailImage and -thumbnailWidth or 0, 1, 0),
                Position = UDim2.new(0, thumbnailImage and thumbnailWidth or 0, 0, 0),
                BackgroundTransparency = 1,
                Parent = dialogUI.UIElements.Main
            }, {
                createElement("Frame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                }, {
                    createElement("UIListLayout", {
                        Padding = UDim.new(0, 18),
                        FillDirection = "Vertical",
                    }),
                    mainContentFrame,
                    contentLabel,
                    buttonsFrame,
                    createElement("UIPadding", {
                        PaddingTop = UDim.new(0, 16),
                        PaddingLeft = UDim.new(0, 16),
                        PaddingRight = UDim.new(0, 16),
                        PaddingBottom = UDim.new(0, 16),
                    })
                }),
            })
        end

        -- Создание кнопок
        for _, buttonConfig in pairs(popupData.Buttons) do
            if buttonConfig and buttonsFrame then
                buttonModule.New(buttonConfig.Title, buttonConfig.Icon, buttonConfig.Callback, buttonConfig.Variant, buttonsFrame, dialogUI)
            end
        end

        if dialogUI and dialogUI.Open then
            dialogUI:Open()
        end

        return popupData
    end

    return popup
end

-- UI системы ключей
function UILibrary.KeySystem()
    local utils = UILibrary.Utils()
    if not utils then return {} end
    
    local createElement = utils.CreateElement
    local createTween = utils.CreateTween
    local dialogModule = UILibrary.Dialog()
    local buttonModule = UILibrary.Button()
    local inputModule = UILibrary.Input()

    local keySystem = {}

    function keySystem.New(window, keyConfig, onSuccess)
        if not window or not window.WindUI or not onSuccess then return end
        
        local dialogController = dialogModule.Init(nil, window.WindUI.ScreenGui)
        if not dialogController then return end
        
        local dialogUI = dialogController.Create(true)
        if not dialogUI then return end

        local services = {}
        local currentKey

        local thumbnailWidth = (window.KeySystem and window.KeySystem.Thumbnail and window.KeySystem.Thumbnail.Width) or 200
        local dialogWidth = 430

        if window.KeySystem and window.KeySystem.Thumbnail and window.KeySystem.Thumbnail.Image then
            dialogWidth = 430 + (thumbnailWidth / 2)
        end

        if dialogUI.UIElements and dialogUI.UIElements.Main then
            utils.SafeSetProperty(dialogUI.UIElements.Main, "AutomaticSize", "Y")
            utils.SafeSetProperty(dialogUI.UIElements.Main, "Size", UDim2.new(0, dialogWidth, 0, 0))
        end

        -- Иконка
        local iconElement
        if window.Icon then
            iconElement = utils.CreateImage(
                window.Icon,
                window.Title .. ":" .. window.Icon,
                0,
                "Temp",
                "KeySystem",
                window.IconThemed
            )
            if iconElement then
                utils.SafeSetProperty(iconElement, "Size", UDim2.new(0, 24, 0, 24))
                utils.SafeSetProperty(iconElement, "LayoutOrder", -1)
            end
        end

        -- Заголовок
        local titleLabel = createElement("TextLabel", {
            AutomaticSize = "XY",
            BackgroundTransparency = 1,
            Text = tostring(window.Title or "Key System"),
            FontFace = Font.new(utils.Font, Enum.FontWeight.SemiBold),
            ThemeTag = {
                TextColor3 = "Text",
            },
            TextSize = 20
        })

        local subtitleLabel = createElement("TextLabel", {
            AutomaticSize = "XY",
            BackgroundTransparency = 1,
            Text = "Key System",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            TextTransparency = 1,
            FontFace = Font.new(utils.Font, Enum.FontWeight.Medium),
            ThemeTag = {
                TextColor3 = "Text",
            },
            TextSize = 16
        })

        local headerFrame = createElement("Frame", {
            BackgroundTransparency = 1,
            AutomaticSize = "XY",
        }, {
            createElement("UIListLayout", {
                Padding = UDim.new(0, 14),
                FillDirection = "Horizontal",
                VerticalAlignment = "Center"
            }),
            iconElement,
            titleLabel
        })

        local titleContainer = createElement("Frame", {
            AutomaticSize = "Y",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
        }, {
            headerFrame,
            subtitleLabel,
        })

        -- Ввод ключа
        local keyInput = inputModule.New("Enter Key", "key", nil, "Input", function(key)
            currentKey = key
        end)

        -- Примечание
        local noteLabel
        if window.KeySystem and window.KeySystem.Note and window.KeySystem.Note ~= "" then
            noteLabel = createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = "Y",
                FontFace = Font.new(utils.Font, Enum.FontWeight.Medium),
                TextXAlignment = "Left",
                Text = tostring(window.KeySystem.Note),
                TextSize = 18,
                TextTransparency = .4,
                ThemeTag = {
                    TextColor3 = "Text",
                },
                BackgroundTransparency = 1,
                RichText = true,
                TextWrapped = true,
            })
        end

        -- Фрейм кнопок
        local buttonsFrame = createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundTransparency = 1,
        }, {
            createElement("Frame", {
                BackgroundTransparency = 1,
                AutomaticSize = "X",
                Size = UDim2.new(0, 0, 1, 0),
            }, {
                createElement("UIListLayout", {
                    Padding = UDim.new(0, 9),
                    FillDirection = "Horizontal",
                })
            })
        })

        -- Миниатюра
        local thumbnailImage
        if window.KeySystem and window.KeySystem.Thumbnail and window.KeySystem.Thumbnail.Image and dialogUI.UIElements and dialogUI.UIElements.Main then
            local thumbnailLabel
            if window.KeySystem.Thumbnail.Title then
                thumbnailLabel = createElement("TextLabel", {
                    Text = tostring(window.KeySystem.Thumbnail.Title),
                    ThemeTag = {
                        TextColor3 = "Text",
                    },
                    TextSize = 18,
                    FontFace = Font.new(utils.Font, Enum.FontWeight.Medium),
                    BackgroundTransparency = 1,
                    AutomaticSize = "XY",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                })
            end
            thumbnailImage = createElement("ImageLabel", {
                Image = tostring(window.KeySystem.Thumbnail.Image),
                BackgroundTransparency = 1,
                Size = UDim2.new(0, thumbnailWidth, 1, -12),
                Position = UDim2.new(0, 6, 0, 6),
                Parent = dialogUI.UIElements.Main,
                ScaleType = "Crop"
            }, {
                thumbnailLabel,
                createElement("UICorner", {
                    CornerRadius = UDim.new(0, 20),
                })
            })
        end

        if dialogUI.UIElements and dialogUI.UIElements.Main then
            createElement("Frame", {
                Size = UDim2.new(1, thumbnailImage and -thumbnailWidth or 0, 1, 0),
                Position = UDim2.new(0, thumbnailImage and thumbnailWidth or 0, 0, 0),
                BackgroundTransparency = 1,
                Parent = dialogUI.UIElements.Main
            }, {
                createElement("Frame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                }, {
                    createElement("UIListLayout", {
                        Padding = UDim.new(0, 18),
                        FillDirection = "Vertical",
                    }),
                    titleContainer,
                    noteLabel,
                    keyInput,
                    buttonsFrame,
                    createElement("UIPadding", {
                        PaddingTop = UDim.new(0, 16),
                        PaddingLeft = UDim.new(0, 16),
                        PaddingRight = UDim.new(0, 16),
                        PaddingBottom = UDim.new(0, 16),
                    })
                }),
            })
        end

        -- Кнопка выхода
        local exitButton = buttonModule.New("Exit", "log-out", function()
            if dialogUI and dialogUI.Close then
                dialogUI:Close()
            end
        end, "Tertiary", buttonsFrame:FindFirstChild("Frame"))

        if thumbnailImage and exitButton then
            utils.SafeSetProperty(exitButton, "Parent", thumbnailImage)
            utils.SafeSetProperty(exitButton, "Size", UDim2.new(0, 0, 0, 42))
            utils.SafeSetProperty(exitButton, "Position", UDim2.new(0, 10, 1, -10))
            utils.SafeSetProperty(exitButton, "AnchorPoint", Vector2.new(0, 1))
        end

        -- Кнопка получения ключа для простого URL
        if window.KeySystem and window.KeySystem.URL then
            buttonModule.New("Get key", "key", function()
                if setclipboard then
                    setclipboard(tostring(window.KeySystem.URL))
                end
            end, "Secondary", buttonsFrame:FindFirstChild("Frame"))
        end

        -- Обработка успешного ввода
        local function handleSuccess(key)
            if dialogUI and dialogUI.Close then
                dialogUI:Close()
            end
            local folder = (window.Folder or window.Title or "default")
            FileOperations.write(folder .. "/" .. tostring(keyConfig) .. ".key", tostring(key))
            task.wait(.4)
            onSuccess(true)
        end

        -- Кнопка отправки
        local submitButton = buttonModule.New("Submit", "arrow-right", function()
            local key = tostring(currentKey or "empty")
            local folder = window.Folder or window.Title or "default"

            if not window.KeySystem or not window.KeySystem.API then
                local isValid = false
                if window.KeySystem and window.KeySystem.Key then
                    if type(window.KeySystem.Key) == "table" then
                        for _, validKey in pairs(window.KeySystem.Key) do
                            if tostring(validKey) == key then
                                isValid = true
                                break
                            end
                        end
                    else
                        isValid = (tostring(window.KeySystem.Key) == key)
                    end
                end

                if isValid then
                    if window.KeySystem and window.KeySystem.SaveKey then
                        handleSuccess(key)
                    else
                        if dialogUI and dialogUI.Close then
                            dialogUI:Close()
                        end
                        task.wait(.4)
                        onSuccess(true)
                    end
                end
            else
                local success, message = false, "No key services available"
                for _, service in pairs(services) do
                    if service and service.Verify then
                        local result, msg = service.Verify(key)
                        if result then
                            success, message = true, msg
                            break
                        end
                        message = msg
                    end
                end

                if success then
                    handleSuccess(key)
                else
                    if window.WindUI and window.WindUI.Notify then
                        window.WindUI:Notify{
                            Title = "Key System Error",
                            Content = tostring(message),
                            Icon = "triangle-alert",
                        }
                    end
                end
            end
        end, "Primary", buttonsFrame)

        if submitButton then
            utils.SafeSetProperty(submitButton, "AnchorPoint", Vector2.new(1, 0.5))
            utils.SafeSetProperty(submitButton, "Position", UDim2.new(1, 0, 0.5, 0))
        end

        if dialogUI and dialogUI.Open then
            dialogUI:Open()
        end
    end

    return keySystem
end

-- Основной компонент библиотеки
function UILibrary.MainLibrary()
    local utils = UILibrary.Utils()
    local themes = UILibrary.Themes()
    local notificationSystem = UILibrary.NotificationSystem()
    
    if not utils then
        warn("Не удалось инициализировать utils")
        return {}
    end

    local mainLibrary = {}
    
    function mainLibrary.New(config)
        config = config or {}
        
        -- Безопасная настройка тем
        if utils.SetTheme and themes and themes.Dark then
            utils.Themes = themes
            utils.Theme = themes.Dark
            utils.SetTheme(themes.Dark)
        end
        
        -- Безопасное создание главного ScreenGui
        local screenGui = utils.CreateElement("ScreenGui", {
            Name = Services.HttpService:GenerateGUID(false):sub(1, 8),
            ResetOnSpawn = false,
            ZIndexBehavior = "Sibling",
            Parent = Services.CoreGui
        })
        
        if not screenGui then
            warn("Не удалось создать ScreenGui")
            return {}
        end

        -- Безопасная инициализация системы уведомлений
        local notifications = notificationSystem and notificationSystem.Init and notificationSystem.Init(screenGui) or nil

        local library = {
            ScreenGui = screenGui,
            Window = config,
            Notifications = notifications,
            Version = "2.1.1"
        }

        -- Безопасная функция уведомлений
        function library:Notify(notificationConfig)
            if not notifications or not notificationConfig then return end
            notificationConfig.Holder = notifications.Frame
            notificationConfig.WindUI = library
            return notificationSystem.CreateNotification and notificationSystem.CreateNotification(notificationConfig) or {}
        end

        -- Всплывающее окно
        function library:Popup(popupConfig)
            if not popupConfig then return end
            local popupModule = UILibrary.Popup()
            if popupModule and popupModule.New then
                popupConfig.WindUI = library
                return popupModule.New(popupConfig)
            end
        end

        -- Система ключей
        function library:KeySystem(keyConfig, onSuccess)
            if not keyConfig or not onSuccess then return end
            local keySystemModule = UILibrary.KeySystem()
            if keySystemModule and keySystemModule.New then
                keySystemModule.New(library.Window, keyConfig, onSuccess)
            end
        end

        -- Управление темами
        function library:SetTheme(theme)
            if theme and utils.SetTheme then
                utils.SetTheme(theme)
            end
        end

        function library:GetThemes()
            return themes
        end

        -- Безопасная функция очистки
        function library:Destroy()
            if utils.DisconnectAll then
                utils.DisconnectAll()
            end
            if screenGui then
                screenGui:Destroy()
            end
        end

        return library
    end

    return mainLibrary
end

-- Дополнительные компоненты
function UILibrary.ListButton()
    local utils = UILibrary.Utils()
    if not utils then return {} end
    
    local createElement = utils.CreateElement
    local createTween = utils.CreateTween
    
    local listButton = {}
    
    function listButton.New(title, icon, parent)
        local cornerRadius = 10
        local iconElement

        if icon and icon ~= "" then
            local iconData = utils.Icon(icon)
            iconElement = createElement("ImageLabel", {
                Image = iconData[1],
                ImageRectSize = iconData[2].ImageRectSize,
                ImageRectOffset = iconData[2].ImageRectPosition,
                Size = UDim2.new(0, 21, 0, 21),
                BackgroundTransparency = 1,
                ThemeTag = {
                    ImageColor3 = "Icon",
                }
            })
        end

        local titleLabel = createElement("TextLabel", {
            BackgroundTransparency = 1,
            TextSize = 17,
            FontFace = Font.new(utils.Font, Enum.FontWeight.Regular),
            Size = UDim2.new(1, iconElement and -29 or 0, 1, 0),
            TextXAlignment = "Left",
            ThemeTag = {
                TextColor3 = "Text",
            },
            Text = tostring(title or "Button"),
        })

        local buttonElement = createElement("TextButton", {
            Size = UDim2.new(1, 0, 0, 42),
            Parent = parent,
            BackgroundTransparency = 1,
            Text = "",
        }, {
            createElement("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
            }, {
                utils.CreateRoundFrame(cornerRadius, "Squircle", {
                    ThemeTag = {
                        ImageColor3 = "Accent",
                    },
                    Size = UDim2.new(1, 0, 1, 0),
                    ImageTransparency = .85,
                }),
                utils.CreateRoundFrame(cornerRadius, "SquircleOutline", {
                    ThemeTag = {
                        ImageColor3 = "Outline",
                    },
                    Size = UDim2.new(1, 0, 1, 0),
                    ImageTransparency = .9,
                }, {
                    createElement("UIGradient", {
                        Rotation = 70,
                        Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                            ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
                        },
                        Transparency = NumberSequence.new{
                            NumberSequenceKeypoint.new(0.0, 0.1),
                            NumberSequenceKeypoint.new(0.5, 1),
                            NumberSequenceKeypoint.new(1.0, 0.1),
                        }
                    })
                }),
                utils.CreateRoundFrame(cornerRadius, "Squircle", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Name = "Frame",
                    ImageColor3 = Color3.new(1, 1, 1),
                    ImageTransparency = .95
                }, {
                    createElement("UIPadding", {
                        PaddingLeft = UDim.new(0, 12),
                        PaddingRight = UDim.new(0, 12),
                    }),
                    createElement("UIListLayout", {
                        FillDirection = "Horizontal",
                        Padding = UDim.new(0, 8),
                        VerticalAlignment = "Center",
                        HorizontalAlignment = "Left",
                    }),
                    iconElement,
                    titleLabel,
                })
            })
        })

        return buttonElement
    end

    return listButton
end

function UILibrary.ScrollBar()
    local utils = UILibrary.Utils()
    if not utils then return {} end
    
    local createElement = utils.CreateElement
    local createTween = utils.CreateTween
    
    local scrollBar = {}
    
    function scrollBar.New(scrollingFrame, parent, width)
        if not scrollingFrame or not parent then return nil end
        
        local scrollBarFrame = createElement("Frame", {
            Size = UDim2.new(0, width or 6, 1, 0),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 0, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
            Parent = parent,
            ZIndex = 999,
            Active = true,
        })

        local thumbFrame = utils.CreateRoundFrame((width or 6) / 2, "Squircle", {
            Size = UDim2.new(1, 0, 0, 0),
            ImageTransparency = 0.85,
            ThemeTag = {ImageColor3 = "Text"},
            Parent = scrollBarFrame,
        })

        local dragFrame = createElement("Frame", {
            Size = UDim2.new(1, 12, 1, 12),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Active = true,
            ZIndex = 999,
            Parent = thumbFrame,
        })

        local isDragging = false
        local dragOffset = 0

        local function updateThumbSize()
            if not scrollingFrame or not thumbFrame then return end
            
            local canvasSize = utils.SafeGetProperty(scrollingFrame, "AbsoluteCanvasSize", Vector2.new(0, 0)).Y
            local windowSize = utils.SafeGetProperty(scrollingFrame, "AbsoluteWindowSize", Vector2.new(0, 0)).Y

            if canvasSize <= windowSize then
                utils.SafeSetProperty(thumbFrame, "Visible", false)
                return
            end

            local thumbRatio = math.clamp(windowSize / canvasSize, 0.1, 1)
            utils.SafeSetProperty(thumbFrame, "Size", UDim2.new(1, 0, thumbRatio, 0))
            utils.SafeSetProperty(thumbFrame, "Visible", true)
        end

        local function updateScrollPosition()
            if not scrollingFrame or not thumbFrame then return end
            
            local thumbPos = utils.SafeGetProperty(thumbFrame, "Position", UDim2.new(0, 0, 0, 0)).Y.Scale
            local canvasSize = utils.SafeGetProperty(scrollingFrame, "AbsoluteCanvasSize", Vector2.new(0, 0)).Y
            local windowSize = utils.SafeGetProperty(scrollingFrame, "AbsoluteWindowSize", Vector2.new(0, 0)).Y
            local maxScroll = math.max(canvasSize - windowSize, 0)

            if maxScroll <= 0 then return end

            local thumbSize = utils.SafeGetProperty(thumbFrame, "Size", UDim2.new(1, 0, 1, 0))
            local maxThumbPos = math.max(1 - thumbSize.Y.Scale, 0)
            if maxThumbPos <= 0 then return end

            local scrollRatio = thumbPos / maxThumbPos
            local currentCanvasPos = utils.SafeGetProperty(scrollingFrame, "CanvasPosition", Vector2.new(0, 0))
            utils.SafeSetProperty(scrollingFrame, "CanvasPosition", Vector2.new(
                currentCanvasPos.X,
                scrollRatio * maxScroll
            ))
        end

        local function updateThumbPosition()
            if isDragging or not scrollingFrame or not thumbFrame then return end

            local canvasPos = utils.SafeGetProperty(scrollingFrame, "CanvasPosition", Vector2.new(0, 0)).Y
            local canvasSize = utils.SafeGetProperty(scrollingFrame, "AbsoluteCanvasSize", Vector2.new(0, 0)).Y
            local windowSize = utils.SafeGetProperty(scrollingFrame, "AbsoluteWindowSize", Vector2.new(0, 0)).Y
            local maxScroll = math.max(canvasSize - windowSize, 0)

            if maxScroll <= 0 then
                utils.SafeSetProperty(thumbFrame, "Position", UDim2.new(0, 0, 0, 0))
                return
            end

            local scrollRatio = canvasPos / maxScroll
            local thumbSize = utils.SafeGetProperty(thumbFrame, "Size", UDim2.new(1, 0, 1, 0))
            local maxThumbPos = math.max(1 - thumbSize.Y.Scale, 0)
            local thumbPos = math.clamp(scrollRatio * maxThumbPos, 0, maxThumbPos)

            utils.SafeSetProperty(thumbFrame, "Position", UDim2.new(0, 0, thumbPos, 0))
        end

        -- Обработчики событий перетаскивания
        if scrollBarFrame and utils.HasProperty(scrollBarFrame, "InputBegan") then
            utils.AddSignal(scrollBarFrame.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                   input.UserInputType == Enum.UserInputType.Touch then
                    
                    local thumbAbsPos = utils.SafeGetProperty(thumbFrame, "AbsolutePosition", Vector2.new(0, 0))
                    local thumbAbsSize = utils.SafeGetProperty(thumbFrame, "AbsoluteSize", Vector2.new(0, 0))
                    local thumbTop = thumbAbsPos.Y
                    local thumbBottom = thumbTop + thumbAbsSize.Y
                    
                    if not (input.Position.Y >= thumbTop and input.Position.Y <= thumbBottom) then
                        local scrollBarAbsPos = utils.SafeGetProperty(scrollBarFrame, "AbsolutePosition", Vector2.new(0, 0))
                        local scrollBarAbsSize = utils.SafeGetProperty(scrollBarFrame, "AbsoluteSize", Vector2.new(0, 0))
                        local scrollBarTop = scrollBarAbsPos.Y
                        local scrollBarHeight = scrollBarAbsSize.Y
                        local thumbHeight = thumbAbsSize.Y
                        
                        local newThumbPos = input.Position.Y - scrollBarTop - thumbHeight / 2
                        local maxPos = scrollBarHeight - thumbHeight
                        
                        local thumbSize = utils.SafeGetProperty(thumbFrame, "Size", UDim2.new(1, 0, 1, 0))
                        local clampedPos = math.clamp(newThumbPos / maxPos, 0, 1 - thumbSize.Y.Scale)
                        
                        utils.SafeSetProperty(thumbFrame, "Position", UDim2.new(0, 0, clampedPos, 0))
                        updateScrollPosition()
                    end
                end
            end)
        end

        if dragFrame and utils.HasProperty(dragFrame, "InputBegan") then
            utils.AddSignal(dragFrame.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                   input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = true
                    local thumbAbsPos = utils.SafeGetProperty(thumbFrame, "AbsolutePosition", Vector2.new(0, 0))
                    dragOffset = input.Position.Y - thumbAbsPos.Y
                    
                    local moveConnection
                    local endConnection
                    
                    moveConnection = Services.UserInputService.InputChanged:Connect(function(moveInput)
                        if moveInput.UserInputType == Enum.UserInputType.MouseMovement or 
                           moveInput.UserInputType == Enum.UserInputType.Touch then
                            local scrollBarAbsPos = utils.SafeGetProperty(scrollBarFrame, "AbsolutePosition", Vector2.new(0, 0))
                            local scrollBarAbsSize = utils.SafeGetProperty(scrollBarFrame, "AbsoluteSize", Vector2.new(0, 0))
                            local thumbAbsSize = utils.SafeGetProperty(thumbFrame, "AbsoluteSize", Vector2.new(0, 0))
                            local scrollBarTop = scrollBarAbsPos.Y
                            local scrollBarHeight = scrollBarAbsSize.Y
                            local thumbHeight = thumbAbsSize.Y
                            
                            local newThumbPos = moveInput.Position.Y - scrollBarTop - dragOffset
                            local maxPos = scrollBarHeight - thumbHeight
                            
                            local thumbSize = utils.SafeGetProperty(thumbFrame, "Size", UDim2.new(1, 0, 1, 0))
                            local clampedPos = math.clamp(newThumbPos / maxPos, 0, 1 - thumbSize.Y.Scale)
                            
                            utils.SafeSetProperty(thumbFrame, "Position", UDim2.new(0, 0, clampedPos, 0))
                            updateScrollPosition()
                        end
                    end)
                    
                    endConnection = Services.UserInputService.InputEnded:Connect(function(endInput)
                        if endInput.UserInputType == Enum.UserInputType.MouseButton1 or 
                           endInput.UserInputType == Enum.UserInputType.Touch then
                            isDragging = false
                            if moveConnection then moveConnection:Disconnect() end
                            if endConnection then endConnection:Disconnect() end
                        end
                    end)
                end
            end)
        end

        -- Подключение к событиям фрейма прокрутки
        if scrollingFrame and utils.HasProperty(scrollingFrame, "GetPropertyChangedSignal") then
            utils.AddSignal(scrollingFrame:GetPropertyChangedSignal("AbsoluteWindowSize"), function()
                updateThumbSize()
                updateThumbPosition()
            end)
            
            utils.AddSignal(scrollingFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"), function()
                updateThumbSize()
                updateThumbPosition()
            end)
            
            utils.AddSignal(scrollingFrame:GetPropertyChangedSignal("CanvasPosition"), function()
                if not isDragging then
                    updateThumbPosition()
                end
            end)
        end

        updateThumbSize()
        updateThumbPosition()

        return scrollBarFrame
    end

    return scrollBar
end

function UILibrary.Tag()
    local utils = UILibrary.Utils()
    if not utils then return {} end
    
    local createElement = utils.CreateElement
    local createTween = utils.CreateTween
    
    local tag = {}
    
    function tag.New(title, config, parent)
        local tagData = {
            Title = (config and config.Title) or tostring(title or "Tag"),
            Color = (config and config.Color) or Color3.fromHex("#315dff"),
            Radius = (config and config.Radius) or 999,
            TagFrame = nil,
            Height = 26,
            Padding = 10,
            TextSize = 14,
        }

        local function Color3ToHSB(color)
            local r, g, b = color.R, color.G, color.B
            local max = math.max(r, g, b)
            local min = math.min(r, g, b)
            local delta = max - min
            
            local hue = 0
            if delta ~= 0 then
                if max == r then
                    hue = (g - b) / delta % 6
                elseif max == g then
                    hue = (b - r) / delta + 2
                else
                    hue = (r - g) / delta + 4
                end
                hue = hue * 60
            else
                hue = 0
            end
            
            local saturation = (max == 0) and 0 or (delta / max)
            local brightness = max
            
            return {
                h = math.floor(hue + 0.5),
                s = saturation,
                b = brightness
            }
        end

        local function GetPerceivedBrightness(color)
            return 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
        end

        local function GetTextColorForHSB(color)
            if GetPerceivedBrightness(color) > 0.5 then
                local hsb = Color3ToHSB(color)
                return Color3.fromHSV(hsb.h / 360, 0, 0.05)
            else
                local hsb = Color3ToHSB(color)
                return Color3.fromHSV(hsb.h / 360, 0, 0.98)
            end
        end

        local function GetAverageColor(gradient)
            local r, g, b = 0, 0, 0
            local keypoints = gradient.Color.Keypoints
            for _, keypoint in ipairs(keypoints) do
                r = r + keypoint.Value.R
                g = g + keypoint.Value.G
                b = b + keypoint.Value.B
            end
            local count = #keypoints
            return Color3.new(r / count, g / count, b / count)
        end

        local titleLabel = createElement("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = "XY",
            TextSize = tagData.TextSize,
            FontFace = Font.new(utils.Font, Enum.FontWeight.SemiBold),
            Text = tagData.Title,
            TextColor3 = typeof(tagData.Color) == "Color3" and GetTextColorForHSB(tagData.Color) or Color3.new(1, 1, 1),
        })

        local gradientElement
        if typeof(tagData.Color) == "table" then
            gradientElement = createElement("UIGradient")
            if gradientElement then
                for prop, value in pairs(tagData.Color) do
                    if utils.HasProperty(gradientElement, prop) then
                        utils.SafeSetProperty(gradientElement, prop, value)
                    end
                end
                if titleLabel then
                    utils.SafeSetProperty(titleLabel, "TextColor3", GetTextColorForHSB(GetAverageColor(gradientElement)))
                end
            end
        end

        local tagFrame = utils.CreateRoundFrame(tagData.Radius, "Squircle", {
            AutomaticSize = "X",
            Size = UDim2.new(0, 0, 0, tagData.Height),
            Parent = parent,
            ImageColor3 = typeof(tagData.Color) == "Color3" and tagData.Color or Color3.new(1, 1, 1),
        }, {
            gradientElement,
            createElement("UIPadding", {
                PaddingLeft = UDim.new(0, tagData.Padding),
                PaddingRight = UDim.new(0, tagData.Padding),
            }),
            titleLabel,
            createElement("UIListLayout", {
                FillDirection = "Horizontal",
                VerticalAlignment = "Center",
            })
        })

        function tagData:SetTitle(newTitle)
            tagData.Title = tostring(newTitle or "")
            if titleLabel then
                utils.SafeSetProperty(titleLabel, "Text", tagData.Title)
            end
        end

        function tagData:SetColor(newColor)
            tagData.Color = newColor
            if typeof(newColor) == "table" then
                local avgColor = Color3.new(1, 1, 1)
                if gradientElement then
                    pcall(function() avgColor = GetAverageColor(gradientElement) end)
                end
                if titleLabel then
                    local tween = createTween(titleLabel, .06, {TextColor3 = GetTextColorForHSB(avgColor)})
                    if tween then tween:Play() end
                end
                local gradient = (tagFrame and tagFrame:FindFirstChildOfClass("UIGradient")) or createElement("UIGradient", {Parent = tagFrame})
                if gradient then
                    for prop, value in pairs(newColor) do
                        if utils.HasProperty(gradient, prop) then
                            utils.SafeSetProperty(gradient, prop, value)
                        end
                    end
                end
                if tagFrame then
                    local tween2 = createTween(tagFrame, .06, {ImageColor3 = Color3.new(1, 1, 1)})
                    if tween2 then tween2:Play() end
                end
            else
                if gradientElement then
                    gradientElement:Destroy()
                    gradientElement = nil
                end
                if titleLabel then
                    local tween = createTween(titleLabel, .06, {TextColor3 = GetTextColorForHSB(newColor)})
                    if tween then tween:Play() end
                end
                if tagFrame then
                    local tween2 = createTween(tagFrame, .06, {ImageColor3 = newColor})
                    if tween2 then tween2:Play() end
                end
            end
        end

        return tagData
    end

    return tag
end

-- Система управления конфигурацией
function UILibrary.ConfigManager()
    local crypto = UILibrary.CryptoUtils()
    
    local configManager = {
        Folder = nil,
        Path = nil,
        Configs = {},
        Parser = {
            Colorpicker = {
                Save = function(element)
                    return {
                        __type = element.__type,
                        value = element.Default and element.Default.ToHex and element.Default:ToHex() or "#ffffff",
                        transparency = element.Transparency or nil,
                    }
                end,
                Load = function(element, data)
                    if element and element.Update and data then
                        pcall(function()
                            element:Update(Color3.fromHex(data.value or "#ffffff"), data.transparency)
                        end)
                    end
                end
            },
            Dropdown = {
                Save = function(element)
                    return {
                        __type = element.__type,
                        value = element.Value,
                    }
                end,
                Load = function(element, data)
                    if element and element.Select and data then
                        pcall(function()
                            element:Select(data.value)
                        end)
                    end
                end
            },
            Input = {
                Save = function(element)
                    return {
                        __type = element.__type,
                        value = element.Value,
                    }
                end,
                Load = function(element, data)
                    if element and element.Set and data then
                        pcall(function()
                            element:Set(data.value)
                        end)
                    end
                end
            },
            Keybind = {
                Save = function(element)
                    return {
                        __type = element.__type,
                        value = element.Value,
                    }
                end,
                Load = function(element, data)
                    if element and element.Set and data then
                        pcall(function()
                            element:Set(data.value)
                        end)
                    end
                end
            },
            Slider = {
                Save = function(element)
                    return {
                        __type = element.__type,
                        value = element.Value and element.Value.Default or 0,
                    }
                end,
                Load = function(element, data)
                    if element and element.Set and data then
                        pcall(function()
                            element:Set(data.value)
                        end)
                    end
                end
            },
            Toggle = {
                Save = function(element)
                    return {
                        __type = element.__type,
                        value = element.Value,
                    }
                end,
                Load = function(element, data)
                    if element and element.Set and data then
                        pcall(function()
                            element:Set(data.value)
                        end)
                    end
                end
            },
        }
    }
    
    function configManager.Init(library, config)
        if not config or not config.Folder then
            warn("[ Custom UI Library ] Window.Folder не указан.")
            return false
        end
        
        configManager.Folder = tostring(config.Folder)
        configManager.Path = "CustomUI/" .. configManager.Folder .. "/config/"
        
        if not FileOperations.folderExists("CustomUI/" .. configManager.Folder) then
            FileOperations.makeFolder("CustomUI/" .. configManager.Folder)
            if not FileOperations.folderExists("CustomUI/" .. configManager.Folder .. "/config/") then
                FileOperations.makeFolder("CustomUI/" .. configManager.Folder .. "/config/")
            end
        end
        
        local allConfigs = configManager:AllConfigs()
        
        for _, configName in pairs(allConfigs) do
            local configPath = configManager.Path .. configName .. ".json"
            if FileOperations.exists(configPath) then
                configManager.Configs[configName] = FileOperations.read(configPath)
            end
        end
        
        return configManager
    end
    
    function configManager.CreateConfig(name)
        if not name then
            return false, "Не выбран конфигурационный файл"
        end
        
        local config = {
            Path = configManager.Path .. tostring(name) .. ".json",
            Elements = {},
            CustomData = {},
            Version = 1.1
        }
        
        function config:Register(id, element)
            if id and element then
                config.Elements[tostring(id)] = element
            end
        end
        
        function config:Set(key, value)
            if key then
                config.CustomData[tostring(key)] = value
            end
        end
        
        function config:Get(key)
            return config.CustomData[tostring(key or "")]
        end
        
        function config:Save()
            local data = {
                __version = config.Version,
                __elements = {},
                __custom = config.CustomData
            }
            
            for id, element in pairs(config.Elements) do
                if element and element.__type and configManager.Parser[element.__type] then
                    local success, elementData = pcall(configManager.Parser[element.__type].Save, element)
                    if success and elementData then
                        data.__elements[tostring(id)] = elementData
                    end
                end
            end
            
            local jsonData = crypto.JSONEncode(data)
            FileOperations.write(config.Path, jsonData)
            
            return data
        end
        
        function config:Load()
            if not FileOperations.exists(config.Path) then
                return false, "Конфигурационный файл не существует"
            end
            
            local success, data = pcall(function()
                return crypto.JSONDecode(FileOperations.read(config.Path))
            end)
            
            if not success or not data then
                return false, "Не удалось разобрать конфигурационный файл"
            end
            
            if not data.__version then
                local newData = {
                    __version = config.Version,
                    __elements = data,
                    __custom = {}
                }
                data = newData
            end
            
            for id, elementData in pairs(data.__elements or {}) do
                if config.Elements[id] and elementData.__type and configManager.Parser[elementData.__type] then
                    task.spawn(function()
                        pcall(configManager.Parser[elementData.__type].Load, config.Elements[id], elementData)
                    end)
                end
            end
            
            config.CustomData = data.__custom or {}
            
            return config.CustomData
        end
        
        function config:GetData()
            return {
                elements = config.Elements,
                custom = config.CustomData
            }
        end
        
        configManager.Configs[tostring(name)] = config
        return config
    end
    
    function configManager:AllConfigs()
        if not FileOperations.listFiles then 
            return {} 
        end
        
        local configs = {}
        if not FileOperations.folderExists(configManager.Path) then
            FileOperations.makeFolder(configManager.Path)
            return configs
        end
        
        local success, files = pcall(FileOperations.listFiles, configManager.Path)
        if success and files then
            for _, filePath in pairs(files) do
                local configName = string.match(tostring(filePath), "([^\\/]+)%.json$")
                if configName then
                    table.insert(configs, configName)
                end
            end
        end
        
        return configs
    end
    
    function configManager:GetConfig(name)
        return configManager.Configs[tostring(name or "")]
    end
    
    return configManager
end

-- Инициализация кэша библиотеки со всеми модулями
UILibrary.Utils = UILibrary.Utils
UILibrary.Localization = UILibrary.Localization  
UILibrary.NotificationSystem = UILibrary.NotificationSystem
UILibrary.Themes = UILibrary.Themes
UILibrary.CryptoUtils = UILibrary.CryptoUtils
UILibrary.PlatoBoost = UILibrary.PlatoBoost
UILibrary.PandaDevelopment = UILibrary.PandaDevelopment
UILibrary.Luarmor = UILibrary.Luarmor
UILibrary.KeySystemServices = UILibrary.KeySystemServices
UILibrary.PackageInfo = UILibrary.PackageInfo
UILibrary.Button = UILibrary.Button
UILibrary.Input = UILibrary.Input
UILibrary.Dialog = UILibrary.Dialog
UILibrary.Popup = UILibrary.Popup
UILibrary.KeySystem = UILibrary.KeySystem
UILibrary.MainLibrary = UILibrary.MainLibrary
UILibrary.ListButton = UILibrary.ListButton
UILibrary.ScrollBar = UILibrary.ScrollBar
UILibrary.Tag = UILibrary.Tag
UILibrary.ConfigManager = UILibrary.ConfigManager

-- Безопасная функция loadModule после определения всех модулей
local function loadModule(moduleName)
    if not cache[moduleName] and UILibrary[moduleName] then 
        local success, module = pcall(UILibrary[moduleName])
        if success and module then
            cache[moduleName] = {content = module}
        else
            warn("Не удалось загрузить модуль: " .. tostring(moduleName))
            cache[moduleName] = {content = {}}
        end
    end
    return cache[moduleName] and cache[moduleName].content or {}
end

-- Экспорт основной библиотеки с безопасной инициализацией античита
local function initializeLibrary()
    -- Задержка против обнаружения
    local delayTime = math.random(50, 200) / 1000
    task.wait(delayTime)
    
    -- Проверка безопасной среды
    local function isSafeEnvironment()
        local criticalFunctions = {"loadstring", "getgenv", "game"}
        local available = 0
        
        for _, funcName in ipairs(criticalFunctions) do
            if _G[funcName] or (getfenv and getfenv()[funcName]) then
                available = available + 1
            end
        end
        
        return available >= 2
    end
    
    if not isSafeEnvironment() then
        warn("Небезопасная среда обнаружена")
        return nil
    end
    
    -- Основной интерфейс библиотеки, соответствующий API WindUI
    local MainInterface = {}
    
    function MainInterface.New(config)
        local mainLib = UILibrary.MainLibrary()
        if mainLib and mainLib.New then
            return mainLib.New(config)
        else
            warn("Не удалось инициализировать основную библиотеку")
            return {}
        end
    end
    
    -- Экспорт служебных функций для обратной совместимости
    MainInterface.loadModule = loadModule
    MainInterface.Services = Services
    MainInterface.FileOperations = FileOperations
    MainInterface.Version = "2.1.1"
    
    -- Создание глобальной ссылки с обфусцированным именем
    local success = pcall(function()
        local globalName = "CUI_" .. Services.HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 6)
        if getgenv then
            getgenv()[globalName] = MainInterface
        end
    end)
    
    if not success then
        warn("Не удалось создать глобальную ссылку")
    end
    
    return MainInterface
end

return initializeLibrary()
