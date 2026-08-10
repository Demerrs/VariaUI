--!strict
--!optimize 2

--[[
	UILibrary
	A lightweight, Varia UI framework for Roblox. All rights reserved.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local TargetGui = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- Types
-- ============================================================

export type ButtonConfig = {
	Title: string,
	Description: string?,
	TextColor: Color3?,
	Callback: (() -> ())?,
}

export type ToggleConfig = {
	Title: string,
	Description: string?,
	TextColor: Color3?,
	Default: boolean?,
	Flag: string?,
	Callback: ((value: boolean) -> ())?,
}

export type SliderConfig = {
	Title: string,
	Description: string?,
	TextColor: Color3?,
	Min: number,
	Max: number,
	Default: number?,
	Increment: number?,
	Flag: string?,
	Callback: ((value: number) -> ())?,
}

export type DropdownConfig = {
	Title: string,
	Description: string?,
	TextColor: Color3?,
	Options: { string },
	Default: string?,
	Multi: boolean?,
	Flag: string?,
	Callback: ((value: any) -> ())?,
}

export type MultiDropdownConfig = {
	Title: string,
	Description: string?,
	TextColor: Color3?,
	Options: { string },
	Default: { string }?,
	Flag: string?,
	Callback: ((value: { string }) -> ())?,
}

export type LabelConfig = {
	Title: string,
	Description: string?,
	TextColor: Color3?,
}

export type InputConfig = {
	Title: string,
	Description: string?,
	TextColor: Color3?,
	Min: number?,
	Max: number?,
	Default: number?,
	Placeholder: string?,
	Flag: string?,
	Callback: ((value: number) -> ())?,
}

export type StringInputConfig = {
	Title: string,
	Description: string?,
	TextColor: Color3?,
	Default: string?,
	Placeholder: string?,
	Flag: string?,
	Callback: ((value: string) -> ())?,
}

export type ColorPickerConfig = {
	Title: string,
	Description: string?,
	TextColor: Color3?,
	Default: Color3?,
	Flag: string?,
	Callback: ((color: Color3) -> ())?,
}

export type WindowConfig = {
	Title: string?,
	SubTitle: string?,
	Size: UDim2?,
	MinSize: Vector2?,
	MaxSize: Vector2?,
	ToggleKey: Enum.KeyCode?,
	OnClose: (() -> ())?,
}

export type TabConfig = {
	Name: string,
	Icon: string?,
}

-- ============================================================
-- Theme
-- ============================================================

local Theme = {
	Background = Color3.fromRGB(8, 8, 11),
	BackgroundTransparency = 0.15,
	Elevated = Color3.fromRGB(15, 15, 19),
	ElevatedTransparency = 0.2,
	Border = Color3.fromRGB(40, 40, 46),
	Accent = Color3.fromRGB(51, 144, 236),
	Secondary = Color3.fromRGB(38, 112, 190),
	TextPrimary = Color3.fromRGB(240, 240, 245),
	TextSecondary = Color3.fromRGB(165, 165, 175),
	TextMuted = Color3.fromRGB(115, 115, 125),
	Success = Color3.fromRGB(96, 200, 130),
	Danger = Color3.fromRGB(230, 80, 80),
	Font = Enum.Font.Gotham,
	FontBold = Enum.Font.GothamBold,
	FontSemibold = Enum.Font.GothamSemibold,
	CornerRadius = UDim.new(0, 18),
	CornerRadiusCard = UDim.new(0, 14),
	CornerRadiusSmall = UDim.new(0, 8),
	TweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

-- ============================================================
-- Utilities
-- ============================================================

local function Create(className: string, props: { [string]: any }): any
	local inst = Instance.new(className)
	for key, value in pairs(props) do
		if key == "Parent" then continue end
		(inst :: any)[key] = value
	end
	if props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function AddCorner(parent: Instance, radius: UDim?): UICorner
	return Create("UICorner", {
		CornerRadius = radius or Theme.CornerRadius,
		Parent = parent,
	})
end

local function AddStroke(parent: Instance, color: Color3?, thickness: number?): UIStroke
	return Create("UIStroke", {
		Color = color or Theme.Border,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function AddPadding(parent: Instance, all: number): UIPadding
	return Create("UIPadding", {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all),
		PaddingRight = UDim.new(0, all),
		Parent = parent,
	})
end

local function Tween(inst: Instance, props: { [string]: any }, info: TweenInfo?): Tween
	local t = TweenService:Create(inst :: any, info or Theme.TweenInfo, props)
	t:Play()
	return t
end

local ThemeRefreshCallbacks: { () -> () } = {}

local function RegisterThemeRefresh(fn: () -> ())
	table.insert(ThemeRefreshCallbacks, fn)
end

local function GetOverlay(scope: Instance): Frame
	local screenGui = scope:FindFirstAncestorWhichIsA("ScreenGui")
	assert(screenGui, "UILibrary: element must be parented under a ScreenGui to use an overlay")

	local existing = screenGui:FindFirstChild("__Overlay")
	if existing then
		return existing :: Frame
	end

	return Create("Frame", {
		Name = "__Overlay",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 1000,
		Parent = screenGui,
	}) :: Frame
end

local function MakeDraggable(dragHandle: GuiObject, target: GuiObject)
	local dragging = false
	local dragStart: Vector2
	local startPos: UDim2

	dragHandle.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

local function Round(value: number, increment: number): number
	if increment <= 0 then return value end
	return math.floor((value / increment) + 0.5) * increment
end

-- ============================================================
-- Library
-- ============================================================

local UILibrary = {}
UILibrary.__index = UILibrary

-- Populated automatically whenever a component is created with a `Flag`,
-- and kept in sync as the user interacts with it.
UILibrary.Settings = {} :: { [string]: any }
-- Internal reference registry mapping flags to component API setters
local Registry = {} :: { [string]: any }

-- ---------- Component builders ----------

local function BuildRow(parent: Instance, title: string, description: string?, textColor: Color3?): Frame
	local row = Create("Frame", {
		Name = "Row",
		Size = UDim2.new(1, 0, 0, description and 52 or 42),
		BackgroundColor3 = Theme.Elevated,
		BackgroundTransparency = Theme.ElevatedTransparency,
		Parent = parent,
	})
	AddCorner(row, Theme.CornerRadiusCard)
	AddPadding(row, 14)

	local titleLabel = Create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(0.6, 0, description and 0.55 or 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.FontSemibold,
		Text = title,
		TextColor3 = textColor or Theme.TextPrimary,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	local descLabel
	if description then
		descLabel = Create("TextLabel", {
			Name = "Description",
			Position = UDim2.new(0, 0, 0.55, 0),
			Size = UDim2.new(0.6, 0, 0.45, 0),
			BackgroundTransparency = 1,
			Font = Theme.Font,
			Text = description,
			TextColor3 = Theme.TextSecondary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
	end

	RegisterThemeRefresh(function()
		row.BackgroundColor3 = Theme.Elevated
		titleLabel.TextColor3 = textColor or Theme.TextPrimary
		if descLabel then
			descLabel.TextColor3 = Theme.TextSecondary
		end
	end)

	return row
end

local function CreateButton(parent: Instance, config: ButtonConfig)
	local row = BuildRow(parent, config.Title, config.Description, config.TextColor)

	local button = Create("TextButton", {
		Name = "Button",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 90, 0, 26),
		BackgroundColor3 = Theme.Secondary,
		Font = Theme.FontSemibold,
		Text = "Run",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 13,
		AutoButtonColor = false,
		Parent = row,
	})
	AddCorner(button, Theme.CornerRadiusSmall)

	RegisterThemeRefresh(function()
		button.BackgroundColor3 = Theme.Secondary
	end)

	button.MouseEnter:Connect(function()
		Tween(button, { BackgroundColor3 = Theme.Accent })
	end)
	button.MouseLeave:Connect(function()
		Tween(button, { BackgroundColor3 = Theme.Secondary })
	end)
	button.MouseButton1Click:Connect(function()
		Tween(button, { BackgroundColor3 = Theme.Accent }, TweenInfo.new(0.08))
		task.delay(0.08, function()
			Tween(button, { BackgroundColor3 = Theme.Secondary })
		end)
		if config.Callback then
			task.spawn(config.Callback)
		end
	end)

	return {
		Instance = row,
		SetTitle = function(_self, newTitle: string)
			(row:FindFirstChild("Title") :: TextLabel).Text = newTitle
		end,
	}
end

local function CreateToggle(parent: Instance, config: ToggleConfig)
	local row = BuildRow(parent, config.Title, config.Description, config.TextColor)
	local state = config.Default or false

	if config.Flag then
		UILibrary.Settings[config.Flag] = state
	end

	local track = Create("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 40, 0, 22),
		BackgroundColor3 = state and Theme.Secondary or Theme.Border,
		Parent = row,
	})
	AddCorner(track, UDim.new(1, 0))

	local knob = Create("Frame", {
		Name = "Knob",
		Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0, 18, 0, 18),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = track,
	})
	AddCorner(knob, UDim.new(1, 0))

	local clickArea = Create("TextButton", {
		Name = "ClickArea",
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.new(1, 0, 1, 0),
		Parent = row,
	})

	local function render()
		Tween(track, { BackgroundColor3 = state and Theme.Secondary or Theme.Border })
		Tween(knob, { Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) })
		if config.Flag then
			UILibrary.Settings[config.Flag] = state
		end
	end
	RegisterThemeRefresh(render)

	local api = {}
	function api.SetValue(_self, value: boolean)
		state = value
		render()
	end
	function api.GetValue(_self)
		return state
	end

	if config.Flag then
		Registry[config.Flag] = api
	end

	clickArea.MouseButton1Click:Connect(function()
		state = not state
		render()
		if config.Callback then
			task.spawn(config.Callback, state)
		end
	end)

	return api
end

local function CreateSlider(parent: Instance, config: SliderConfig)
	local increment = config.Increment or 1
	local value = math.clamp(config.Default or config.Min, config.Min, config.Max)

	if config.Flag then
		UILibrary.Settings[config.Flag] = value
	end

	local row = Create("Frame", {
		Name = "Row",
		Size = UDim2.new(1, 0, 0, 72),
		BackgroundColor3 = Theme.Elevated,
		BackgroundTransparency = Theme.ElevatedTransparency,
		Parent = parent,
	})
	AddCorner(row, Theme.CornerRadiusCard)
	AddPadding(row, 16)

	local labelArea = Create("Frame", {
		Name = "LabelArea",
		Size = UDim2.new(0.4, -8, 1, 0),
		BackgroundTransparency = 1,
		Parent = row,
	})

	local titleLabel = Create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.FontBold,
		Text = config.Title,
		TextColor3 = config.TextColor or Theme.TextPrimary,
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = labelArea,
	})

	local trackArea = Create("Frame", {
		Name = "TrackArea",
		Position = UDim2.new(0.4, 8, 0, 0),
		Size = UDim2.new(0.6, -8, 1, 0),
		BackgroundTransparency = 1,
		Parent = row,
	})

	local valueLabel = Create("TextLabel", {
		Name = "Value",
		Size = UDim2.new(0, 44, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.FontSemibold,
		Text = tostring(value),
		TextColor3 = Theme.TextSecondary,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = trackArea,
	})

	local track = Create("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 52, 0.5, 0),
		Size = UDim2.new(1, -52, 0, 14),
		BackgroundColor3 = Theme.Border,
		BackgroundTransparency = 0.35,
		Parent = trackArea,
	})
	AddCorner(track, UDim.new(1, 0))

	local fillRatio = (value - config.Min) / math.max(config.Max - config.Min, 1e-6)
	local fill = Create("Frame", {
		Name = "Fill",
		Size = UDim2.new(fillRatio, 0, 1, 0),
		BackgroundColor3 = Theme.Secondary,
		Parent = track,
	})
	AddCorner(fill, UDim.new(1, 0))

	RegisterThemeRefresh(function()
		row.BackgroundColor3 = Theme.Elevated
		titleLabel.TextColor3 = config.TextColor or Theme.TextPrimary
		valueLabel.TextColor3 = Theme.TextSecondary
		fill.BackgroundColor3 = Theme.Secondary
	end)

	local knob = Create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(fillRatio, 0, 0.5, 0),
		Size = UDim2.new(0, 24, 0, 24),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = track,
	})
	AddCorner(knob, UDim.new(1, 0))

	local dragging = false

	local function setFromRatio(ratio: number)
		ratio = math.clamp(ratio, 0, 1)
		local raw = config.Min + (config.Max - config.Min) * ratio
		value = math.clamp(Round(raw, increment), config.Min, config.Max)
		local newRatio = (value - config.Min) / math.max(config.Max - config.Min, 1e-6)
		fill.Size = UDim2.new(newRatio, 0, 1, 0)
		knob.Position = UDim2.new(newRatio, 0, 0.5, 0)
		valueLabel.Text = tostring(value)
		if config.Flag then
			UILibrary.Settings[config.Flag] = value
		end
	end

	track.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			local ratio = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
			setFromRatio(ratio)
			if config.Callback then
				task.spawn(config.Callback, value)
			end
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local ratio = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
			setFromRatio(ratio)
			if config.Callback then
				task.spawn(config.Callback, value)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	local api = {}
	function api.SetValue(_self, newValue: number)
		setFromRatio((newValue - config.Min) / math.max(config.Max - config.Min, 1e-6))
	end
	function api.GetValue(_self)
		return value
	end

	if config.Flag then
		Registry[config.Flag] = api
	end

	return api
