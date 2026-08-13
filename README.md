# 🎨 VariaUI

**A modern, lightweight, and highly customizable UI framework for Roblox.**

## 🌟 Introduction

VariaUI is designed to be sleek, modular, and developer-friendly. Whether you are building a simple UI or a complex one, VariaUI provides beautifully animated components, built-in settings management, full theme customization, and dynamic multi-column layouts out of the box. The built-in search bar also dynamically filters through all your tabs, sections, and expandable groups automatically.

---

## 🚀 1. Getting Started

To begin using VariaUI, load the library and initialize your main **Window**.

> **💡 Pro Tip:** If you are using a custom theme, apply it using `UILibrary:SetTheme()` *before* creating your window to ensure all components load with your custom colors instantly!
> 
> 
> **💡 Start Minimized:** If you want your UI to start as a small floating bubble instead of fully open, simply pass `true` to the `StartUp()` function or call `Window:Minimize()` at the very end of your script.
> 
> 

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VariaUI = require(ReplicatedStorage:WaitForChild("VariaUI"))

-- (Optional) Apply custom theme colors before building the UI
VariaUI:SetTheme({
    Background = Color3.fromRGB(12, 12, 14),
    Secondary = Color3.fromRGB(255, 65, 65), -- Red Accent
    UseGradient = true
})

