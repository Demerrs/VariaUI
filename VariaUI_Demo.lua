--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UILibrary = require(ReplicatedStorage:WaitForChild("VariaUI")) :: any

-- ============================================================
-- Window
-- ============================================================

local Window = UILibrary:CreateWindow({
	Title = "VariaUI Test Rig",
	SubTitle = "All Elements / All Combinations",
	Size = UDim2.new(0, 620, 0, 440),
	MinSize = Vector2.new(340, 280),
	MaxSize = Vector2.new(1100, 760),
	ToggleKey = Enum.KeyCode.RightControl,
	StartHidden = false,
	OnClose = function()
		print("[VariaUI Demo] Window closed")
	end,
})

Window:CreateTabCategory("Core Elements")

-- ============================================================
-- Tab 1: Toggles & Buttons (single column, title/desc combos)
-- ============================================================

local togglesTab = Window:CreateTab({ Name = "Toggles/Buttons", Columns = 1 })

do
	local basic = togglesTab:CreateSection("Toggle — Combinations")

	basic:CreateToggle({
		Title = "Short toggle",
		Default = false,
		Flag = "Toggle_Short",
		Callback = function(v) print("Toggle_Short ->", v) end,
	})

	basic:CreateToggle({
		Title = "Short toggle, default on",
		Default = true,
		Flag = "Toggle_ShortOn",
	})

	basic:CreateToggle({
		Title = "Toggle with a description line under the title",
		Description = "This is the description text, shown below the title.",
		Default = false,
		Flag = "Toggle_Desc",
	})

	basic:CreateToggle({
		Title = "A deliberately very long toggle title that will not fit next to the switch on a narrow window",
		Default = false,
		Flag = "Toggle_LongTitle",
	})

	basic:CreateToggle({
		Title = "Very long title AND a very long description, together, to test the worst-case stacked layout height",
		Description = "This description is also long on purpose, so we can confirm the stacked control line sits below both lines of text cleanly with no overlap.",
		Default = true,
		Flag = "Toggle_LongBoth",
	})

	local withExtras = togglesTab:CreateSection("Toggle — Chained Extras")

	withExtras:CreateToggle({
		Title = "Toggle + AddKeybind",
		Flag = "Toggle_Keybind",
	}):AddKeybind({
		Default = Enum.KeyCode.G,
		Flag = "Toggle_Keybind_Key",
	})

	withExtras:CreateToggle({
		Title = "Toggle + AddColorPicker",
		Flag = "Toggle_Color",
	}):AddColorPicker({
		Default = Color3.fromRGB(255, 80, 80),
		Flag = "Toggle_Color_Value",
	})

	withExtras:CreateToggle({
		Title = "Long toggle title with BOTH a keybind and a color picker chained on, to really squeeze the row",
		Description = "Every extra control should still line up on the same control line when stacked.",
		Flag = "Toggle_Everything",
	}):AddKeybind({
		Default = Enum.KeyCode.H,
		Flag = "Toggle_Everything_Key",
	}):AddColorPicker({
		Default = Color3.fromRGB(80, 180, 255),
		Flag = "Toggle_Everything_Color",
	})

	local buttons = togglesTab:CreateSection("Buttons")

	buttons:CreateButton({
		Title = "Short button",
		Callback = function() UILibrary:Notify({ Title = "Button", Content = "Short button pressed.", Duration = 2.5 }) end,
	})

	buttons:CreateButton({
		Title = "Button with a description",
		Description = "Runs a task when clicked.",
		Callback = function() print("Described button pressed") end,
	})

	buttons:CreateButton({
		Title = "A very long button title that should wrap the Run button to its own line once the window gets narrow enough",
		Callback = function() print("Long button pressed") end,
	})

	buttons:CreateButton({
		Title = "Button + AddKeybind",
	}):AddKeybind({
		Default = Enum.KeyCode.F,
		Callback = function() print("Keybind-triggered button fired") end,
	})

	buttons:CreateButton({
		Title = "Button + AddColorPicker",
	}):AddColorPicker({
		Default = Color3.fromRGB(120, 255, 150),
		Callback = function(c) print("Button color ->", c) end,
	})

	local keybinds = togglesTab:CreateSection("Standalone Keybind")

	keybinds:CreateKeybind({
		Title = "Short keybind",
		Default = Enum.KeyCode.E,
		Callback = function(key) print("Keybind pressed:", key.Name) end,
	})

	keybinds:CreateKeybind({
		Title = "Keybind with description and a longer title to force stacking on narrow widths",
		Description = "Press the bound key to trigger the callback.",
		Default = Enum.KeyCode.Q,
	})
end

-- ============================================================
-- Tab 2: Sliders, Inputs, Text (single column)
-- ============================================================

local inputsTab = Window:CreateTab({ Name = "Sliders/Inputs" })