end

local function CreateDropdown(parent: Instance, config: DropdownConfig)
	local isMulti = config.Multi or false
	local selected: { [string]: boolean } = {}
	if isMulti then
	else
		selected[config.Default or config.Options[1]] = true
	end

	local row = BuildRow(parent, config.Title, config.Description, config.TextColor)
	row.ClipsDescendants = false

	local display = Create("TextButton", {
		Name = "Display",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 140, 0, 26),
		BackgroundColor3 = Theme.Background,
		Font = Theme.Font,
		Text = config.Default or "Select...",
		TextColor3 = Theme.TextPrimary,
		TextSize = 13,
		AutoButtonColor = false,
		ZIndex = 5,
		Parent = row,
	})
	AddCorner(display, Theme.CornerRadiusSmall)
	AddStroke(display)

	local overlay = GetOverlay(row)

	local blocker = Create("TextButton", {
		Name = "Blocker",
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 1000,
		Visible = false,
		Parent = overlay,
	})

	local list = Create("Frame", {
		Name = "List",
		Size = UDim2.new(0, 140, 0, math.min(#config.Options * 28, 168)),
		BackgroundColor3 = Theme.Elevated,
		Visible = false,
		ZIndex = 1001,
		ClipsDescendants = true,
		Parent = overlay,
	})
	AddCorner(list, Theme.CornerRadiusSmall)
	AddStroke(list)

	local listLayout = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = list,
	})
	AddPadding(list, 2)

	local scroller = Create("ScrollingFrame", {
		Name = "Scroller",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(0, 0, 0, #config.Options * 28),
		ZIndex = 1001,
		Parent = list,
	})
	listLayout.Parent = scroller

	local open = false
	local function setOpen(value: boolean)
		open = value
		if value then
			local pos = display.AbsolutePosition
			local size = display.AbsoluteSize
			list.Position = UDim2.fromOffset(pos.X + size.X - list.AbsoluteSize.X, pos.Y + size.Y + 4)
		end
		list.Visible = open
		blocker.Visible = open
	end

	blocker.MouseButton1Click:Connect(function()
		setOpen(false)
	end)

	local function updateDisplayText()
		if isMulti then
			local names = {}
			for name, isSelected in pairs(selected) do
				if isSelected then
					table.insert(names, name)
				end
			end
			display.Text = #names > 0 and table.concat(names, ", ") or "Select..."
		else
			for name, isSelected in pairs(selected) do
				if isSelected then
					display.Text = name
					break
				end
			end
		end
	end

	local function syncFlag()
		if not config.Flag then return end
		if isMulti then
			local names = {}
			for name, isSelected in pairs(selected) do
				if isSelected then
					table.insert(names, name)
				end
			end
			UILibrary.Settings[config.Flag] = names
		else
			for name, isSelected in pairs(selected) do
				if isSelected then
					UILibrary.Settings[config.Flag] = name
					break
				end
			end
		end
	end

	local optionButtons: { [string]: TextButton } = {}

	local function refreshHighlight()
		display.BackgroundColor3 = Theme.Background
		display.TextColor3 = Theme.TextPrimary
		list.BackgroundColor3 = Theme.Elevated
		for name, btn in pairs(optionButtons) do
			btn.BackgroundColor3 = selected[name] and Theme.Secondary or Theme.Elevated
			btn.TextColor3 = Theme.TextPrimary
		end
	end
	RegisterThemeRefresh(refreshHighlight)

	for i, option in ipairs(config.Options) do
		local optionButton = Create("TextButton", {
			Name = option,
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = selected[option] and Theme.Secondary or Theme.Elevated,
			AutoButtonColor = false,
			Font = Theme.Font,
			Text = option,
			TextColor3 = Theme.TextPrimary,
			TextSize = 13,
			ZIndex = 10,
			Parent = scroller,
		})
		AddCorner(optionButton, Theme.CornerRadiusSmall)
		optionButtons[option] = optionButton

		optionButton.MouseButton1Click:Connect(function()
			if isMulti then
				selected[option] = not selected[option]
			else
				for name in pairs(selected) do
					selected[name] = false
				end
				selected[option] = true
				setOpen(false)
			end
			refreshHighlight()
			updateDisplayText()
			syncFlag()

			if config.Callback then
				if isMulti then
					local names = {}
					for name, isSelected in pairs(selected) do
						if isSelected then
							table.insert(names, name)
						end
					end
					task.spawn(config.Callback, names)
				else
					task.spawn(config.Callback, option)
				end
			end
		end)
	end

	display.MouseButton1Click:Connect(function()
		setOpen(not open)
	end)

	updateDisplayText()
	syncFlag()

	local api = {}
	function api.SetValue(_self, value: any)
		if isMulti then
			for name in pairs(selected) do
				selected[name] = false
			end
			if type(value) == "table" then
				for _, name in ipairs(value :: { string }) do
					selected[name] = true
				end
			end
		else
			for name in pairs(selected) do
				selected[name] = false
			end
			selected[value :: string] = true
		end
		refreshHighlight()
		updateDisplayText()
		syncFlag()
	end
	function api.GetValue(_self)
		if isMulti then
			local names = {}
			for name, isSelected in pairs(selected) do
				if isSelected then
					table.insert(names, name)
				end
			end
			return names
		end
		for name, isSelected in pairs(selected) do
			if isSelected then
				return name
			end
		end
		return nil
	end

	if config.Flag then
		Registry[config.Flag] = api
	end

	return api
end

local function CreateMultiDropdown(parent: Instance, config: MultiDropdownConfig)
	local seed: { [string]: boolean } = {}
	if config.Default then
		for _, name in ipairs(config.Default :: { string }) do
			seed[name] = true
		end
	end

	local api = CreateDropdown(parent, {
		Title = config.Title,
		Description = config.Description,
		TextColor = config.TextColor,
		Options = config.Options,
		Multi = true,
		Flag = config.Flag,
		Callback = config.Callback,
	} :: DropdownConfig)

	if config.Default then
		api:SetValue(config.Default)
	end

	return api
end

local function CreateLabel(parent: Instance, config: LabelConfig)
	local row = Create("Frame", {
		Name = "Row",
		Size = UDim2.new(1, 0, 0, config.Description and 40 or 24),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	local title = Create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, config.Description and 0.55 or 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.FontSemibold,
		Text = config.Title,
		TextColor3 = config.TextColor or Theme.TextPrimary,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = row,
	})

	local desc
	if config.Description then
		desc = Create("TextLabel", {
			Name = "Description",
			Position = UDim2.new(0, 0, 0.55, 0),
			Size = UDim2.new(1, 0, 0.45, 0),
			BackgroundTransparency = 1,
			Font = Theme.Font,
			Text = config.Description,
			TextColor3 = Theme.TextSecondary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = row,
		})
	end

	RegisterThemeRefresh(function()
		title.TextColor3 = config.TextColor or Theme.TextPrimary
		if desc then
			desc.TextColor3 = Theme.TextSecondary
		end
	end)

	local api = {}
	function api.SetText(_self, text: string)
		title.Text = text
	end

	return api
end

local function CreateInput(parent: Instance, config: InputConfig)
	local row = BuildRow(parent, config.Title, config.Description, config.TextColor)
	local value = config.Default or 0

	if config.Flag then
		UILibrary.Settings[config.Flag] = value
	end

	local box = Create("TextBox", {
		Name = "Input",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 90, 0, 26),
		BackgroundColor3 = Theme.Background,
		Font = Theme.Font,
		PlaceholderText = config.Placeholder or "0",
		Text = config.Default and tostring(config.Default) or "",
		TextColor3 = Theme.TextPrimary,
		PlaceholderColor3 = Theme.TextMuted,
		TextSize = 13,
		ClearTextOnFocus = false,
		Parent = row,
	})
	AddCorner(box, Theme.CornerRadiusSmall)
	AddStroke(box)
	AddPadding(box, 6)

	RegisterThemeRefresh(function()
		box.BackgroundColor3 = Theme.Background
		box.TextColor3 = Theme.TextPrimary
		box.PlaceholderColor3 = Theme.TextMuted
	end)

	local function commit()
		local num = tonumber(box.Text)
		if not num then
			box.Text = tostring(value)
			return
		end
		if config.Min then
			num = math.max(num, config.Min :: number)
		end
		if config.Max then
			num = math.min(num, config.Max :: number)
		end
		value = num
		box.Text = tostring(value)
		if config.Flag then
			UILibrary.Settings[config.Flag] = value
		end
		if config.Callback then
			task.spawn(config.Callback, value)
		end
	end

	box.FocusLost:Connect(function(enterPressed: boolean)
		commit()
	end)

	local api = {}
	function api.SetValue(_self, newValue: number)
		box.Text = tostring(newValue)
		commit()
	end
	function api.GetValue(_self)
		return value
	end

	if config.Flag then
		Registry[config.Flag] = api
	end

	return api
