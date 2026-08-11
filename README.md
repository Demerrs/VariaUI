
# **<p align="center">🎨 VariaUI</p>**

# 🌟 VariaUI | API Documentation
## 1. Initialization
To begin using VariaUI, you must first load the library via `loadstring` and then initialize a **Window**.

```lua
local url = "https://raw.githubusercontent.com/Demerrs/VariaUI/refs/heads/main/VariaUI.lua"
local UILibrary = loadstring(game:HttpGet(url))()

local Window = UILibrary:CreateWindow({
    Title = "MyTitle",
    SubTitle = "SubTitle",
    Size = UDim2.new(0, 560, 0, 380), -- Optional
    MinSize = Vector2.new(380, 280),  -- Optional
    MaxSize = Vector2.new(1000, 720), -- Optional
    ToggleKey = Enum.KeyCode.RightShift, -- Optional
    OnClose = function()
        print("Window closed!")
    end
})
```
## 2. Window Management Methods

Once your `Window` is created, you can use the following methods to manage it.

| Method | Description |
| --- | --- |
| `Window:SetVisible(boolean)` | Hides or shows the entire UI without destroying it. |
| `Window:Minimize()` | Minimizes the UI into a floating icon bubble. |
| `Window:Restore()` | Restores the UI from the minimized bubble state. |
| `Window:ToggleMinimize()` | Toggles between the minimized and restored states. |
| `Window:Destroy()` | Completely deletes the UI from the screen. |
| `Window:OnClose(callback)` | Overrides or sets the function that runs when the "X" button is clicked. |
| `Window:SetWindowIcon(assetId)` | Changes the window icon asset ID. |
| `Window:SetBubbleIcon(assetId)` | Changes the minimized bubble icon asset ID. |
| `Window:SetToggleKey(keyCode)` | Changes the keyboard shortcut key to show/hide the menu. |
| `Window:CreateTabCategory(name, textColor)` | Creates a sidebar category header. |
| `Window:CreateTab(config)` | Creates a new tab page in the sidebar. |
| `Window:CreateThemeTab(config)` | Generates a built-in "Theme Settings" tab. |

## 3. Layout: Categories, Tabs & Sections

VariaUI organizes content into **Categories**, **Tabs**, and **Sections**, allowing you to structure your user interface cleanly.

```lua
-- Creates a non-clickable text label in the sidebar to group tabs
Window:CreateTabCategory("Main Features")

-- Creates a clickable tab in the sidebar
local MainTab = Window:CreateTab({
    Name = "MainTabName",
    Icon = "rbxassetid://...", -- Optional asset ID
    Columns = 1, -- Optional layout columns for elements inside the tab
    RowHeight = 44 -- Optional row height for grid layouts
})

-- Creates a visual grouping inside a tab
local NewSection = MainTab:CreateSection("NewSection Name", nil, 1, 44)

```

> **Important Note:** All UI elements can be parented directly to a `Tab` or a `Section`. Additionally, components support auxiliary chaining methods like `:AddKeybind()` and `:AddColorPicker()`.

## 4. UI Components

### Button

Creates a simple clickable button.

```lua
local MyButton = NewSection:CreateButton({
    Title = "Test Button",
    Description = "This executes a print function.",
    TextColor = Color3.fromRGB(255, 255, 255), -- Optional
    Callback = function()
        print("Button clicked!")
    end,
})

-- Button specific API:
MyButton:SetTitle("New Title")

```

### Toggle

Creates an on/off switch component.

```lua
local MyToggle = NewSection:CreateToggle({
    Title = "Test Toggle",
    Description = "ON/OFF Toggle for configuration.",
    Default = false,
    Flag = "Test_Toggle_Flag", -- Used for saving settings
    Callback = function(state)
        print("Toggle is now:", state)
    end,
})

-- Can chain auxiliary inputs:
MyToggle:AddKeybind({
    Title = "Toggle Shortcut",
    Default = Enum.KeyCode.E,
    Flag = "Toggle_Keybind_Flag"
}):AddColorPicker({
    Title = "Toggle Accent",
    Default = Color3.fromRGB(51, 144, 236),
    Flag = "Toggle_Color_Flag"
})

```

### Slider

Creates a draggable slider for numerical adjustments.

```lua
local MySlider = NewSection:CreateSlider({
    Title = "Test Slider",
    Description = "Adjust your numerical value.",
    Min = 0,
    Max = 100,
    Default = 50,
    Increment = 1,
    Flag = "Test_Slider_Flag",
    Callback = function(value)
        print("Slider value:", value)
    end,
})

```

### Dropdown (Single)

Creates a dropdown menu where only one option can be selected at a time.

```lua
local MyDropdown = NewSection:CreateDropdown({
    Title = "Test Dropdown",
    Description = "Choose a selection option.",
    Options = {"OptionA", "OptionB", "OptionC"},
    Default = "OptionA",
    Flag = "Test_Dropdown_Flag",
    ExpandColumns = 1, -- Optional expanded grid columns for search view
    Callback = function(selectedValue)
        print("Chosen option:", selectedValue)
    end,
})

```

