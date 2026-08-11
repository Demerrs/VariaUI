# 🎨 VariaUI

**A modern, lightweight, and highly customizable UI framework for Roblox.**

## 🌟 Introduction

VariaUI is designed to be sleek, modular, and developer-friendly. Whether you are building a simple UI or complex one, VariaUI provides beautifully animated components, built-in settings management, and full theme customization out of the box.

---

## 🚀 1. Getting Started

To begin using VariaUI, load the library via GitHub and initialize your main **Window**.

> **💡 Pro Tip:** If you are using a custom theme, apply it using `UILibrary:SetTheme()` *before* creating your window to ensure all components load with your custom colors instantly!

```lua
local url = "https://raw.githubusercontent.com/Demerrs/VariaUI/refs/heads/main/VariaUI.lua"
local UILibrary = loadstring(game:HttpGet(url))()

-- (Optional) Apply custom theme colors before building the UI
UILibrary:SetTheme({
    Background = Color3.fromRGB(12, 12, 14),
    Secondary = Color3.fromRGB(255, 65, 65), -- Red Accent
    UseGradient = true
})

-- Initialize the Main Window
local Window = UILibrary:CreateWindow({
    Title = "VariaUI Hub",
    SubTitle = "v1.0.0",
    Size = UDim2.new(0, 560, 0, 380),    -- Optional: Default size
    MinSize = Vector2.new(380, 280),     -- Optional: Minimum drag size
    MaxSize = Vector2.new(1000, 720),    -- Optional: Maximum drag size
    ToggleKey = Enum.KeyCode.RightShift, -- Optional: Key to show/hide menu
    OnClose = function()
        print("UI has been closed and destroyed!")
    end
})

```

---

## 🪟 2. Window Management API

Once your `Window` is created, you can control its behavior and layout using these methods:

| Method | Description |
| --- | --- |
| `Window:SetVisible(boolean)` | Hides or shows the entire UI without destroying it. |
| `Window:Minimize()` | Minimizes the UI into a floating, draggable icon bubble. |
| `Window:Restore()` | Restores the UI from the minimized bubble state. |
| `Window:ToggleMinimize()` | Toggles between the minimized and restored states. |
| `Window:Destroy()` | Completely deletes the UI and disconnects all events. |
| `Window:OnClose(callback)` | Sets the function that runs when the "X" close button is clicked. |
| `Window:SetWindowIcon(assetId)` | Changes the top-bar window icon asset ID. |
| `Window:SetBubbleIcon(assetId)` | Changes the minimized draggable bubble icon asset ID. |
| `Window:SetToggleKey(keyCode)` | Binds a new keyboard shortcut to show/hide the menu. |

### Built-in Feature Tabs

VariaUI includes pre-built utility tabs so you don't have to code them from scratch!

| Method | Description |
| --- | --- |
| `Window:CreateThemeTab(config)` | Generates a complete "Theme Settings" tab for live color tweaking. |
| `Window:CreateIntegrationTab(config)` | Generates a "Webhooks" tab for easy Discord webhook testing/saving. |

```lua
-- Example: Instantly add Theme and Webhook controls to your UI
Window:CreateTabCategory("Utility")
Window:CreateThemeTab({ Name = "UI Customization" })
Window:CreateIntegrationTab({ Name = "Discord Integration" })

```

---

## 📁 3. Layout: Categories, Tabs & Sections

Keep your interface organized by nesting elements logically: **Category ➔ Tab ➔ Section ➔ Component**.

```lua
-- 1. Create a non-clickable text label in the sidebar to group tabs
Window:CreateTabCategory("Main Features")

-- 2. Create a clickable tab in the sidebar
local MainTab = Window:CreateTab({
    Name = "Combat",
    Icon = "rbxassetid://123456789", -- Optional
    Columns = 1,                     -- Grid layout columns (Default: 1)
    RowHeight = 44                   -- Row height for grid layouts
})

-- 3. Create a visual grouping box inside the tab
local CombatSection = MainTab:CreateSection("Aimbot Settings")

```

---

## 🧩 4. Component Library

Parent your components to any `Tab` or `Section`. All components support a `Flag` property, which acts as a unique ID for saving and loading configurations.

### 🔘 Button

A standard interactable button. Can chain inline keybinds or color pickers.

```lua
local MyButton = CombatSection:CreateButton({
    Title = "Execute Script",
    Description = "Runs the main loop.",
    TextColor = Color3.fromRGB(255, 255, 255),
    Callback = function()
        print("Button clicked!")
    end,
})

MyButton:SetTitle("Run Now!") -- Update title dynamically

```

### 🎚️ Toggle

An on/off switch component.