-- Initialize the Main Window
local Window = VariaUI:CreateWindow({
    Title = "newName Interface",
    SubTitle = "v1.1.0",
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
| `Window:SetVisible(boolean)` | Hides or shows the entire UI without destroying it.|
| `Window:Minimize()` | Minimizes the UI into a floating, draggable icon bubble.|
| `Window:Restore()` | Restores the UI from the minimized bubble state.|
| `Window:ToggleMinimize()` | Toggles between the minimized and restored states.|
| `Window:Destroy()` | Completely deletes the UI and disconnects all events.|
| `Window:OnClose(callback)` | Sets the function that runs when the "X" close button is clicked.|
| `Window:SetWindowIcon(assetId)` | Changes the top-bar window icon asset ID.|
| `Window:SetBubbleIcon(assetId)` | Changes the minimized draggable bubble icon asset ID.|
| `Window:SetToggleKey(keyCode)` | Binds a new keyboard shortcut to show/hide the menu.|
| `Window:OnChange(callback)` | Registers a function that fires automatically whenever any setting is changed (includes a built-in 0.5s debounce to prevent spam).|
| `Window:StartUp(savedData, startMinimized)` | Initializes the UI, optionally loading a saved configuration table and choosing if it should start minimized.|

### Built-in Feature Tabs

VariaUI includes pre-built utility tabs so you don't have to code them from scratch!

```lua
-- Example: Instantly add Theme and Webhook controls to your UI
Window:CreateTabCategory("dummyCategory")
Window:CreateThemeTab({ Name = "dummyThemeTab" })
Window:CreateIntegrationTab({ Name = "dummyIntegrationTab" })

```

---

## 📁 3. Layout: Categories, Tabs, Sections & Expandables

Keep your interface organized by nesting elements logically: **Category ➔ Tab ➔ Section ➔ Expandable Group (Optional) ➔ Component**.

⚠️ **Crucial Rule for Expandable Groups:** Expandable Groups *must* be created under a `Section`. You cannot attach an Expandable Group directly to a `Tab`.

```lua
-- 1. Create a non-clickable text label in the sidebar to group tabs
Window:CreateTabCategory("dummyMainCategory")

-- 2. Create a clickable tab in the sidebar
local MainTab = Window:CreateTab({
    Name = "dummyTab",
    Icon = "rbxassetid://123456789" -- Optional
})

-- 3. Create a visual grouping box inside the tab
local GeneralSection = MainTab:CreateSection("dummySection")

-- 4. Create an Expandable Group inside the section
local AdvancedGroup = GeneralSection:CreateExpandableGroup("dummyExpandable", false) -- false = closed by default

```

### 🔲 Multi-Column (Grid) Layouts

Tabs, Sections, and Expandable Groups all feature native support for multi-column grids! Simply pass the `columns` and `rowHeight` parameters when creating them.

```lua
-- Create a Section with 2 columns
local GridSection = MainTab:CreateSection("dummyGridSection", nil, 2, 42)

GridSection:CreateToggle({ Title = "dummyLeftToggle" })
GridSection:CreateToggle({ Title = "dummyRightToggle" })

-- Create an Expandable Group with 3 columns inside a section
local TripleGroup = GeneralSection:CreateExpandableGroup("dummyTripleGroup", true, 3, 42)

TripleGroup:CreateButton({ Title = "dummyActionA" })
TripleGroup:CreateButton({ Title = "dummyActionB" })
TripleGroup:CreateButton({ Title = "dummyActionC" })

```

---

## 🧩 4. Component Library

Parent your components to any `Tab`, `Section`, or `ExpandableGroup`. All components support a `Flag` property, which acts as a unique ID for saving and loading configurations.

### 🔘 Button

A standard interactable button. Can chain inline keybinds or color pickers.

```lua
local MyButton = GeneralSection:CreateButton({
    Title = "dummyButton",
    Description = "dummy description text here.",
    TextColor = Color3.fromRGB(255, 255, 255),
    Callback = function()
        print("dummyAction triggered!")
    end,
})

```

### 🎚️ Toggle

An on/off switch component. Toggles visually sync with your custom theme colors.

```lua
local MyToggle = GeneralSection:CreateToggle({
    Title = "dummyToggle",
    Description = "dummy toggle description.",
    Default = false,
    Flag = "dummyToggle_Flag", 
    Callback = function(state)
        print("dummyToggle state:", state)
    end,
})

-- Example: Chaining inline elements to a Toggle
MyToggle:AddKeybind({
    Title = "dummyShortcut",
    Default = Enum.KeyCode.F,
    Flag = "dummyShortcut_Flag"
}):AddColorPicker({
    Title = "dummyColor",
    Default = Color3.fromRGB(255, 255, 0),
    Flag = "dummyColor_Flag"
})

```

### 🎛️ Slider

A draggable slider for numerical values.

```lua
GeneralSection:CreateSlider({
    Title = "dummySlider",
    Description = "dummy slider description.",
    Min = 1,
    Max = 100,
    Default = 50,
    Increment = 1,
    Flag = "dummySlider_Flag",
    Callback = function(value)
        print("dummySlider value changed to:", value)
    end,
})

```

### 📋 Dropdowns (Single & Multi)

Searchable dropdown menus for selecting from a list of options.

```lua
-- Single Selection
GeneralSection:CreateDropdown({
    Title = "dummyDropdown",
    Options = {"dummyOption1", "dummyOption2", "dummyOption3"},
    Default = "dummyOption2",
    Flag = "dummyDropdown_Flag",
    Callback = function(selectedValue)
        print("dummyOption set to:", selectedValue)
    end,
})

-- Multiple Selection
GeneralSection:CreateMultiDropdown({
    Title = "dummyMultiDropdown",
    Options = {"dummyChoiceA", "dummyChoiceB", "dummyChoiceC", "dummyChoiceD"},
    Default = {"dummyChoiceA", "dummyChoiceD"},
    Flag = "dummyMultiDropdown_Flag",
    Callback = function(selectedList)
        print("Selected:", table.concat(selectedList, ", "))
    end,
})

```

### 🗂️ Priority List

A fully interactive list that allows users to drag and drop items to reorder them.

```lua
GeneralSection:CreatePriorityList({
    Title = "dummyPriorityList",
    Description = "Drag to reorder dummy items.",
    Items = {"dummyItemA", "dummyItemB", "dummyItemC", "dummyItemD"},
    Flag = "dummyPriority_Flag",
    Callback = function(items)
        print("dummyPriority updated!")
    end
})

```

### ⌨️ Text Inputs (String & Number)

```lua
-- String Input (Includes an expand button for multi-line text)
GeneralSection:CreateStringInput({
    Title = "dummyStringInput",
    Placeholder = "Enter text...",
    Default = "dummyDefaultText",
    Flag = "dummyString_Flag",
    Callback = function(text)
        print("Text updated to:", text)
    end,
})

-- Number Input
GeneralSection:CreateInput({
    Title = "dummyNumberInput",
    Placeholder = "70",
    Default = 70,
    Min = 30,
    Max = 120,
    Flag = "dummyNumber_Flag",
    Callback = function(value)
        print("Number updated to:", value)
    end,
})

```

### 🎨 Color Picker & 🔑 Keybind (Standalone)

```lua
GeneralSection:CreateColorPicker({
    Title = "dummyColorPicker",
    Default = Color3.fromRGB(51, 144, 236),
    Flag = "dummyColorPicker_Flag",
    Callback = function(color)
        VariaUI:SetTheme({ Secondary = color })
    end,
})

GeneralSection:CreateKeybind({
    Title = "dummyKeybind",
    Default = Enum.KeyCode.End,
    Flag = "dummyKeybind_Flag",
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
| `Component:SetValue(value)` | Forces the component to a new value and triggers its callback.|
| `Component:GetValue()` | Returns the current value of the component.|
| `Component:AddKeybind(config)` | Appends an inline keybind button to the right side of the row.|
| `Component:AddColorPicker(config)` | Appends an inline color picker to the right side of the row.|

```lua
local dummyToggleRef = GeneralSection:CreateToggle({ Title = "dummyState", Flag = "dummyState_Flag" })

-- Force it on via script
dummyToggleRef:SetValue(true)

-- Read the state later
if dummyToggleRef:GetValue() == true then
    print("State is currently active!")
end

```

---

## ⚙️ 6. Library Utilities & Config Saving

These functions are called directly on the library and handle configuration saving, notification dispatching, and theming.

### Configuration Saving & Loading

VariaUI uses unique `Flag` strings to manage states. It automatically formats `Color3` values and keybinds safely for JSON encoding. You can use the `OnChange` method to create a highly efficient auto-save system!

```lua
local HttpService = game:GetService("HttpService")
local saveFileName = "dummyConfig.json"

-- AUTO-SAVING: Fires automatically whenever a user changes a setting (slider, toggle, etc.)
Window:OnChange(function(currentSettings)
    -- currentSettings is already a safe, formatted table!
    local jsonString = HttpService:JSONEncode(currentSettings)
    DummySaveFunction(saveFileName, jsonString)
    print("Configuration auto-saved!")
end)

-- LOADING & STARTUP: Load your settings and initialize the UI in one step
local savedTable = nil
local loadedJson = DummyLoadFunction(saveFileName)

if loadedJson then
    savedTable = HttpService:JSONDecode(loadedJson)
end

-- Initialize the window with the saved data, and choose whether it starts minimized
local startMinimized = false
Window:StartUp(savedTable, startMinimized)

```

### Notifications

Trigger a clean, animated on-screen toast notification.

```lua
VariaUI:Notify({
    Title = "Success!",
    Content = "Your dummy configuration has been applied successfully.",
    Duration = 3.5 -- Display duration in seconds
})

```

### Dynamic Theming

Update the global theme colors dynamically. VariaUI automatically re-renders all existing components to flawlessly match the new theme.

```lua
VariaUI:SetTheme({
    Background = Color3.fromRGB(15, 15, 20),
    Elevated = Color3.fromRGB(22, 22, 28),
    Secondary = Color3.fromRGB(0, 255, 127), -- Neon Green
    TextPrimary = Color3.fromRGB(255, 255, 255),
    UseGradient = false
})

```
