-- Source: src/init.lua
local WindUI = {
    Window = nil,
    Theme = nil,
    Creator = require("./modules/Creator"),
    Themes = require("./themes/init"),
    Transparent = false,
    
    TransparencyValue = .15,
    
    UIScale = 1,
    
    ConfigManager = nil
}


local KeySystem = require("./components/KeySystem")

local Themes = WindUI.Themes
local Creator = WindUI.Creator

local New = Creator.New
local Tween = Creator.Tween

Creator.Themes = Themes

local LocalPlayer = game:GetService("Players") and game:GetService("Players").LocalPlayer or nil
WindUI.Themes = Themes

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local GUIParent = gethui and gethui() or game.CoreGui
--local GUIParent = game.CoreGui

WindUI.ScreenGui = New("ScreenGui", {
    Name = "WindUI",
    Parent = GUIParent,
    IgnoreGuiInset = true,
    ScreenInsets = "None",
}, {
    New("UIScale", {
        Scale = WindUI.Scale,
    }),
    New("Folder", {
        Name = "Window"
    }),
    -- New("Folder", {
    --     Name = "Notifications"
    -- }),
    -- New("Folder", {
    --     Name = "Dropdowns"
    -- }),
    New("Folder", {
        Name = "KeySystem"
    }),
    New("Folder", {
        Name = "Popups"
    }),
    New("Folder", {
        Name = "ToolTips"
    })
})

WindUI.NotificationGui = New("ScreenGui", {
    Name = "WindUI/Notifications",
    Parent = GUIParent,
    IgnoreGuiInset = true,
})
WindUI.DropdownGui = New("ScreenGui", {
    Name = "WindUI/Dropdowns",
    Parent = GUIParent,
    IgnoreGuiInset = true,
})
ProtectGui(WindUI.ScreenGui)
ProtectGui(WindUI.NotificationGui)
ProtectGui(WindUI.DropdownGui)

Creator.Init(WindUI)

math.clamp(WindUI.TransparencyValue, 0, 0.4)

local Notify = require("./components/Notification")
local Holder = Notify.Init(WindUI.NotificationGui)

function WindUI:Notify(Config)
    Config.Holder = Holder.Frame
    Config.Window = WindUI.Window
    Config.WindUI = WindUI
    return Notify.New(Config)
end

function WindUI:SetNotificationLower(Val)
    Holder.SetLower(Val)
end

function WindUI:SetFont(FontId)
    Creator.UpdateFont(FontId)
end

function WindUI:AddTheme(LTheme)
    Themes[LTheme.Name] = LTheme
    return LTheme
end

function WindUI:SetTheme(Value)
    if Themes[Value] then
        WindUI.Theme = Themes[Value]
        Creator.SetTheme(Themes[Value])
        Creator.UpdateTheme()
        
        return Themes[Value]
    end
    return nil
end

WindUI:SetTheme("Dark")

function WindUI:GetThemes()
    return Themes
end
function WindUI:GetCurrentTheme()
    return WindUI.Theme.Name
end
function WindUI:GetTransparency()
    return WindUI.Transparent or false
end
function WindUI:GetWindowSize()
    return Window.UIElements.Main.Size
end


function WindUI:Popup(PopupConfig)
    PopupConfig.WindUI = WindUI
    return require("./components/popup/Init").new(PopupConfig)
end


function WindUI:CreateWindow(Config)
    local CreateWindow = require("./components/window/Init")
    
    if not isfolder("WindUI") then
        makefolder("WindUI")
    end
    if Config.Folder then
        makefolder(Config.Folder)
    else
        makefolder(Config.Title)
    end
    
    Config.WindUI = WindUI
    Config.Parent = WindUI.ScreenGui.Window
    
    if WindUI.Window then
        warn("You cannot create more than one window")
        return
    end
    
    local CanLoadWindow = true
    
    local Theme = Themes[Config.Theme or "Dark"]
    
    WindUI.Theme = Theme
    
    Creator.SetTheme(Theme)
    
    local Filename = LocalPlayer.Name or "Unknown"
    
    if Config.KeySystem then
        CanLoadWindow = false
        if Config.KeySystem.SaveKey and Config.Folder then
            if isfile(Config.Folder .. "/" .. Filename .. ".key") then
                local isKey
                if type(Config.KeySystem.Key) == "table" then
                    isKey = table.find(Config.KeySystem.Key, readfile(Config.Folder .. "/" .. Filename .. ".key" ))
                else
                    isKey = tostring(Config.KeySystem.Key) == tostring(readfile(Config.Folder .. "/" .. Filename .. ".key" ))
                end
                if isKey then
                    CanLoadWindow = true
                end
            else
                KeySystem.new(Config, Filename, function(c) CanLoadWindow=c end)
            end
        else
            KeySystem.new(Config, Filename, function(c) CanLoadWindow=c end)
        end
		repeat task.wait() until CanLoadWindow
    end
    
    local Window = CreateWindow(Config)

    WindUI.Transparent = Config.Transparent
    WindUI.Window = Window
    
    
    -- function Window:ToggleTransparency(Value)
    --     WindUI.Transparent = Value
    --     WindUI.Window.Transparent = Value
        
    --     Window.UIElements.Main.Background.BackgroundTransparency = Value and WindUI.TransparencyValue or 0
    --     Window.UIElements.Main.Background.ImageLabel.ImageTransparency = Value and WindUI.TransparencyValue or 0
    --     Window.UIElements.Main.Gradient.UIGradient.Transparency = NumberSequence.new{
    --         NumberSequenceKeypoint.new(0, 1), 
    --         NumberSequenceKeypoint.new(1, Value and 0.85 or 0.7),
    --     }
    -- end
    
    return Window