### Multi-Dropdown

Creates a dropdown menu where multiple options can be selected simultaneously.

```lua
local MyMultiDrop = NewSection:CreateMultiDropdown({
    Title = "Test Multi-Dropdown",
    Description = "Choose multiple options.",
    Options = {"Item1", "Item2", "Item3", "Item4"},
    Default = {"Item1", "Item3"},
    Flag = "Test_Multi_Flag",
    ExpandColumns = 2,
    Callback = function(selectedList)
        print("Items selected:", table.concat(selectedList, ", "))
    end,
})

```

### Text Input (Number & String)

Creates a text box. Use `CreateInput` for numbers and `CreateStringInput` for standard text strings.

```lua
-- Number Input
local NumInput = NewSection:CreateInput({
    Title = "Test Number Input",
    Placeholder = "Enter number...",
    Default = 10,
    Min = 1,      -- Optional
    Max = 100,    -- Optional
    Flag = "Test_Num_Flag",
    Callback = function(value)
        print("Number set to:", value)
    end,
})

-- String Input
local StrInput = NewSection:CreateStringInput({
    Title = "Test String Input",
    Placeholder = "Enter text...",
    Default = "Hello World",
    Flag = "Test_Str_Flag",
    Callback = function(text)
        print("Text set to:", text)
    end,
})

```

### Color Picker

Creates a pop-out color wheel for selecting Color3 values.

```lua
local MyColor = NewSection:CreateColorPicker({
    Title = "Test Color Picker",
    Description = "Select a theme color component.",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "Test_Color_Flag",
    Callback = function(color)
        print("New color selected:", color)
    end,
})

```

### Keybind

Creates an interactive key binding component.

```lua
local MyKeybind = NewSection:CreateKeybind({
    Title = "Test Keybind",
    Description = "Press a key to bind an action.",
    Default = Enum.KeyCode.F,
    Flag = "Test_Keybind_Flag",
    Callback = function(key)
        print("Bound key triggered:", key.Name)
    end,
    ChangedCallback = function(newKey)
        print("Key changed to:", newKey.Name)
    end,
})

```

### Label

Creates a simple text label without any interactable elements.

```lua
local MyLabel = NewSection:CreateLabel({
    Title = "Test Label Header",
    Description = "Static descriptive info text.",
    TextColor = Color3.fromRGB(200, 200, 200)
})

-- Label specific API:
MyLabel:SetText("Updated Label Header")

```

## 5. Component API Methods

Most components return an API object that allows you to programmatically change or read their values later in your script.

| Method | Description |
| --- | --- |
| `Component:SetValue(value)` | Updates the UI component to the provided value and triggers its callback. |
| `Component:GetValue()` | Returns the current value of the component. |
| `Component:AddKeybind(config)` | Appends an inline keybind element onto the row. |
| `Component:AddColorPicker(config)` | Appends an inline color picker element onto the row. |

**Example:**

```lua
local MyToggle = NewSection:CreateToggle({ Title = "Example Toggle", Flag = "Ex_Toggle" })

-- Turn the toggle on via script
MyToggle:SetValue(true)

-- Check if it is on
local isOn = MyToggle:GetValue()
print(isOn)

```

## 6. Library & Settings Management

These functions are called directly on `UILibrary` and handle configuration saving, notification dispatching, and theming.

`UILibrary:GetSettings()` Returns a dictionary of all active `Flags` and their current values. `Color3` values are automatically formatted safely for data encoding.

```lua
local currentConfig = UILibrary:GetSettings()
local jsonString = game:GetService("HttpService"):JSONEncode(currentConfig)

```

`UILibrary:LoadSettings(table)` Takes a decoded table and automatically applies the saved values to all corresponding UI elements, triggering their callbacks.

```lua
local savedTable = game:GetService("HttpService"):JSONDecode(jsonString)
UILibrary:LoadSettings(savedTable)

```

`UILibrary:Notify(config)` Triggers a clean on-screen notification toast element.

```lua
UILibrary:Notify({
    Title = "Notification Title",
    Content = "This is a prompt message description.",
    Duration = 3.5 -- Optional display duration in seconds
})

```

`UILibrary:SetTheme(overrides)` Dynamically updates the global theme colors or properties.

```lua
UILibrary:SetTheme({
    Background = Color3.fromRGB(15, 15, 20),
    UseGradient = true
})

```

`UILibrary:GetTargetGuiName()` Returns a string description of the active UI storage container (e.g. `Protected UI (gethui)`).

```lua
print(UILibrary:GetTargetGuiName())

```

`Window:CreateThemeTab()` A built-in utility function that automatically generates a fully functional "Theme Settings" tab with functional color pickers, settings controls, and a storage container information display.

```lua
Window:CreateThemeTab()
```