do
	local sliders = inputsTab:CreateSection("Sliders")

	sliders:CreateSlider({
		Title = "Short slider",
		Min = 0, Max = 100, Default = 50, Increment = 1,
		Flag = "Slider_Short",
	})

	sliders:CreateSlider({
		Title = "Slider with description",
		Description = "Adjusts a value between 0 and 10, in steps of 0.5.",
		Min = 0, Max = 10, Default = 2.5, Increment = 0.5,
		Flag = "Slider_Desc",
	})

	sliders:CreateSlider({
		Title = "A very long slider title to test how the value label and title share the top row",
		Min = -50, Max = 50, Default = 0, Increment = 5,
		Flag = "Slider_Long",
	})

	local numbers = inputsTab:CreateSection("Numeric Input")

	numbers:CreateInput({
		Title = "Short input",
		Min = 0, Max = 999, Default = 10,
		Flag = "Input_Short",
	})

	numbers:CreateInput({
		Title = "Input with description and min/max bounds",
		Description = "Clamped between 1 and 20.",
		Min = 1, Max = 20, Default = 5, Placeholder = "1-20",
		Flag = "Input_Desc",
	})

	numbers:CreateInput({
		Title = "A long numeric input title that pushes the input box to the next line when narrow",
		Default = 0,
	}):AddKeybind({
		Default = Enum.KeyCode.N,
	})

	local strings = inputsTab:CreateSection("String Input")

	strings:CreateStringInput({
		Title = "Short text field",
		Placeholder = "Type here...",
		Flag = "String_Short",
	})

	strings:CreateStringInput({
		Title = "Text field with description",
		Description = "Click the ↗ to expand into a larger multi-line editor.",
		Default = "Hello, world!",
		Flag = "String_Desc",
	})

	strings:CreateStringInput({
		Title = "A long text field title, description, and long default value all at once",
		Description = "This combination stresses both the row stacking and the expand-panel sync.",
		Default = "This is a longer default string value to test wrapping and truncation behavior.",
		Flag = "String_Long",
	})

	local labels = inputsTab:CreateSection("Labels")

	labels:CreateLabel({ Title = "Short label" })
	labels:CreateLabel({
		Title = "Label with description",
		Description = "Labels are non-interactive, but should still stack cleanly if needed.",
	})
	labels:CreateLabel({ Title = "A long label title with no description at all, just informational text for the user to read" })
end

-- ============================================================
-- Tab 3: Dropdowns, MultiDropdowns, PriorityList, ColorPicker
-- ============================================================

local pickersTab = Window:CreateTab({ Name = "Dropdowns/Lists" })

do
	local dropdowns = pickersTab:CreateSection("Dropdowns")

	dropdowns:CreateDropdown({
		Title = "Short dropdown",
		Options = { "Alpha", "Beta", "Gamma" },
		Default = "Alpha",
		Flag = "Dropdown_Short",
	})

	dropdowns:CreateDropdown({
		Title = "Dropdown with description",
		Description = "Pick one option.",
		Options = { "Low", "Medium", "High" },
		Default = "Medium",
		Flag = "Dropdown_Desc",
	})

	dropdowns:CreateDropdown({
		Title = "A very long dropdown title that forces the Display/Expand buttons onto their own control line",
		Options = { "None", "Option One", "Option Two", "Option Three", "Option Four" },
		Default = "None",
		NoneOptions = { "None" },
		Flag = "Dropdown_Long",
	})

	dropdowns:CreateDropdown({
		Title = "Dropdown with ExpandColumns",
		Description = "Opening the expand panel lays options out in 2 columns.",
		Options = { "Red", "Orange", "Yellow", "Green", "Blue", "Indigo", "Violet", "Pink" },
		Default = "Red",
		ExpandColumns = 2,
		Flag = "Dropdown_Columns",
	})

	local multi = pickersTab:CreateSection("Multi-Dropdowns")

	multi:CreateMultiDropdown({
		Title = "Short multi-select",
		Options = { "Fire", "Water", "Earth", "Air" },
		Default = { "Fire", "Water" },
		Flag = "Multi_Short",
	})

	multi:CreateMultiDropdown({
		Title = "Multi-select with description and long option list, ExpandColumns = 3",
		Description = "Select multiple tags.",
		Options = { "Tag1", "Tag2", "Tag3", "Tag4", "Tag5", "Tag6", "Tag7", "Tag8", "Tag9" },
		ExpandColumns = 3,
		Flag = "Multi_Columns",
	})

	local colors = pickersTab:CreateSection("Color Pickers")

	colors:CreateColorPicker({
		Title = "Short color picker",
		Default = Color3.fromRGB(255, 255, 255),
		Flag = "Color_Short",
	})

	colors:CreateColorPicker({
		Title = "A long color picker title with a description, to test the swatch dropping to its own line",
		Description = "Click the swatch to open the picker.",
		Default = Color3.fromRGB(200, 120, 255),
		Flag = "Color_Long",
	})

	local priority = pickersTab:CreateSection("Priority List")

	priority:CreatePriorityList({
		Title = "Short priority list",
		Items = { "First", "Second", "Third" },
		Flag = "Priority_Short",
	})

	priority:CreatePriorityList({
		Title = "A long priority list title with a description explaining what the ordering controls",
		Description = "Drag items, or use the arrow buttons, to reorder them.",
		Items = { "Weapon A", "Weapon B", "Weapon C", "Weapon D", "Weapon E" },
		Flag = "Priority_Long",
		Callback = function(items) print("Priority order ->", table.concat(items, ", ")) end,
	})