end

local function CreateStringInput(parent: Instance, config: StringInputConfig)
	local row = BuildRow(parent, config.Title, config.Description, config.TextColor)
	local value = config.Default or ""

	if config.Flag then
		UILibrary.Settings[config.Flag] = value
	end

	local box = Create("TextBox", {
		Name = "StringInput",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 160, 0, 26),
		BackgroundColor3 = Theme.Background,
		Font = Theme.Font,
		PlaceholderText = config.Placeholder or "Enter text...",
		Text = value,
		TextColor3 = Theme.TextPrimary,
		PlaceholderColor3 = Theme.TextMuted,
		TextSize = 13,
		ClearTextOnFocus = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	AddCorner(box, Theme.CornerRadiusSmall)
	AddStroke(box)
	AddPadding(box, 6)

	RegisterThemeRefresh(function()
		box.BackgroundColor3 = Theme.Background
		box.TextColor3 = Theme.TextPrimary
		box.PlaceholderColor3 = Theme.TextMuted
	end)

	local function commit()
		value = box.Text
		if config.Flag then
			UILibrary.Settings[config.Flag] = value
		end
		if config.Callback then
			task.spawn(config.Callback, value)
		end
	end

	box.FocusLost:Connect(function(enterPressed: boolean)
		commit()
	end)

	local api = {}
	function api.SetValue(_self, newValue: string)
		box.Text = newValue
		commit()
	end
	function api.GetValue(_self)
		return value
	end

	if config.Flag then
		Registry[config.Flag] = api
	end

	return api
end

local function CreateColorPicker(parent: Instance, config: ColorPickerConfig)
	local row = BuildRow(parent, config.Title, config.Description, config.TextColor)
	local currentColor = config.Default or Color3.fromRGB(255, 0, 0)
	local h, s, v = currentColor:ToHSV()

	if config.Flag then
		UILibrary.Settings[config.Flag] = currentColor
	end

	local swatch = Create("TextButton", {
		Name = "Swatch",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 48, 0, 26),
		BackgroundColor3 = currentColor,
		AutoButtonColor = false,
		Text = "",
		Parent = row,
	})
	AddCorner(swatch, Theme.CornerRadiusSmall)
	AddStroke(swatch)

	local overlay = GetOverlay(row)

	local blocker = Create("TextButton", {
		Name = "Blocker",
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 1000,
		Visible = false,
		Parent = overlay,
	})

	local popup = Create("Frame", {
		Name = "Popup",
		Size = UDim2.new(0, 196, 0, 168),
		BackgroundColor3 = Theme.Elevated,
		BackgroundTransparency = 0.05,
		Visible = false,
		ZIndex = 1001,
		Parent = overlay,
	})
	AddCorner(popup, Theme.CornerRadiusCard)
	AddStroke(popup)
	AddPadding(popup, 14)

	RegisterThemeRefresh(function()
		popup.BackgroundColor3 = Theme.Elevated
	end)

	local svSquare = Create("Frame", {
		Name = "SVSquare",
		Size = UDim2.new(0, 140, 0, 140),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		ZIndex = 1002,
		Parent = popup,
	})
	AddCorner(svSquare, Theme.CornerRadiusSmall)

	local whiteOverlay = Create("Frame", {
		Name = "WhiteOverlay",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 1003,
		Parent = svSquare,
	})
	AddCorner(whiteOverlay, Theme.CornerRadiusSmall)
	Create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = whiteOverlay,
	})

	local blackOverlay = Create("Frame", {
		Name = "BlackOverlay",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 1004,
		Parent = svSquare,
	})
	AddCorner(blackOverlay, Theme.CornerRadiusSmall)
	Create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = blackOverlay,
	})

	local svHitArea = Create("Frame", {
		Name = "HitArea",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Active = true,
		ZIndex = 1006,
		Parent = svSquare,
	})

	local svCursor = Create("Frame", {
		Name = "Cursor",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(s, 0, 1 - v, 0),
		Size = UDim2.new(0, 12, 0, 12),
		BackgroundTransparency = 1,
		ZIndex = 1005,
		Parent = svSquare,
	})
	AddCorner(svCursor, UDim.new(1, 0))
	AddStroke(svCursor, Color3.new(1, 1, 1), 2)

	local hueStrip = Create("Frame", {
		Name = "HueStrip",
		Position = UDim2.new(0, 152, 0, 0),
		Size = UDim2.new(0, 16, 0, 140),
		Active = true,
		ZIndex = 1002,
		Parent = popup,
	})
	AddCorner(hueStrip, UDim.new(1, 0))
	Create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
			ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
			ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
			ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
			ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
			ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
		}),
		Parent = hueStrip,
	})

	local hueCursor = Create("Frame", {
		Name = "Cursor",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, h, 0),
		Size = UDim2.new(1, 4, 0, 4),
		BackgroundTransparency = 1,
		ZIndex = 1005,
		Parent = hueStrip,
	})
	AddCorner(hueCursor, UDim.new(1, 0))
	AddStroke(hueCursor, Color3.new(1, 1, 1), 2)

	local function updateColor()
		currentColor = Color3.fromHSV(h, s, v)
		swatch.BackgroundColor3 = currentColor
		svSquare.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
		hueCursor.Position = UDim2.new(0.5, 0, h, 0)
		if config.Flag then
			UILibrary.Settings[config.Flag] = currentColor
		end
		if config.Callback then
			task.spawn(config.Callback, currentColor)
		end
	end

	local draggingSV = false
	local draggingHue = false

	local function setOpen(value: boolean)
		if value then
			local pos = swatch.AbsolutePosition
			local size = swatch.AbsoluteSize
			popup.Position = UDim2.fromOffset(pos.X + size.X - popup.AbsoluteSize.X, pos.Y + size.Y + 4)
		else
			draggingSV = false
			draggingHue = false
		end
		popup.Visible = value
		blocker.Visible = value
	end

	swatch.MouseButton1Click:Connect(function()
		setOpen(not popup.Visible)
	end)

	blocker.MouseButton1Click:Connect(function()
		setOpen(false)
	end)

	svHitArea.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSV = true
			local relX = (input.Position.X - svSquare.AbsolutePosition.X) / svSquare.AbsoluteSize.X
			local relY = (input.Position.Y - svSquare.AbsolutePosition.Y) / svSquare.AbsoluteSize.Y
			s = math.clamp(relX, 0, 1)
			v = 1 - math.clamp(relY, 0, 1)
			updateColor()
		end
	end)

	hueStrip.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingHue = true
			local relY = (input.Position.Y - hueStrip.AbsolutePosition.Y) / hueStrip.AbsoluteSize.Y
			h = math.clamp(relY, 0, 1)
			updateColor()
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if draggingSV then
			local relX = (input.Position.X - svSquare.AbsolutePosition.X) / svSquare.AbsoluteSize.X
			local relY = (input.Position.Y - svSquare.AbsolutePosition.Y) / svSquare.AbsoluteSize.Y
			s = math.clamp(relX, 0, 1)
			v = 1 - math.clamp(relY, 0, 1)
			updateColor()
		elseif draggingHue then
			local relY = (input.Position.Y - hueStrip.AbsolutePosition.Y) / hueStrip.AbsoluteSize.Y
			h = math.clamp(relY, 0, 1)
			updateColor()
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSV = false
			draggingHue = false
		end
	end)

	local api = {}
	function api.SetValue(_self, color: Color3)
		h, s, v = color:ToHSV()
		updateColor()
	end
	function api.GetValue(_self)
		return currentColor
	end

	if config.Flag then
		Registry[config.Flag] = api
	end

	return api
