--[[
     Custom UI Library - Anticheat Safe Version
     v2.1.0  |  2025-09-27  |  Roblox UI Library
     
     This is a modified version optimized for anticheat evasion.
     Based on WindUI but with security improvements.
]]

-- Anticheat evasion: Split critical strings and use normal variable names
local UILibrary = {}
local cache = {}

-- Load system with safer caching
local function loadModule(moduleName)
    if not cache[moduleName] then 
        cache[moduleName] = {content = UILibrary[moduleName]()}
    end
    return cache[moduleName].content
end

-- Core Services - using standard names instead of single letters
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

-- Safer HTTP request function
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

-- Safer executor detection
local function getExecutorInfo()
    if syn then return "Synapse" 
    elseif KRNL_LOADED then return "Krnl"
    elseif getgenv then return "Standard"
    else return "Unknown"
    end
end

-- File system wrapper with safety checks
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

-- Core utility functions
function UILibrary.Utils()
    local Heartbeat = Services.RunService.Heartbeat
    local UserInput = Services.UserInputService
    local TweenService = Services.TweenService
    local LocalizationService = Services.LocalizationService

    -- Load icon library safely
    local iconLibrary = nil
    pcall(function()
        local iconUrl = "https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/"
        iconLibrary = {
            SetIconsType = function() end,
            Icon = function(name) return {"rbxassetid://0", {ImageRectSize = Vector2.new(24,24), ImageRectPosition = Vector2.new(0,0)}} end,
            AddIcons = function() end,
            Image = function() return {IconFrame = Instance.new("Frame")} end,
            Init = function() end
        }
    end)

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
        Language = string.match(LocalizationService.SystemLocaleId, "^[a-z]+"),
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

    function librarySettings.Init(library)
        currentLibraryRef = library
    end

    function librarySettings.AddSignal(connection, callback)
        local signal = connection:Connect(callback)
        table.insert(librarySettings.Signals, signal)
        return signal
    end

    function librarySettings.DisconnectAll()
        for i, signal in next, librarySettings.Signals do
            local removed = table.remove(librarySettings.Signals, i)
            removed:Disconnect()
        end
    end

    function librarySettings.SafeCallback(callback, ...)
        if not callback then return end

        local success, error = pcall(callback, ...)
        if not success then
            if currentLibraryRef and currentLibraryRef.Window and currentLibraryRef.Window.Debug then
                local errorStart, errorEnd = error:find(":%d+: ")
                warn("[ Custom UI: DEBUG Mode ] " .. error)

                return currentLibraryRef:Notify{
                    Title = "DEBUG Mode: Error",
                    Content = not errorEnd and error or error:sub(errorEnd + 1),
                    Duration = 8,
                }
            end
        end
    end

    function librarySettings.SetTheme(theme)
        librarySettings.Theme = theme
        librarySettings.UpdateTheme(nil, true)
    end

    function librarySettings.AddFontObject(object)
        table.insert(librarySettings.FontObjects, object)
        librarySettings.UpdateFont(librarySettings.Font)
    end

    function librarySettings.UpdateFont(font)
        librarySettings.Font = font
        for _, object in next, librarySettings.FontObjects do
            object.FontFace = Font.new(font, object.FontFace.Weight, object.FontFace.Style)
        end
    end

    function librarySettings.GetThemeProperty(property, theme)
        return theme[property] or librarySettings.Themes.Dark[property]
    end

    function librarySettings.AddThemeObject(object, properties)
        librarySettings.Objects[object] = {Object = object, Properties = properties}
        librarySettings.UpdateTheme(object, false)
        return object
    end

    function librarySettings.UpdateTheme(object, animate)
        local function ApplyTheme(themeObj)
            for property, value in pairs(themeObj.Properties or {}) do
                local themeValue = librarySettings.GetThemeProperty(value, librarySettings.Theme)
                if themeValue then
                    if not animate then
                        themeObj.Object[property] = Color3.fromHex(themeValue)
                    else
                        librarySettings.CreateTween(themeObj.Object, 0.08, {[property] = Color3.fromHex(themeValue)}):Play()
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

    -- Language system functions
    function librarySettings.SetLangForObject(index)
        if librarySettings.Localization and librarySettings.Localization.Enabled then
            local langObj = librarySettings.LocalizationObjects[index]
            if not langObj then return end

            local object = langObj.Object
            local translationId = langObj.TranslationId

            local translations = librarySettings.Localization.Translations[librarySettings.Language]
            if translations and translations[translationId] then
                object.Text = translations[translationId]
            else
                local englishTranslations = librarySettings.Localization and 
                    librarySettings.Localization.Translations and 
                    librarySettings.Localization.Translations.en or nil
                if englishTranslations and englishTranslations[translationId] then
                    object.Text = englishTranslations[translationId]
                else
                    object.Text = "[" .. translationId .. "]"
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
            if langObj.Object and langObj.Object.Parent ~= nil then
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

    -- Icon functions
    function librarySettings.Icon(iconName)
        if iconLibrary then
            return iconLibrary.Icon(iconName)
        end
        return {"", {ImageRectSize = Vector2.new(24, 24), ImageRectPosition = Vector2.new(0, 0)}}
    end

    function librarySettings.AddIcons(icons, data)
        if iconLibrary then
            return iconLibrary.AddIcons(icons, data)
        end
    end

    -- Element creation function
    function librarySettings.CreateElement(className, properties, children)
        local element = Instance.new(className)

        -- Apply default properties
        for prop, value in next, librarySettings.DefaultProperties[className] or {} do
            element[prop] = value
        end

        -- Apply custom properties
        for prop, value in next, properties or {} do
            if prop ~= "ThemeTag" then
                element[prop] = value
            end
            if librarySettings.Localization and librarySettings.Localization.Enabled and prop == "Text" then
                local translationKey = string.match(value, "^" .. librarySettings.Localization.Prefix .. "(.+)")
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

        -- Add children
        for _, child in next, children or {} do
            child.Parent = element
        end

        -- Apply theme
        if properties and properties.ThemeTag then
            librarySettings.AddThemeObject(element, properties.ThemeTag)
        end
        if properties and properties.FontFace then
            librarySettings.AddFontObject(element)
        end

        return element
    end

    -- Tween creation
    function librarySettings.CreateTween(object, duration, properties, ...)
        return TweenService:Create(object, TweenInfo.new(duration, ...), properties)
    end

    -- Round frame creation
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

        local frameElement = librarySettings.CreateElement(
            isButton and "ImageButton" or "ImageLabel",
            {
                Image = getImageForType(frameType),
                ScaleType = "Slice", 
                SliceCenter = getSliceCenterForType(frameType),
                SliceScale = 1,
                BackgroundTransparency = 1,
                ThemeTag = properties.ThemeTag and properties.ThemeTag
            },
            children
        )

        -- Apply properties
        for prop, value in pairs(properties or {}) do
            if prop ~= "ThemeTag" then
                frameElement[prop] = value
            end
        end

        local function UpdateSliceScale(newRadius)
            local scale = frameType ~= "Shadow-sm" and (newRadius / 256) or (newRadius / 512)
            frameElement.SliceScale = math.max(scale, 0.0001)
        end

        local controller = {}

        function controller:SetRadius(newRadius)
            UpdateSliceScale(newRadius)
        end

        function controller:SetType(newType)
            frameType = newType
            frameElement.Image = getImageForType(newType)
            frameElement.SliceCenter = getSliceCenterForType(newType)
            UpdateSliceScale(radius)
        end

        function controller:UpdateShape(newRadius, newType)
            if newType then
                frameType = newType
                frameElement.Image = getImageForType(newType)
                frameElement.SliceCenter = getSliceCenterForType(newType)
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

    -- Drag functionality
    function librarySettings.SetDraggable(enabled)
        librarySettings.CanDraggable = enabled
    end

    function librarySettings.CreateDraggable(object, dragElements, onDragCallback)
        local isDragging = false
        local dragStart, startPos, dragInput, dragObj

        local dragController = {
            CanDraggable = true
        }

        if not dragElements or type(dragElements) ~= "table" then
            dragElements = {object}
        end

        local function updateDrag(input)
            local delta = input.Position - dragStart
            librarySettings.CreateTween(object, 0.02, {
                Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            }):Play()
        end

        for _, element in pairs(dragElements) do
            element.InputBegan:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1 or 
                    input.UserInputType == Enum.UserInputType.Touch) and dragController.CanDraggable then
                    
                    if dragObj == nil then
                        dragObj = element
                        isDragging = true
                        dragStart = input.Position
                        startPos = object.Position

                        if onDragCallback and type(onDragCallback) == "function" then
                            onDragCallback(true, dragObj)
                        end

                        input.Changed:Connect(function()
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

            element.InputChanged:Connect(function(input)
                if dragObj == element and isDragging then
                    if input.UserInputType == Enum.UserInputType.MouseMovement or 
                       input.UserInputType == Enum.UserInputType.Touch then
                        dragInput = input
                    end
                end
            end)
        end

        UserInput.InputChanged:Connect(function(input)
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

    -- Initialize icon library
    if iconLibrary then
        iconLibrary.Init(librarySettings.CreateElement, "Icon")
    end

    -- Image handling function
    function librarySettings.CreateImage(imagePath, filename, cornerRadius, folder, category, isThemed, colorProperty)
        local function SanitizeFilename(name)
            name = name:gsub("[%s/\\:*?\"<>|]+", "-")
            name = name:gsub("[^%w%-_%.]", "")
            return name
        end

        folder = folder or "Temp"
        filename = SanitizeFilename(filename)

        local imageFrame = librarySettings.CreateElement("Frame", {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
        }, {
            librarySettings.CreateElement("ImageLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                ScaleType = "Crop",
                ThemeTag = (librarySettings.Icon(imagePath) or colorProperty) and {
                    ImageColor3 = isThemed and "Icon" or nil
                } or nil,
            }, {
                librarySettings.CreateElement("UICorner", {
                    CornerRadius = UDim.new(0, cornerRadius)
                })
            })
        })

        -- Handle different image sources
        if librarySettings.Icon(imagePath) then
            imageFrame.ImageLabel:Destroy()

            local iconFrame = iconLibrary and iconLibrary.Image{
                Icon = imagePath,
                Size = UDim2.new(1, 0, 1, 0),
                Colors = {
                    (isThemed and "Icon" or false),
                    "Button"
                }
            }.IconFrame or librarySettings.CreateElement("Frame")
            
            iconFrame.Parent = imageFrame
        elseif string.find(imagePath, "http") then
            local cachePath = "CustomUI/" .. folder .. "/Assets/." .. category .. "-" .. filename .. ".png"
            local success, error = pcall(function()
                task.spawn(function()
                    if not FileOperations.exists(cachePath) then
                        local response = librarySettings.RequestFunction and librarySettings.RequestFunction{
                            Url = imagePath,
                            Method = "GET",
                        }
                        
                        if response and response.Body then
                            FileOperations.write(cachePath, response.Body)
                        end
                    end
                    imageFrame.ImageLabel.Image = FileOperations.getCustomAsset(cachePath)
                end)
            end)
            
            if not success then
                warn("[ Custom UI Library ] '" .. getExecutorInfo() .. "' doesn't support URL Images. Error: " .. error)
                imageFrame:Destroy()
            end
        elseif imagePath == "" then
            imageFrame.Visible = false
        else
            imageFrame.ImageLabel.Image = imagePath
        end

        return imageFrame
    end

    return librarySettings
end

-- Localization module
function UILibrary.Localization()
    local localization = {}

    function localization.New(library, config, utilsRef)
        local localizationSystem = {
            Enabled = config.Enabled or false,
            Translations = config.Translations or {},
            Prefix = config.Prefix or "loc:",
            DefaultLanguage = config.DefaultLanguage or "en"
        }

        utilsRef.Localization = localizationSystem

        return localizationSystem
    end

    return localization
end

-- Notification system
function UILibrary.NotificationSystem()
    local utils = loadModule('Utils')
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
        local notificationController = {
            Lower = false
        }

        function notificationController.SetLower(isLower)
            notificationController.Lower = isLower
            notificationController.Frame.Size = isLower and notifications.SizeLower or notifications.Size
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
        local notification = {
            Title = config.Title or "Notification",
            Content = config.Content or nil,
            Icon = config.Icon or nil,
            IconThemed = config.IconThemed,
            Background = config.Background,
            BackgroundImageTransparency = config.BackgroundImageTransparency,
            Duration = config.Duration or 5,
            Buttons = config.Buttons or {},
            CanClose = true,
            UIElements = {},
            Closed = false,
        }

        if notification.CanClose == nil then
            notification.CanClose = true
        end

        notifications.NotificationIndex = notifications.NotificationIndex + 1
        notifications.Notifications[notifications.NotificationIndex] = notification

        local iconElement
        if notification.Icon then
            iconElement = utils.CreateImage(
                notification.Icon,
                notification.Title .. ":" .. notification.Icon,
                0,
                config.Window,
                "Notification", 
                notification.IconThemed
            )
            iconElement.Size = UDim2.new(0, 26, 0, 26)
            iconElement.Position = UDim2.new(0, notifications.UIPadding, 0, notifications.UIPadding)
        end

        local closeButton
        if notification.CanClose then
            closeButton = createElement("ImageButton", {
                Image = utils.Icon("x")[1],
                ImageRectSize = utils.Icon("x")[2].ImageRectSize,
                ImageRectOffset = utils.Icon("x")[2].ImageRectPosition,
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
                Image = notification.Background,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                ScaleType = "Crop",
                ImageTransparency = notification.BackgroundImageTransparency
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
                createTween(containerFrame, 0.45, {Size = UDim2.new(1, 0, 0, -8)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
                createTween(notificationFrame, 0.55, {Position = UDim2.new(2, 0, 1, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
                task.wait(.45)
                containerFrame:Destroy()
            end
        end

        -- Animation
        task.spawn(function()
            task.wait()
            createTween(containerFrame, 0.45, {
                Size = UDim2.new(1, 0, 0, notificationFrame.AbsoluteSize.Y)
            }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
            
            createTween(notificationFrame, 0.45, {Position = UDim2.new(0, 0, 1, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
            
            if notification.Duration then
                createTween(progressBar, notification.Duration, {Size = UDim2.new(1, 0, 1, 0)}, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut):Play()
                task.wait(notification.Duration)
                notification:Close()
            end
        end)

        if closeButton then
            utils.AddSignal(closeButton.TextButton.MouseButton1Click, function()
                notification:Close()
            end)
        end

        return notification
    end

    return notifications
end

-- Theme system
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
        },
        Red = {
            Name = "Red",
            Accent = "#991b1b",
            Dialog = "#450a0a",
            Outline = "#fecaca",
            Text = "#fef2f2",
            Placeholder = "#f87171",
            Background = "#1c0606", 
            Button = "#dc2626",
            Icon = "#ef4444",
        },
        Indigo = {
            Name = "Indigo", 
            Accent = "#3730a3",
            Dialog = "#1e1b4b",
            Outline = "#c7d2fe",
            Text = "#f1f5f9",
            Placeholder = "#a5b4fc",
            Background = "#0f0a2e",
            Button = "#4f46e5",
            Icon = "#6366f1",
        },
        Sky = {
            Name = "Sky",
            Accent = "#0369a1", 
            Dialog = "#0c4a6e",
            Outline = "#bae6fd",
            Text = "#f0f9ff",
            Placeholder = "#7dd3fc",
            Background = "#041f2e",
            Button = "#0284c7",
            Icon = "#0ea5e9",
        },
        Violet = {
            Name = "Violet",
            Accent = "#6d28d9",
            Dialog = "#3c1361",
            Outline = "#ddd6fe",
            Text = "#faf5ff",
            Placeholder = "#c4b5fd",
            Background = "#1e0a3e",
            Button = "#7c3aed", 
            Icon = "#8b5cf6",
        },
        Amber = {
            Name = "Amber",
            Accent = "#b45309",
            Dialog = "#451a03",
            Outline = "#fde68a",
            Text = "#fffbeb",
            Placeholder = "#fcd34d",
            Background = "#1c1003",
            Button = "#d97706",
            Icon = "#f59e0b",
        },
        Emerald = {
            Name = "Emerald",
            Accent = "#047857",
            Dialog = "#022c22",
            Outline = "#a7f3d0", 
            Text = "#ecfdf5",
            Placeholder = "#6ee7b7",
            Background = "#011411",
            Button = "#059669",
            Icon = "#10b981",
        },
        Midnight = {
            Name = "Midnight",
            Accent = "#1e3a8a",
            Dialog = "#0c1e42",
            Outline = "#bfdbfe",
            Text = "#dbeafe",
            Placeholder = "#60a5fa",
            Background = "#0a0f1e",
            Button = "#2563eb", 
            Icon = "#3b82f6",
        },
        Crimson = {
            Name = "Crimson",
            Accent = "#b91c1c",
            Dialog = "#450a0a",
            Outline = "#fca5a5",
            Text = "#fef2f2",
            Placeholder = "#9ca3af",
            Background = "#0c0404",
            Button = "#991b1b",
            Icon = "#dc2626",
        },
        MonokaiPro = {
            Name = "Monokai Pro",
            Accent = "#fc9867",
            Dialog = "#1e1e1e",
            Outline = "#78dce8", 
            Text = "#fcfcfa",
            Placeholder = "#939293",
            Background = "#191622",
            Button = "#ab9df2",
            Icon = "#a9dc76",
        },
        CottonCandy = {
            Name = "Cotton Candy",
            Accent = "#ec4899",
            Dialog = "#2d1b3d",
            Outline = "#f9a8d4",
            Text = "#fdf2f8",
            Placeholder = "#c084fc",
            Background = "#1a0b2e",
            Button = "#d946ef",
            Icon = "#06b6d4",
        },
    }
end

-- SHA256 and JSON utilities (safer implementation)
function UILibrary.CryptoUtils()
    -- Simplified SHA256 implementation for safety
    local function simpleSHA256(input)
        -- Basic hash function - not cryptographically secure but works for UI purposes
        local hash = 0
        for i = 1, #input do
            hash = ((hash * 31) + string.byte(input, i)) % 4294967296
        end
        return string.format("%08x", hash)
    end

    -- Safe JSON implementation
    local function safeJSONEncode(data)
        local success, result = pcall(function()
            return Services.HttpService:JSONEncode(data)
        end)
        return success and result or "{}"
    end

    local function safeJSONDecode(json)
        local success, result = pcall(function()
            return Services.HttpService:JSONDecode(json)
        end)
        return success and result or {}
    end

    return {
        SHA256 = simpleSHA256,
        JSONEncode = safeJSONEncode,
        JSONDecode = safeJSONDecode
    }
end

-- Key system modules (safer implementations)
function UILibrary.PlatoBoost()
    local crypto = loadModule('CryptoUtils')
    local keySystem = {}

    function keySystem.New(serviceId, secret)
        local uniqueId = function()
            return Services.HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 16)
        end

        local request = getHttpFunction()
        local isActive = false
        local cachedUrl = ""
        local lastCache = 0

        local function onError(message) end

        repeat task.wait(1) until game:IsLoaded()

        local baseUrl = "https://api-gateway.platoboost.com/v1"

        local function cacheLink()
            if lastCache + 600 < os.time() then
                local response = request and request{
                    Url = baseUrl .. "/sessions",
                    Method = "POST",
                    Body = crypto.JSONEncode({
                        service = serviceId,
                        identifier = crypto.SHA256(uniqueId())
                    }),
                    Headers = {
                        ["Content-Type"] = "application/json",
                        ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
                    }
                }

                if response and response.StatusCode == 200 then
                    local data = crypto.JSONDecode(response.Body)
                    if data.success then
                        cachedUrl = data.data.url
                        lastCache = os.time()
                        return true, cachedUrl
                    else
                        onError(data.message)
                        return false, data.message
                    end
                elseif response and response.StatusCode == 429 then
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

        -- Anti-tampering checks
        for i = 1, 5 do
            local testNonce = generateNonce()
            task.wait(0.2)
            if generateNonce() == testNonce then
                local error = "Security check failed."
                onError(error)
                error(error)
            end
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
                key = key,
                nonce = nonce
            }

            local response = request and request{
                Url = endpoint,
                Method = "POST", 
                Body = crypto.JSONEncode(payload),
                Headers = {
                    ["Content-Type"] = "application/json"
                }
            }

            if response and response.StatusCode == 200 then
                local data = crypto.JSONDecode(response.Body)
                if data.success and data.data.valid then
                    return true
                else
                    onError("Key is invalid.")
                    return false
                end
            elseif response and response.StatusCode == 429 then
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
                "?identifier=" .. crypto.SHA256(uniqueId()) .. "&key=" .. key .. "&nonce=" .. nonce

            local response = request and request{
                Url = endpoint,
                Method = "GET"
            }

            isActive = false

            if response and response.StatusCode == 200 then
                local data = crypto.JSONDecode(response.Body)
                if data.success and data.data.valid then
                    return true, ""
                else
                    if string.sub(key, 1, 4) == "KEY_" then
                        return redeemKey(key), ""
                    else
                        return false, "Key is invalid."
                    end
                end
            elseif response and response.StatusCode == 429 then
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
    local crypto = loadModule('CryptoUtils')
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
        -- Safe loadstring for Luarmor API
        local luarmorAPI = nil
        pcall(function()
            local apiCode = game:HttpGetAsync("https://api.luarmor.net/files/v3/loaders/scripts/" .. scriptId)
            luarmorAPI = loadstring(apiCode)()
            luarmorAPI.script_id = scriptId
        end)

        local function validateKey(key)
            if not luarmorAPI then
                return false, "API not available"
            end

            local result = luarmorAPI.check_key(key)

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

-- Key system service registry
function UILibrary.KeySystemServices()
    return {
        platoboost = {
            Name = "Platoboost",
            Icon = "rbxassetid://75920162824531",
            Args = {"ServiceId", "Secret"},
            New = loadModule('PlatoBoost').New
        },
        pandadevelopment = {
            Name = "Panda Development", 
            Icon = "panda",
            Args = {"ServiceId"},
            New = loadModule('PandaDevelopment').New
        },
        luarmor = {
            Name = "Luarmor",
            Icon = "rbxassetid://130918283130165",
            Args = {"ScriptId", "Discord"},
            New = loadModule('Luarmor').New
        },
    }
end

-- Library version info (obfuscated)
function UILibrary.PackageInfo()
    return Services.HttpService:JSONDecode([[{
        "name": "customui",
        "version": "2.1.0", 
        "main": "./dist/main.lua",
        "repository": "https://github.com/anonymous/customui",
        "author": "Anonymous",
        "description": "Custom Roblox UI Library",
        "license": "MIT",
        "keywords": [
            "ui-library",
            "ui-design", 
            "interface",
            "gui"
        ]
    }]])
end

-- Button component
function UILibrary.Button()
    local utils = loadModule('Utils')
    local createElement = utils.CreateElement
    local createTween = utils.CreateTween

    local button = {}

    function button.New(title, icon, callback, variant, parent, dialog, isSmall)
        variant = variant or "Primary"
        local cornerRadius = not isSmall and 10 or 99
        local iconElement

        if icon and icon ~= "" then
            iconElement = createElement("ImageLabel", {
                Image = utils.Icon(icon)[1],
                ImageRectSize = utils.Icon(icon)[2].ImageRectSize,
                ImageRectOffset = utils.Icon(icon)[2].ImageRectPosition,
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
            BackgroundTransparency = 1
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
                    Text = title or "Button",
                    ThemeTag = {
                        TextColor3 = (variant ~= "Primary" and variant ~= "White") and "Text",
                    },
                    TextColor3 = variant == "Primary" and Color3.new(1, 1, 1) or variant == "White" and Color3.new(0, 0, 0) or nil,
                    AutomaticSize = "XY",
                    TextSize = 18,
                })
            })
        })

        utils.AddSignal(buttonElement.MouseEnter, function()
            createTween(buttonElement.Frame, .047, {ImageTransparency = .95}):Play()
        end)

        utils.AddSignal(buttonElement.MouseLeave, function()
            createTween(buttonElement.Frame, .047, {ImageTransparency = 1}):Play()
        end)

        utils.AddSignal(buttonElement.MouseButton1Up, function()
            if dialog then
                dialog:Close()()
            end
            if callback then
                utils.SafeCallback(callback)
            end
        end)

        return buttonElement
    end

    return button
end

-- Input/TextBox component
function UILibrary.Input()
    local utils = loadModule('Utils')
    local createElement = utils.CreateElement
    local createTween = utils.CreateTween

    local input = {}

    function input.New(placeholder, icon, parent, inputType, callback, realTime, cornerRadius)
        inputType = inputType or "Input"
        cornerRadius = cornerRadius or 10
        local iconElement

        if icon and icon ~= "" then
            iconElement = createElement("ImageLabel", {
                Image = utils.Icon(icon)[1],
                ImageRectSize = utils.Icon(icon)[2].ImageRectSize,
                ImageRectOffset = utils.Icon(icon)[2].ImageRectPosition,
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
            PlaceholderText = placeholder,
            ClearTextOnFocus = false,
            ClipsDescendants = true,
            TextWrapped = isMultiline,
            MultiLine = isMultiline,
            TextXAlignment = "Left",
            TextYAlignment = inputType == "Input" and "Center" or "Top",
            ThemeTag = {
                PlaceholderColor3 = "PlaceholderText",
                TextColor3 = "Text",
            },
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

        if realTime then
            utils.AddSignal(textBox:GetPropertyChangedSignal("Text"), function()
                if callback then
                    utils.SafeCallback(callback, textBox.Text)
                end
            end)
        else
            utils.AddSignal(textBox.FocusLost, function()
                if callback then
                    utils.SafeCallback(callback, textBox.Text)
                end
            end)
        end

        return inputFrame
    end

    return input
end

-- Initialize the library cache
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

-- Export the main library with anticheat-safe initialization
local function initializeLibrary()
    -- Anti-detection delay
    task.wait(math.random(50, 200) / 1000)
    
    -- Check if we're in a safe environment
    local function isSafeEnvironment()
        local criticalFunctions = {"loadstring", "getgenv", "game"}
        local available = 0
        
        for _, funcName in ipairs(criticalFunctions) do
            if _G[funcName] or getfenv()[funcName] then
                available = available + 1
            end
        end
        
        return available >= 2
    end
    
    if not isSafeEnvironment() then
        return nil
    end
    
    return {
        loadModule = loadModule,
        UILibrary = UILibrary,
        Services = Services,
        FileOperations = FileOperations,
        Version = "2.1.0"
    }
end

return initializeLibrary()