end

-- ============================================================
-- Tab 4: Multi-column Sections + Expandable Groups (grid collapse)
-- ============================================================

local columnsTab = Window:CreateTab({ Name = "Columns (2)", Columns = 2 })

do
	local left = columnsTab:CreateSection("Left Column", nil, 1) -- goes into Column 1
	left:CreateToggle({ Title = "Left toggle A", Flag = "Col_LeftA" })
	left:CreateToggle({ Title = "Left toggle B with description", Description = "Second toggle in the left column.", Flag = "Col_LeftB" })
	left:CreateSlider({ Title = "Left slider", Min = 0, Max = 100, Default = 25, Flag = "Col_LeftSlider" })

	local right = columnsTab:CreateSection("Right Column") -- goes into Column 2
	right:CreateDropdown({ Title = "Right dropdown", Options = { "One", "Two", "Three" }, Default = "One", Flag = "Col_RightDropdown" })
	right:CreateButton({ Title = "Right button", Callback = function() print("Right column button") end })
	right:CreateInput({ Title = "Right input", Default = 0, Flag = "Col_RightInput" })

	-- A grid section (numColumns > 1) inside a page-column, so we're
	-- testing BOTH the page-level column collapse and the grid's own
	-- column collapse at the same time as the window narrows.
	local grid2 = columnsTab:CreateSection("2-Wide Grid", nil, 2, 44)
	grid2:CreateToggle({ Title = "Grid A", Flag = "Grid2_A" })
	grid2:CreateToggle({ Title = "Grid B", Flag = "Grid2_B" })
	grid2:CreateToggle({ Title = "Grid C", Flag = "Grid2_C" })
	grid2:CreateToggle({ Title = "Grid D", Flag = "Grid2_D" })
end

-- ============================================================
-- Tab 5: Wide grid sections + expandable groups (single column page)
-- ============================================================

local gridsTab = Window:CreateTab({ Name = "Grids/Groups" })

do
	local grid3 = gridsTab:CreateSection("3-Column Grid Section", nil, 3, 44)
	for i = 1, 6 do
		grid3:CreateToggle({ Title = "Grid Toggle " .. i, Flag = "Grid3_" .. i })
	end

	local groupHost = gridsTab:CreateSection("Expandable Groups")

	local group1 = groupHost:CreateExpandableGroup("Basic Group (1 column)", true)
	group1:CreateToggle({ Title = "Group toggle", Flag = "Group1_Toggle" })
	group1:CreateSlider({ Title = "Group slider", Min = 0, Max = 100, Default = 50, Flag = "Group1_Slider" })
	group1:CreateDropdown({ Title = "Group dropdown", Options = { "A", "B", "C" }, Default = "A", Flag = "Group1_Dropdown" })

	local group2 = groupHost:CreateExpandableGroup("Grid Group (2 columns, collapsed)", false, 2, 42)
	for i = 1, 4 do
		group2:CreateToggle({ Title = "Group2 Toggle " .. i, Flag = "Group2_" .. i })
	end

	local group3 = groupHost:CreateExpandableGroup(
		"Group with a long title that itself might need attention, expanded by default",
		true
	)
	group3:CreateStringInput({ Title = "Nested string input", Placeholder = "...", Flag = "Group3_String" })
	group3:CreateColorPicker({ Title = "Nested color picker", Default = Color3.fromRGB(255, 200, 0), Flag = "Group3_Color" })
end

-- ============================================================
-- Tab 6: Built-in Theme & Integration tabs
-- ============================================================

Window:CreateTabCategory("Built-in")
Window:CreateThemeTab()
Window:CreateIntegrationTab()

-- ============================================================
-- Misc: Notify, OnChange, StartUp
-- ============================================================

Window:OnChange(function(settings)
	print("[VariaUI Demo] Settings changed:", settings)
end)

task.delay(1, function()
	UILibrary:Notify({
		Title = "Demo Loaded",
		Content = "Try resizing the window (drag the bottom-right corner) to see rows and columns respond.",
		Duration = 5,
	})
end)

Window:StartUp() -- makes the window visible; pass StartUp(savedSettings) to restore state