end

-- ---------- Section ----------

local Section = {}
Section.__index = Section

function Section.new(parent: Instance, title: string, textColor: Color3?)
	local self = setmetatable({}, Section)

	local container = Create("Frame", {
		Name = "Section_" .. title,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = parent,
	})

	local header = Create("TextLabel", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Font = Theme.FontBold,
		Text = title,
		TextColor3 = textColor or Theme.TextMuted,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	local list = Create("Frame", {
		Name = "Items",
		Position = UDim2.new(0, 0, 0, 26),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = container,
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = list,
	})

	RegisterThemeRefresh(function()
		header.TextColor3 = textColor or Theme.TextMuted
	end)

	self._container = container
	self._list = list
	return self
end

function Section:CreateButton(config: ButtonConfig)
	return CreateButton(self._list, config)
end

function Section:CreateToggle(config: ToggleConfig)
	return CreateToggle(self._list, config)
end

function Section:CreateSlider(config: SliderConfig)
	return CreateSlider(self._list, config)
end

function Section:CreateDropdown(config: DropdownConfig)
	return CreateDropdown(self._list, config)
end

function Section:CreateMultiDropdown(config: MultiDropdownConfig)
	return CreateMultiDropdown(self._list, config)
end

function Section:CreateLabel(config: LabelConfig)
	return CreateLabel(self._list, config)
end

function Section:CreateInput(config: InputConfig)
	return CreateInput(self._list, config)
end

function Section:CreateStringInput(config: StringInputConfig)
	return CreateStringInput(self._list, config)
end

function Section:CreateColorPicker(config: ColorPickerConfig)
	return CreateColorPicker(self._list, config)
end

-- ---------- Tab ----------

local Tab = {}
Tab.__index = Tab

function Tab.new(pageContainer: ScrollingFrame, tabButton: TextButton)
	local self = setmetatable({}, Tab)
	self._page = pageContainer
	self._button = tabButton
	return self
end

function Tab:CreateSection(title: string, textColor: Color3?)
	return Section.new(self._page, title, textColor)
end

function Tab:CreateButton(config: ButtonConfig)
	return CreateButton(self._page, config)
end

function Tab:CreateToggle(config: ToggleConfig)
	return CreateToggle(self._page, config)
end

function Tab:CreateSlider(config: SliderConfig)
	return CreateSlider(self._page, config)
end

function Tab:CreateDropdown(config: DropdownConfig)
	return CreateDropdown(self._page, config)
end

function Tab:CreateMultiDropdown(config: MultiDropdownConfig)
	return CreateMultiDropdown(self._page, config)
end

function Tab:CreateLabel(config: LabelConfig)
	return CreateLabel(self._page, config)
end

function Tab:CreateInput(config: InputConfig)
	return CreateInput(self._page, config)
end

function Tab:CreateStringInput(config: StringInputConfig)
	return CreateStringInput(self._page, config)
end

function Tab:CreateColorPicker(config: ColorPickerConfig)
	return CreateColorPicker(self._page, config)
end

-- ---------- Window ----------

local Window = {}
Window.__index = Window

function Window.new(config: WindowConfig)
	local self = setmetatable({}, Window)

	local screenGui = Create("ScreenGui", {
		Name = "UILibrary",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = TargetGui,
	})

	local main = Create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = config.Size or UDim2.new(0, 560, 0, 380),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = Theme.BackgroundTransparency,
		ClipsDescendants = true,
		Parent = screenGui,
	})
	AddCorner(main, Theme.CornerRadius)
	AddStroke(main, Theme.Border, 1)

	local topBar = Create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = Theme.Elevated,
		BackgroundTransparency = Theme.ElevatedTransparency,
		Parent = main,
	})
	AddCorner(topBar, Theme.CornerRadius)
	local topBarBottomEdge = Create("Frame", {
		Name = "SquareBottomEdge",
		Position = UDim2.new(0, 0, 1, -Theme.CornerRadius.Offset),
		Size = UDim2.new(1, 0, 0, Theme.CornerRadius.Offset),
		BackgroundColor3 = Theme.Elevated,
		BackgroundTransparency = Theme.ElevatedTransparency,
		BorderSizePixel = 0,
		Parent = topBar,
	})

	local topBarContent = Create("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = topBar,
	})
	AddPadding(topBarContent, 12)

	local windowTitle = Create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -180, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.FontBold,
		Text = config.Title or "UI Library",
		TextColor3 = Theme.TextPrimary,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = topBarContent,
	})

	local windowSubtitle
	if config.SubTitle then
		windowSubtitle = Create("TextLabel", {
			Name = "SubTitle",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -74, 0.5, 0),
			Size = UDim2.new(0, 140, 1, 0),
			BackgroundTransparency = 1,
			Font = Theme.Font,
			Text = config.SubTitle,
			TextColor3 = Theme.TextMuted,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = topBarContent,
		})
	end

	local controls = Create("Frame", {
		Name = "Controls",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 56, 0, 24),
		BackgroundTransparency = 1,
		Parent = topBarContent,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = controls,
	})

	local minimizeButton = Create("TextButton", {
		Name = "Minimize",
		Size = UDim2.new(0, 24, 0, 24),
		BackgroundColor3 = Theme.Border,
		BackgroundTransparency = 0.3,
		AutoButtonColor = false,
		Text = "",
		Parent = controls,
	})
	AddCorner(minimizeButton, UDim.new(1, 0))
	Create("Frame", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 10, 0, 2),
		BackgroundColor3 = Theme.TextSecondary,
		BorderSizePixel = 0,
		Parent = minimizeButton,
	})

	local closeButton = Create("TextButton", {
		Name = "Close",
		Size = UDim2.new(0, 24, 0, 24),
		BackgroundColor3 = Theme.Danger,
		BackgroundTransparency = 0.3,
		AutoButtonColor = false,
		Text = "",
		Parent = controls,
	})
	AddCorner(closeButton, UDim.new(1, 0))
	Create("Frame", {
		Name = "IconA",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 2),
		Rotation = 45,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = closeButton,
	})
	Create("Frame", {
		Name = "IconB",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 2),
		Rotation = -45,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = closeButton,
	})

	minimizeButton.MouseEnter:Connect(function()
		Tween(minimizeButton, { BackgroundTransparency = 0 })
	end)
	minimizeButton.MouseLeave:Connect(function()
		Tween(minimizeButton, { BackgroundTransparency = 0.3 })
	end)
	closeButton.MouseEnter:Connect(function()
		Tween(closeButton, { BackgroundTransparency = 0 })
	end)
	closeButton.MouseLeave:Connect(function()
		Tween(closeButton, { BackgroundTransparency = 0.3 })
	end)

	MakeDraggable(topBar, main)

	local body = Create("Frame", {
		Name = "Body",
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(1, 0, 1, -44),
		BackgroundTransparency = 1,
		Parent = main,
	})

	local tabBarBg = Create("Frame", {
		Name = "TabBarBackground",
		Size = UDim2.new(0, 140, 1, 0),
		BackgroundColor3 = Theme.Elevated,
		BackgroundTransparency = Theme.ElevatedTransparency,
		BorderSizePixel = 0,
		Parent = body,
	})
	AddCorner(tabBarBg, Theme.CornerRadius)

	local tabBarSquareTop = Create("Frame", {
		Name = "SquareTop",
		Size = UDim2.new(1, 0, 0, Theme.CornerRadius.Offset),
		BackgroundColor3 = Theme.Elevated,
		BackgroundTransparency = Theme.ElevatedTransparency,
		BorderSizePixel = 0,
		Parent = tabBarBg,
	})

	local tabBarSquareRight = Create("Frame", {
		Name = "SquareRight",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, Theme.CornerRadius.Offset, 1, 0),
		BackgroundColor3 = Theme.Elevated,
		BackgroundTransparency = Theme.ElevatedTransparency,
		BorderSizePixel = 0,
		Parent = tabBarBg,
	})

	local tabBar = Create("Frame", {
		Name = "TabBar",
		Size = UDim2.new(0, 140, 1, 0),
		BackgroundTransparency = 1,
		Parent = body,
	})
	AddPadding(tabBar, 8)
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = tabBar,
	})

	local pages = Create("Frame", {
		Name = "Pages",
		Position = UDim2.new(0, 140, 0, 0),
		Size = UDim2.new(1, -140, 1, 0),
		BackgroundTransparency = 1,
		Parent = body,
	})

	local resizeHandle = Create("Frame", {
		Name = "ResizeHandle",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		Size = UDim2.new(0, 18, 0, 18),
		BackgroundTransparency = 1,
		Active = true,
		ZIndex = 50,
		Parent = main,
	})
	local resizeDots = { { 2, 0 }, { 1, 1 }, { 2, 1 }, { 0, 2 }, { 1, 2 }, { 2, 2 } }
	for _, p in ipairs(resizeDots) do
		local dot = Create("Frame", {
			Size = UDim2.new(0, 3, 0, 3),
			Position = UDim2.new(0, p[1] * 5, 0, p[2] * 5),
			BackgroundColor3 = Theme.TextMuted,
			BackgroundTransparency = 0.3,
			ZIndex = 50,
			Parent = resizeHandle,
		})
		AddCorner(dot, UDim.new(1, 0))
	end

	self._screenGui = screenGui
	self._main = main
	self._tabBar = tabBar
	self._pages = pages
	self._tabs = {}
	self._firstTab = nil :: ScrollingFrame?
	self._tabBarOrder = 0
	self._activeTabButton = nil :: TextButton?
	self._minimized = false
	self._bubble = nil :: TextButton?
	self._minSize = config.MinSize or Vector2.new(380, 280)
	self._maxSize = config.MaxSize or Vector2.new(1000, 720)
	self._onClose = config.OnClose :: (() -> ())?

	RegisterThemeRefresh(function()
		main.BackgroundColor3 = Theme.Background
		topBar.BackgroundColor3 = Theme.Elevated
		topBarBottomEdge.BackgroundColor3 = Theme.Elevated

		tabBarBg.BackgroundColor3 = Theme.Elevated
		tabBarSquareTop.BackgroundColor3 = Theme.Elevated
		tabBarSquareRight.BackgroundColor3 = Theme.Elevated

		windowTitle.TextColor3 = Theme.TextPrimary
		if windowSubtitle then windowSubtitle.TextColor3 = Theme.TextMuted end

		local mainStroke = main:FindFirstChildWhichIsA("UIStroke")
		if mainStroke then mainStroke.Color = Theme.Border end

		for _, tab in ipairs(self._tabs) do
			local stroke = tab._button:FindFirstChildWhichIsA("UIStroke")
			if tab._button == self._activeTabButton then
				tab._button.BackgroundColor3 = Theme.Background
				tab._button.TextColor3 = Theme.TextPrimary
				if stroke then
					stroke.Color = Theme.Secondary
					stroke.Transparency = 0
				end
			else
				tab._button.BackgroundColor3 = Theme.Background
				tab._button.TextColor3 = Theme.TextSecondary
				if stroke then
					stroke.Color = Theme.Border
					stroke.Transparency = 0
				end
			end
		end
	end)

	minimizeButton.MouseButton1Click:Connect(function()
		self:Minimize()
	end)
	closeButton.MouseButton1Click:Connect(function()
		if self._onClose then
			task.spawn(self._onClose)
		end
		self:Destroy()
	end)

	local resizing = false
	local resizeStart: Vector2
	local startSize: UDim2

	resizeHandle.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			resizeStart = input.Position
			startSize = main.Size
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - resizeStart
			local newWidth = math.clamp(startSize.X.Offset + delta.X, self._minSize.X, self._maxSize.X)
			local newHeight = math.clamp(startSize.Y.Offset + delta.Y, self._minSize.Y, self._maxSize.Y)
			main.Size = UDim2.new(0, newWidth, 0, newHeight)
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = false
		end
	end)

	if config.ToggleKey then
		UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
			if gpe then return end
			if input.KeyCode == config.ToggleKey then
				if self._minimized then
					self:Restore()
				else
					main.Visible = not main.Visible
				end
			end
		end)
	end

	return self