end

return WindUI

-- Source: src/modules/Creator.lua
--[[

Credits: dawid 

]]

local RunService = game:GetService("RunService")
local RenderStepped = RunService.Heartbeat
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Icons = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/main/Main.lua"))()
Icons.SetIconsType("lucide")

local Creator = {
    Font = "rbxassetid://12187365364", -- Inter
    CanDraggable = true,
    Theme = nil,
    Themes = nil,
    WindUI = nil,
    Signals = {},
    Objects = {},
    FontObjects = {},
    Request = http_request or (syn and syn.request) or request,
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
        }, TextButton = {
            BackgroundColor3 = Color3.new(1,1,1),
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor= false,
            TextColor3 = Color3.new(1,1,1),
            TextSize = 14,
        },
        TextBox = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            ClearTextOnFocus = false,
            Text = "",
            TextColor3 = Color3.new(0, 0, 0),
            TextSize = 14,
        },
        ImageLabel = {
            BackgroundTransparency = 1,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
        },
        ImageButton = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            AutoButtonColor = false,
        },
        UIListLayout = {
            SortOrder = "LayoutOrder",
        },
        ScrollingFrame = {
            ScrollBarImageTransparency = 1,
            BorderSizePixel = 0,
        }
    },
    Colors = {
        Red = "#e53935",    -- Danger
        Orange = "#f57c00", -- Warning
        Green = "#43a047",  -- Success
        Blue = "#039be5",   -- Info
        White = "#ffffff",   -- White
        Grey = "#484848",   -- Grey
    }
}

function Creator.Init(WindUI)
    Creator.WindUI = WindUI
end


function Creator.AddSignal(Signal, Function)
	table.insert(Creator.Signals, Signal:Connect(Function))
end

function Creator.DisconnectAll()
	for idx, signal in next, Creator.Signals do
		local Connection = table.remove(Creator.Signals, idx)
		Connection:Disconnect()
	end
end

-- ↓ Debug mode
function Creator.SafeCallback(Function, ...)
	if not Function then
		return
	end

	local Success, Event = pcall(Function, ...)
	if not Success then
		local _, i = Event:find(":%d+: ")


	    warn("[ WindUI: DEBUG Mode ] " .. Event)
	    
		return Creator.WindUI:Notify({
			Title = "DEBUG Mode: Error",
			Content = not i and Event or Event:sub(i + 1),
			Duration = 8,
		})
	end
end

function Creator.SetTheme(Theme)
    Creator.Theme = Theme
    Creator.UpdateTheme(nil, true)
end

function Creator.AddFontObject(Object)
    table.insert(Creator.FontObjects, Object)
    Creator.UpdateFont(Creator.Font)
end

function Creator.UpdateFont(FontId)
    Creator.Font = FontId
    for _,Obj in next, Creator.FontObjects do
        Obj.FontFace = Font.new(FontId, Obj.FontFace.Weight, Obj.FontFace.Style)
    end
end

function Creator.GetThemeProperty(Property, Theme)
    return Theme[Property] or Creator.Themes["Dark"][Property]
end

function Creator.AddThemeObject(Object, Properties)
    Creator.Objects[Object] = { Object = Object, Properties = Properties }
    Creator.UpdateTheme(Object, false)
    return Object
end

function Creator.UpdateTheme(TargetObject, isTween)
    local function ApplyTheme(objData)
        for Property, ColorKey in pairs(objData.Properties or {}) do
            local Color = Creator.GetThemeProperty(ColorKey, Creator.Theme)
            if Color then
                if not isTween then
                    objData.Object[Property] = Color3.fromHex(Color)
                else
                    Creator.Tween(objData.Object, 0.08, { [Property] = Color3.fromHex(Color) }):Play()
                end
            end
        end
    end

    if TargetObject then
        local objData = Creator.Objects[TargetObject]
        if objData then
            ApplyTheme(objData)
        end
    else
        for _, objData in pairs(Creator.Objects) do
            ApplyTheme(objData)
        end
    end