```lua
local MyToggle = CombatSection:CreateToggle({
    Title = "Auto-Farm",
    Description = "Automatically attacks nearby enemies.",
    Default = false,
    Flag = "AutoFarm_Toggle", 
    Callback = function(state)
        print("Auto-Farm is:", state)
    end,
})

-- Example: Chaining inline elements to a Toggle
MyToggle:AddKeybind({
    Title = "Toggle Shortcut",
    Default = Enum.KeyCode.F,
    Flag = "AutoFarm_Key"
}):AddColorPicker({
    Title = "ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "AutoFarm_Color"
})

```

### 🎛️ Slider

A draggable slider for numerical values.

```lua
local MySlider = CombatSection:CreateSlider({
    Title = "WalkSpeed",
    Description = "Adjusts your character's speed.",
    Min = 16,
    Max = 100,
    Default = 16,
    Increment = 1,
    Flag = "WalkSpeed_Slider",
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end,
})

```

### 📋 Dropdowns (Single & Multi)

Searchable dropdown menus for selecting from a list of options.

```lua
-- Single Selection
CombatSection:CreateDropdown({
    Title = "Target Priority",
    Description = "Who should the aimbot target first?",
    Options = {"Distance", "Health", "Threat"},
    Default = "Distance",
    Flag = "Target_Dropdown",
    Callback = function(selectedValue)
        print("Targeting by:", selectedValue)
    end,
})

-- Multiple Selection
CombatSection:CreateMultiDropdown({
    Title = "ESP Entities",
    Options = {"Players", "NPCs", "Items", "Vehicles"},
    Default = {"Players", "Items"},
    Flag = "ESP_MultiDrop",
    Callback = function(selectedList)
        print("Showing ESP for:", table.concat(selectedList, ", "))
    end,
})

```

### ⌨️ Text Inputs (String & Number)

```lua
-- String Input
CombatSection:CreateStringInput({
    Title = "Custom Status",
    Placeholder = "Enter text...",
    Default = "AFK",
    Flag = "Status_Input",
    Callback = function(text)
        print("Status updated to:", text)
    end,
})

-- Number Input
CombatSection:CreateInput({
    Title = "Custom Field of View",
    Placeholder = "70",
    Default = 70,
    Min = 30,
    Max = 120,
    Flag = "FOV_Input",
    Callback = function(value)
        workspace.CurrentCamera.FieldOfView = value
    end,
})

```

### 🎨 Color Picker & 🔑 Keybind (Standalone)

```lua
CombatSection:CreateColorPicker({
    Title = "UI Accent Color",
    Default = Color3.fromRGB(51, 144, 236),
    Flag = "Accent_Color",
    Callback = function(color)
        UILibrary:SetTheme({ Secondary = color })
    end,
})

CombatSection:CreateKeybind({
    Title = "Panic Button",
    Description = "Instantly closes the game.",
    Default = Enum.KeyCode.End,
    Flag = "Panic_Key",
    Callback = function(key)
        game:Shutdown()
    end,
})

```

---

## 🛠️ 5. Component API Methods

When you create a component, it returns an API object. You can use this to programmatically change or read their values later.

| Method | Description |
| --- | --- |
| `Component:SetValue(value)` | Forces the component to a new value and triggers its callback. |
| `Component:GetValue()` | Returns the current value of the component. |
| `Component:AddKeybind(config)` | Appends an inline keybind button to the right side of the row. |
| `Component:AddColorPicker(config)` | Appends an inline color picker to the right side of the row. |

```lua
local GodModeToggle = CombatSection:CreateToggle({ Title = "God Mode", Flag = "GodMode" })

-- Force it on via script
GodModeToggle:SetValue(true)

-- Read the state later
if GodModeToggle:GetValue() == true then
    print("Player is invincible!")
end

```

---

## ⚙️ 6. Library Utilities & Config Saving

These functions are called directly on `UILibrary` and handle configuration saving, notification dispatching, and theming.

### Configuration Saving & Loading

VariaUI automatically formats `Color3` values and keybinds safely for JSON encoding.

```lua
-- SAVING: Get all current UI values by their Flags
local currentConfig = UILibrary:GetSettings()
local jsonString = game:GetService("HttpService"):JSONEncode(currentConfig)
writefile("MyHubConfig.json", jsonString)

-- LOADING: Apply a saved table back to the UI
local savedTable = game:GetService("HttpService"):JSONDecode(readfile("MyHubConfig.json"))
UILibrary:LoadSettings(savedTable)

```

### Notifications

Trigger a clean, animated on-screen toast notification.

```lua
UILibrary:Notify({
    Title = "Success!",
    Content = "Your configuration has been saved successfully.",
    Duration = 3.5 -- Display duration in seconds
})

```

### Dynamic Theming

Update the global theme colors dynamically. VariaUI automatically re-renders all existing components to match the new theme.

```lua
UILibrary:SetTheme({
    Background = Color3.fromRGB(15, 15, 20),
    Elevated = Color3.fromRGB(22, 22, 28),
    Secondary = Color3.fromRGB(0, 255, 127), -- Neon Green
    TextPrimary = Color3.fromRGB(255, 255, 255),
    UseGradient = false
})

```