end

function Window:CreateTabCategory(name: string, textColor: Color3?)
	self._tabBarOrder += 1
	local label = Create("TextLabel", {
		Name = "Category_" .. name,
		LayoutOrder = self._tabBarOrder,
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = Theme.FontBold,
		Text = string.upper(name),
		TextColor3 = textColor or Theme.TextMuted,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self._tabBar,
	})

	RegisterThemeRefresh(function()
		label.TextColor3 = textColor or Theme.TextMuted
	end)

	return label
end

function Window:CreateTab(config: TabConfig)
	self._tabBarOrder += 1
	local button = Create("TextButton", {
		Name = "Tab_" .. config.Name,
		LayoutOrder = self._tabBarOrder,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Theme.Background,
		AutoButtonColor = false,
		Font = Theme.FontSemibold,
		Text = config.Name,
		TextColor3 = Theme.TextSecondary,
		TextSize = 13,
		Parent = self._tabBar,
	})
	AddCorner(button, Theme.CornerRadiusSmall)

	local stroke = AddStroke(button, Theme.Border, 1)
	stroke.Transparency = 0

	local page = Create("ScrollingFrame", {
		Name = "Page_" .. config.Name,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = self._pages,
	})
	AddPadding(page, 12)
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = page,
	})

	local tab = Tab.new(page, button)
	table.insert(self._tabs, tab)

	local function selectTab()
		for _, other in ipairs(self._tabs) do
			other._page.Visible = false
			Tween(other._button, { BackgroundColor3 = Theme.Background, TextColor3 = Theme.TextSecondary })
			local otherStroke = other._button:FindFirstChildWhichIsA("UIStroke")
			if otherStroke then
				Tween(otherStroke, { Color = Theme.Border, Transparency = 0 })
			end
		end
		page.Visible = true
		Tween(button, { BackgroundColor3 = Theme.Background, TextColor3 = Theme.TextPrimary })
		Tween(stroke, { Color = Theme.Secondary, Transparency = 0 })
		self._activeTabButton = button
	end

	button.MouseButton1Click:Connect(selectTab)

	if not self._firstTab then
		self._firstTab = page
		selectTab()
	end

	return tab