end

function Creator.Icon(Icon)
    return Icons.Icon(Icon)
end

function Creator.New(Name, Properties, Children)
    local Object = Instance.new(Name)
    
    for Name, Value in next, Creator.DefaultProperties[Name] or {} do
        Object[Name] = Value
    end
    
    for Name, Value in next, Properties or {} do
        if Name ~= "ThemeTag" then
            Object[Name] = Value
        end
    end
    
    for _, Child in next, Children or {} do
        Child.Parent = Object
    end
    
    if Properties and Properties.ThemeTag then
        Creator.AddThemeObject(Object, Properties.ThemeTag)
    end
    if Properties and Properties.FontFace then
        Creator.AddFontObject(Object)
    end
    return Object
end

function Creator.Tween(Object, Time, Properties, ...)
    return TweenService:Create(Object, TweenInfo.new(Time, ...), Properties)
end

function Creator.NewRoundFrame(Radius, Type, Properties, Children, isButton)
    -- local ThemeTags = {}
    -- if Properties.ThemeTag then
    --     for k, v in next, Properties.ThemeTag do
    --         ThemeTags[k] = v
    --     end
    -- end
    local Image = Creator.New(isButton and "ImageButton" or "ImageLabel", {
        Image = Type == "Squircle" and "rbxassetid://80999662900595"
             or Type == "SquircleOutline" and "rbxassetid://117788349049947" 
             or Type == "SquircleOutline2" and "rbxassetid://117817408534198" 
             or Type == "Shadow-sm" and "rbxassetid://84825982946844"
             or Type == "Squircle-TL-TR" and "rbxassetid://73569156276236",
        ScaleType = "Slice",
        SliceCenter = Type ~= "Shadow-sm" and Rect.new(
            512/2,
            512/2,
            512/2,
            512/2
            ) or Rect.new(512,512,512,512),
        SliceScale = 1,
        BackgroundTransparency = 1,
        ThemeTag = Properties.ThemeTag and Properties.ThemeTag
    }, Children)
    
    for k, v in pairs(Properties or {}) do
        if k ~= "ThemeTag" then
            Image[k] = v
        end
    end

    local function UpdateSliceScale(newRadius)
        local sliceScale = Type ~= "Shadow-sm" and (newRadius / (512/2)) or (newRadius/512)
        Image.SliceScale = sliceScale
    end
    
    UpdateSliceScale(Radius)

    return Image
end

local New = Creator.New
local Tween = Creator.Tween

function Creator.SetDraggable(can)
    Creator.CanDraggable = can
end

function Creator.Drag(mainFrame, dragFrames, ondrag)
    local currentDragFrame = nil
    local dragging, dragInput, dragStart, startPos
    local DragModule = {
        CanDraggable = true
    }
    
    if not dragFrames or type(dragFrames) ~= "table" then
        dragFrames = {mainFrame}
    end
    
    local function update(input)
        local delta = input.Position - dragStart
        Creator.Tween(mainFrame, 0.02, {Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )}):Play()
    end
    
    for _, dragFrame in pairs(dragFrames) do
        dragFrame.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and DragModule.CanDraggable then
                if currentDragFrame == nil then
                    currentDragFrame = dragFrame
                    dragging = true
                    dragStart = input.Position
                    startPos = mainFrame.Position
                    
                    if ondrag and type(ondrag) == "function" then 
                        ondrag(true, currentDragFrame)
                    end
                    
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                            currentDragFrame = nil
                            
                            if ondrag and type(ondrag) == "function" then 
                                ondrag(false, currentDragFrame)
                            end
                        end
                    end)
                end
            end
        end)
        
        dragFrame.InputChanged:Connect(function(input)
            if currentDragFrame == dragFrame and dragging then
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    dragInput = input
                end
            end
        end)
    end
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and currentDragFrame ~= nil then
            if DragModule.CanDraggable then 
                update(input)
            end
        end
    end)
    
    function DragModule:Set(v)
        DragModule.CanDraggable = v
    end
    
    return DragModule
end

