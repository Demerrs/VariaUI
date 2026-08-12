# 🎨 VariaUI

**A modern, lightweight, and highly customizable UI framework for Roblox.**

## 🌟 Introduction

VariaUI is designed to be sleek, modular, and developer-friendly. Whether you are building a simple UI or a complex one, VariaUI provides beautifully animated components, built-in settings management, full theme customization, and dynamic multi-column layouts out of the box.

---

## 🚀 1. Getting Started

To begin using VariaUI, load the library via GitHub and initialize your main **Window**.

> **💡 Pro Tip:** If you are using a custom theme, apply it using `UILibrary:SetTheme()` *before* creating your window to ensure all components load with your custom colors instantly!
> 
> 

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

VariaUI includes pre-built utility tabs so you don't have to code them from scratch! These built-in tabs seamlessly utilize the expandable group layouts.

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

## 📁 3. Layout: Categories, Tabs, Sections & Expandables

Keep your interface organized by nesting elements logically: **Category ➔ Tab ➔ Section ➔ Expandable Group (Optional) ➔ Component**.

```lua
-- 1. Create a non-clickable text label in the sidebar to group tabs
Window:CreateTabCategory("Main Features")

-- 2. Create a clickable tab in the sidebar
local MainTab = Window:CreateTab({
    Name = "General",
    Icon = "rbxassetid://123456789" -- Optional
})

-- 3. Create a visual grouping box inside the tab
local GeneralSection = MainTab:CreateSection("Player Settings")

-- 4. Create an Expandable Group inside the section (Great for hiding advanced settings!)
local AdvancedGroup = GeneralSection:CreateExpandableGroup("Advanced Options", false) -- false = closed by default

```

### 🔲 Multi-Column (Grid) Layouts

Tabs, Sections, and Expandable Groups all feature native support for multi-column grids! Simply pass the `columns` and `rowHeight` parameters when creating them.

Note: When using grids for standard elements (like toggles/buttons), use a `rowHeight` of ~`42`. Elements with descriptions require a `rowHeight` of `52`.

```lua
-- Create a Section with 2 columns
local GridSection = MainTab:CreateSection("Grid Layout", nil, 2, 42)

GridSection:CreateToggle({ Title = "Row 1 Left" })
GridSection:CreateToggle({ Title = "Row 1 Right" })

-- Create an Expandable Group with 3 columns inside a section
local TripleGroup = GeneralSection:CreateExpandableGroup("Quick Actions", true, 3, 42)

TripleGroup:CreateButton({ Title = "Action A" })
TripleGroup:CreateButton({ Title = "Action B" })
TripleGroup:CreateButton({ Title = "Action C" })

```

---

## 🧩 4. Component Library

Parent your components to any `Tab`, `Section`, or `ExpandableGroup`. All components support a `Flag` property, which acts as a unique ID for saving and loading configurations.

### 🔘 Button

A standard interactable button. Can chain inline keybinds or color pickers.

```lua
local MyButton = GeneralSection:CreateButton({
    Title = "Submit Data",
    Description = "Sends the current data to the server.",
    TextColor = Color3.fromRGB(255, 255, 255),
    Callback = function()
        print("Data submitted!")
    end,
})

MyButton:SetTitle("Submit Now!") -- Update title dynamically

```

### 🎚️ Toggle

An on/off switch component. Toggles visually sync with your custom theme colors and border settings natively.

```lua
local MyToggle = GeneralSection:CreateToggle({
    Title = "Enable Notifications",
    Description = "Shows popup alerts on your screen.",
    Default = false,
    Flag = "Notify_Toggle", 
    Callback = function(state)
        print("Notifications enabled:", state)
    end,
})

-- Example: Chaining inline elements to a Toggle
MyToggle:AddKeybind({
    Title = "Toggle Shortcut",
    Default = Enum.KeyCode.F,
    Flag = "Notify_Key"
}):AddColorPicker({
    Title = "Alert Color",
    Default = Color3.fromRGB(255, 255, 0),
    Flag = "Notify_Color"
})

```

### 🎛️ Slider

A draggable slider for numerical values.

```lua
local MySlider = GeneralSection:CreateSlider({
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

Searchable dropdown menus for selecting from a list of options. These gracefully pop out over other elements using the built-in overlay system.

```lua
-- Single Selection
GeneralSection:CreateDropdown({
    Title = "Graphics Quality",
    Description = "Set the rendering quality.",
    Options = {"Low", "Medium", "High"},
    Default = "Medium",
    Flag = "Graphics_Dropdown",
    Callback = function(selectedValue)
        print("Quality set to:", selectedValue)
    end,
})

-- Multiple Selection
GeneralSection:CreateMultiDropdown({
    Title = "Render Elements",
    Options = {"Shadows", "Reflections", "Particles", "Textures"},
    Default = {"Shadows", "Textures"},
    Flag = "Render_MultiDrop",
    Callback = function(selectedList)
        print("Rendering:", table.concat(selectedList, ", "))
    end,
})

```

### ⌨️ Text Inputs (String & Number)

```lua
-- String Input (Includes an expand button for multi-line text)
GeneralSection:CreateStringInput({
    Title = "Custom Status",
    Placeholder = "Enter text...",
    Default = "AFK",
    Flag = "Status_Input",
    Callback = function(text)
        print("Status updated to:", text)
    end,
})

-- Number Input
GeneralSection:CreateInput({
    Title = "Field of View",
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
GeneralSection:CreateColorPicker({
    Title = "UI Accent Color",
    Default = Color3.fromRGB(51, 144, 236),
    Flag = "Accent_Color",
    Callback = function(color)
        UILibrary:SetTheme({ Secondary = color })
    end,
})

GeneralSection:CreateKeybind({
    Title = "Hide Interface",
    Description = "Quickly hides the menu.",
    Default = Enum.KeyCode.End,
    Flag = "Hide_Key",
    Callback = function(key)
        Window:ToggleMinimize()
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
local DebugToggle = GeneralSection:CreateToggle({ Title = "Debug Mode", Flag = "DebugMode" })

-- Force it on via script
DebugToggle:SetValue(true)

-- Read the state later
if DebugToggle:GetValue() == true then
    print("System is in debug state!")
end

```

---

## ⚙️ 6. Library Utilities & Config Saving

These functions are called directly on `UILibrary` and handle configuration saving, notification dispatching, and theming.

### Configuration Saving & Loading

VariaUI uses unique `Flag` strings to manage states. It automatically formats `Color3` values and keybinds safely for JSON encoding, regardless of whether a component is in a Section or hidden inside a collapsed Expandable Group.

```lua
-- SAVING: Get all current UI values by their Flags
local currentConfig = UILibrary:GetSettings()
local jsonString = game:GetService("HttpService"):JSONEncode(currentConfig)
writefile("MyConfig.json", jsonString) -- your custom function to write setting

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

Update the global theme colors dynamically. VariaUI automatically re-renders all existing components (including toggles, strokes, text, and nested groups) to flawlessly match the new theme.

```lua
UILibrary:SetTheme({
    Background = Color3.fromRGB(15, 15, 20),
    Elevated = Color3.fromRGB(22, 22, 28),
    Secondary = Color3.fromRGB(0, 255, 127), -- Neon Green
    TextPrimary = Color3.fromRGB(255, 255, 255),
    UseGradient = false
})

```