end

function Window:CreateThemeTab(config: TabConfig?)
	local tab = self:CreateTab(config or { Name = "Theme Settings" })

	local colorSection = tab:CreateSection("Colors")

	colorSection:CreateColorPicker({
		Title = "Primary Color (Background)",
		Description = "Changes the overall menu background",
		Default = Theme.Background,
        Flag = "Theme_Background", -- Added Flag for saving
		Callback = function(color: Color3)
			local h, s, v = color:ToHSV()
			local elevatedV = math.clamp(v + 0.03, 0, 1)
			local elevatedColor = Color3.fromHSV(h, s, elevatedV)

			UILibrary:SetTheme({ 
				Background = color,
				Elevated = elevatedColor
			})
		end,
	})

	colorSection:CreateColorPicker({
		Title = "Secondary Color",
		Description = "Buttons, sliders, selected states",
		Default = Theme.Secondary,
        Flag = "Theme_Secondary", -- Added Flag for saving
		Callback = function(color: Color3)
			local h, s, v = color:ToHSV()
			local accentV = math.clamp(v + 0.15, 0, 1)
			local accentColor = Color3.fromHSV(h, s, accentV)

			UILibrary:SetTheme({ 
				Secondary = color,
				Accent = accentColor
			})
		end,
	})

	colorSection:CreateColorPicker({
		Title = "Text Color",
		Description = "Global color for normal titles and labels",
		Default = Theme.TextPrimary,
        Flag = "Theme_Text", -- Added Flag for saving
		Callback = function(color: Color3)
			UILibrary:SetTheme({ 
				TextPrimary = color,
				TextSecondary = color,
				TextMuted = color
			})
		end,
	})

	colorSection:CreateColorPicker({
		Title = "Border Color",
		Description = "Color for inactive tabs and element outlines",
		Default = Theme.Border,
        Flag = "Theme_Border", -- Added Flag for saving
		Callback = function(color: Color3)
			UILibrary:SetTheme({ Border = color })
		end,
	})

	local externalSection = tab:CreateSection("External Integrations")

	externalSection:CreateStringInput({
		Title = "Discord Webhook",
		Description = "Used to dispatch events externally",
		Placeholder = "https://discord.com/api/webhooks/...",
        Flag = "Theme_DiscordWebhook", -- Added Flag for saving
		Callback = function(url: string)
			print("Saved Discord Webhook:", url)
		end,
	})

	return tab