function Creator.Image(Img, Name, Corner, Folder, Type, IsThemeTag, Themed)
    local function SanitizeFilename(str)
        str = str:gsub("[%s/\\:*?\"<>|]+", "-")
        str = str:gsub("[^%w%-_%.]", "")
        return str
    end
    
    Name = SanitizeFilename(Name)
    
    local ImageFrame = New("Frame", {
        Size = UDim2.new(0,0,0,0), -- czjzjznsmMdj
        --AutomaticSize = "XY",
        BackgroundTransparency = 1,
    }, {
        New("ImageLabel", {
            Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            ScaleType = "Crop",
            ThemeTag = (Creator.Icon(Img) or Themed) and {
                ImageColor3 = IsThemeTag and "Icon" 
            } or nil,
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(0,Corner)
            })
        })
    })
    if Creator.Icon(Img) then
        ImageFrame.ImageLabel.Image = Creator.Icon(Img)[1]
        ImageFrame.ImageLabel.ImageRectOffset = Creator.Icon(Img)[2].ImageRectPosition
        ImageFrame.ImageLabel.ImageRectSize = Creator.Icon(Img)[2].ImageRectSize
    end
    if string.find(Img,"http") then
        local FileName = "WindUI/" .. Folder .. "/Assets/." .. Type .. "-" .. Name .. ".png"
        local success, response = pcall(function()
            task.spawn(function()
                if not isfile(FileName) then
                    local response = Creator.Request({
                        Url = Img,
                        Method = "GET",
                    }).Body
                    
                    writefile(FileName, response)
                end
                ImageFrame.ImageLabel.Image = getcustomasset(FileName)
            end)
        end)
        if not success then
            warn("[ WindUI.Creator ]  '" .. identifyexecutor() .. "' doesnt support the URL Images. Error: " .. response)
            
            ImageFrame:Destroy()
        end
    elseif string.find(Img,"rbxassetid") then
        ImageFrame.ImageLabel.Image = Img
    end
    
    return ImageFrame
end

return Creator

-- Source: main.lua
local WindUI = require("src/init")

-- Test



-- Set theme:
--WindUI:SetTheme("Light")

--- EXAMPLE !!!

function gradient(text, startColor, endColor)
    local result = ""
    local length = #text

    for i = 1, length do
        local t = (i - 1) / math.max(length - 1, 1)
        local r = math.floor((startColor.R + (endColor.R - startColor.R) * t) * 255)
        local g = math.floor((startColor.G + (endColor.G - startColor.G) * t) * 255)
        local b = math.floor((startColor.B + (endColor.B - startColor.B) * t) * 255)

        local char = text:sub(i, i)
        result = result .. "<font color=\"rgb(" .. r ..", " .. g .. ", " .. b .. ")\">" .. char .. "</font>"
    end

    return result
end

local Confirmed = false

WindUI:Popup({
    Title = "Welcome! Popup Example",
    Icon = "rbxassetid://129260712070622",
    IconThemed = true,
    Content = "This is an Example UI for the " .. gradient("WindUI", Color3.fromHex("#00FF87"), Color3.fromHex("#60EFFF")) .. " Lib",
    Buttons = {
        {
            Title = "Cancel",
            --Icon = "",
            Callback = function() end,
            Variant = "Secondary", -- Primary, Secondary, Tertiary
        },
        {
            Title = "Continue",
            Icon = "arrow-right",
            Callback = function() Confirmed = true end,
            Variant = "Primary", -- Primary, Secondary, Tertiary
        }
    }
})


repeat wait() until Confirmed

--

local Window = WindUI:CreateWindow({
    Title = "WindUI Library",
    Icon = "rbxassetid://129260712070622",
    IconThemed = true,
    Author = "Example UI",
    Folder = "CloudHub",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    User = {
        Enabled = true, -- <- or false
        Callback = function() print("clicked") end, -- <- optional
        Anonymous = true -- <- or true
    },
    SideBarWidth = 200,
    -- HideSearchBar = true, -- hides searchbar
    ScrollBarEnabled = true, -- enables scrollbar
    -- Background = "rbxassetid://13511292247", -- rbxassetid only

    -- remove it below if you don't want to use the key system in your script.
    KeySystem = { -- <- keysystem enabled
        Key = { "1234", "5678" },
        Note = "Example Key System. \n\nThe Key is '1234' or '5678",
        -- Thumbnail = {
        --     Image = "rbxassetid://18220445082", -- rbxassetid only
        --     Title = "Thumbnail"
        -- },
        URL = "link-to-linkvertise-or-discord-or-idk", -- remove this if the key is not obtained from the link.
        SaveKey = true, -- saves key : optional
    },
})


-- Window:SetBackgroundImage("rbxassetid://13511292247")
-- Window:SetBackgroundImageTransparency(0.9)


-- TopBar Edit

-- Disable Topbar Buttons
-- Window:DisableTopbarButtons({
--     "Close", 
--     "Minimize", 
--     "Fullscreen",
-- })

-- Create Custom Topbar Buttons
--                        ↓ Name 
