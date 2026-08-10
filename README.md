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
| :--- | :---: |
| `Window:SetVisible(boolean)` | Hides or shows the entire UI without destroying it. |
| `Window:Minimize()` | Minimizes the UI into a floating icon bubble. |
| `Window:Restore()` | Restores the UI from the minimized bubble state. |
| `Window:ToggleMinimize()` | Toggles between the minimized and restored states. |
| `Window:Destroy()` | Completely deletes the UI from the screen. |
| `Window:OnClose(callback)` | Overrides or sets the function that runs when the "X" button is clicked. |

## 3. Layout: Tabs & Sections
VariaUI organizes content into **Categories**, **Tabs**, and **Sections**.

```lua
-- Creates a non-clickable text label in the sidebar to group tabs
Window:CreateTabCategory("Main Features")

-- Creates a clickable tab in the sidebar
local MainTab = Window:CreateTab({
    Name = "MainTabName",
    Icon = "rbxassetid://..." -- Optional
})

-- Creates a visual grouping inside the tab
local NewSection = MainTab:CreateSection("NewSection Name")
```
> **Important Note:** All UI elements (Buttons, Toggles, etc.) can be parented directly to a `Tab` or a `Section`.

## 4. UI Components
### Button
Creates a simple clickable button.

```lua
local MyButton = NewSection:CreateButton({
    Title = "Click Me",
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
Creates an on/off switch.

```lua
local MyToggle = NewSection:CreateToggle({
    Title = "Toggle Title",
    Description = "ON/OFF Toggle for something...",
    Default = false,
    Flag = "Auto_Toggle", -- Used for saving settings
    Callback = function(state)
        print("Toggle is now:", state)
    end,
})
```

### Slider
Creates a draggable slider for numerical values.

```lua
local MySlider = NewSection:CreateSlider({
    Title = "NewSlider",
    Description = "Adjust your slider.",
    Min = 16,
    Max = 100,
    Default = 16,
    Increment = 1,
    Flag = "New_Slider",
    Callback = function(value)
        print(value)
    end,
})
```

### Dropdown (Single)
Creates a dropdown menu where only one option can be selected at a time.

```lua
local MyDropdown = NewSection:CreateDropdown({
    Title = "Select Target",
    Description = "Choose a target.",
    Options = {"Tag1", "Tag2", "Tag3"},
    Default = "Tag1",
    Flag = "Target_Dropdown",
    Callback = function(selectedValue)
        print("Chosen:", selectedValue)
    end,
})
```

### Multi-Dropdown
Creates a dropdown menu where multiple options can be selected simultaneously.

```lua
local MyMultiDrop = NewSection:CreateMultiDropdown({
    Title = "Select Items",
    Description = "Choose items to keep.",
    Options = {"Sword", "Shield", "Potion", "Armor"},
    Default = {"Sword", "Potion"},
    Flag = "Items_Multi",
    Callback = function(selectedList)
        -- Returns a table of selected strings
        print("Items selected:", table.concat(selectedList, ", "))
    end,
})
```

### Text Input (Number & String)
Creates a text box. Use CreateInput for numbers and CreateStringInput for standard text.

```lua
-- Number Input
local NumInput = NewSection:CreateInput({
    Title = "Custom Health",
    Placeholder = "100",
    Default = 100,
    Min = 1,     -- Optional
    Max = 1000,  -- Optional
    Flag = "Health_Input",
    Callback = function(value)
        print("Health set to:", value)
    end,
})

-- String Input
local StrInput = NewSection:CreateStringInput({
    Title = "Custom Name",
    Placeholder = "Enter name...",
    Default = "Player1",
    Flag = "Name_Input",
    Callback = function(text)
        print("Name set to:", text)
    end,
})
```

### Color Picker
Creates a pop-out color wheel for selecting Color3 values.

```lua
local MyColor = NewSection:CreateColorPicker({
    Title = "ESP Color",
    Description = "Color of the enemy highlights.",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "ESP_Color",
    Callback = function(color)
        print("New color selected:", color)
    end,
})
```

### Label
Creates a simple text label without any interactable elements.

```lua
local MyLabel = NewSection:CreateLabel({
    Title = "Status: Idle",
    Description = "Waiting for input...",
    TextColor = Color3.fromRGB(200, 200, 200)
})

-- Label specific API:
MyLabel:SetText("Status: Doing something")
```

## 5. Component API Methods
Most components (Toggles, Sliders, Dropdowns, Inputs, and Color Pickers) return an API object that allows you to programmatically change or read their values later in your script.


| Method | Description |
| :--- | :---: |
| `Component:SetValue(value)` | Updates the UI component to the provided value and triggers its callback. |
| `Component:GetValue()` | Returns the current value of the component. |

**Example:**

```lua
local MyToggle = NewSection:CreateToggle({ Title = "Example", Flag = "Ex" })

-- Turn the toggle on via script
MyToggle:SetValue(true)

-- Check if it is on
local isOn = MyToggle:GetValue()
```

## 6. Library & Settings Management
These functions are called directly on `UILibrary` and handle configuration saving and theming.

`UILibrary:GetSettings()` Returns a dictionary of all active `Flags` and their current values. `Color3` values are automatically formatted safely for JSON encoding.
```lua
local currentConfig = UILibrary:GetSettings()
local jsonString = game:GetService("HttpService"):JSONEncode(currentConfig)
```

`UILibrary:LoadSettings(table)` Takes a decoded JSON table and automatically applies the saved values to all corresponding UI elements, triggering their callbacks.
```lua
local savedTable = game:GetService("HttpService"):JSONDecode(jsonString)
UILibrary:LoadSettings(savedTable)
```

`Window:CreateThemeTab()` A built-in utility function that automatically generates a fully functional "Theme Settings" tab with functional color pickers and your custom Discord Webhook inputs.
```lua
Window:CreateThemeTab()
```