end

function Window:OnClose(callback: () -> ())
	self._onClose = callback
end

function Window:Destroy()
	self._screenGui:Destroy()
end

function Window:SetVisible(visible: boolean)
	self._main.Visible = visible
end

function Window:Minimize()
	if self._minimized then return end
	self._minimized = true
	self._main.Visible = false

	if self._bubble then
		(self._bubble :: TextButton).Visible = true
		return
	end

	local bubble = Create("TextButton", {
		Name = "Bubble",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -50, 1, -50),
		Size = UDim2.new(0, 52, 0, 52),
		BackgroundColor3 = Color3.fromRGB(10, 10, 12),
		AutoButtonColor = false,
		Text = "",
		ZIndex = 500,
		Parent = self._screenGui,
	})
	AddCorner(bubble, UDim.new(1, 0))
	AddStroke(bubble, Theme.Border, 2)

	local iconImage = Create("ImageLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://71056921656243",
		ZIndex = 501,
		Parent = bubble,
	})

	AddCorner(iconImage, UDim.new(1, 0))

	local dragging = false
	local dragStart: Vector2
	local startPos: UDim2
	local moved = false

	bubble.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = bubble.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			if delta.Magnitude > 4 then moved = true end
			bubble.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			if not moved then self:Restore() end
		end
	end)

	self._bubble = bubble
end

function Window:Restore()
	if not self._minimized then return end
	self._minimized = false
	self._main.Visible = true
	if self._bubble then
		(self._bubble :: TextButton).Visible = false
	end
end

function Window:ToggleMinimize()
	if self._minimized then
		self:Restore()
	else
		self:Minimize()
	end
end

-- ---------- Public API ----------

function UILibrary:CreateWindow(config: WindowConfig?)
	return Window.new(config or {})
end

function UILibrary:GetSettings(): { [string]: any }
	local safeSettings = {}
	for key, val in pairs(UILibrary.Settings) do
		-- Convert Color3 to a JSON-safe table
		if typeof(val) == "Color3" then
			safeSettings[key] = { type = "Color3", r = val.R, g = val.G, b = val.B }
		else
			safeSettings[key] = val
		end
	end
	return safeSettings
end

function UILibrary:LoadSettings(savedData: { [string]: any })
	if type(savedData) ~= "table" then return end
	for flag, value in pairs(savedData) do
		local parsedValue = value
		
		-- Convert the JSON-safe table back into a Roblox Color3 object
		if type(value) == "table" and value.type == "Color3" then
			parsedValue = Color3.new(value.r, value.g, value.b)
		end
		
		UILibrary.Settings[flag] = parsedValue
		local componentApi = Registry[flag]
		if componentApi and componentApi.SetValue then
			pcall(function()
				componentApi:SetValue(parsedValue)
			end)
		end
	end
end
function UILibrary:SetTheme(overrides: { [string]: any })
	for key, value in pairs(overrides) do
		(Theme :: any)[key] = value
	end
	for _, refresh in ipairs(ThemeRefreshCallbacks) do
		refresh()
	end
end

return UILibrary