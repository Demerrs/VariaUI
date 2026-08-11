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
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local TargetGui do
	if gethui then
		TargetGui = gethui()
	else
		TargetGui = CoreGui or LocalPlayer:WaitForChild("PlayerGui")
	end
end

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
	NoneOptions: { string }?,
	Callback: ((value: any) -> ())?,
	ExpandColumns: number?,
}

export type MultiDropdownConfig = {
	Title: string,
	Description: string?,
	TextColor: Color3?,
	Options: { string },
	Default: { string }?,
	Flag: string?,
	NoneOptions: { string }?,
	Callback: ((value: { string }) -> ())?,
	ExpandColumns: number?,
}

export type KeybindConfig = {
	Title: string,
	Description: string?,
	TextColor: Color3?,
	Default: Enum.KeyCode?,
	Flag: string?,
	Callback: ((key: Enum.KeyCode) -> ())?,
	ChangedCallback: ((key: Enum.KeyCode) -> ())?,
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
	Icon: string?,
	BubbleIcon: string?,
	Size: UDim2?,
	MinSize: Vector2?,
	MaxSize: Vector2?,
	ToggleKey: Enum.KeyCode?,
	OnClose: (() -> ())?,
}

export type TabConfig = {
	Name: string,
	Icon: string?,
	Columns: number?,
	RowHeight: number?,
}

export type NotificationConfig = {
	Title: string,
	Content: string,
	Duration: number?,
}

-- ============================================================
-- Theme
-- ============================================================

local Theme = {
	Background = Color3.fromRGB(8, 8, 11),
	BackgroundTransparency = 0.15,
	UseGradient = false,
	GradientColor1 = Color3.fromRGB(42, 20, 56),
	GradientColor2 = Color3.fromRGB(15, 25, 45),
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
-- Utilities & Global Connection Tracking for Cleanup
-- ============================================================

local ActiveConnections: { RBXScriptConnection } = {}

local function TrackConnection(conn: RBXScriptConnection): RBXScriptConnection
	table.insert(ActiveConnections, conn)
	return conn
end

local function FormatAssetId(id: string): string
	if not id or id == "" then return "" end
	if string.find(id, "rbxasset://") then return id end

	local num = string.match(id, "%d+")
	if num then
		return "rbxthumb://type=Asset&id=" .. num .. "&w=150&h=150"
	end
	return id
end

local function Create(className: string, props: { [string]: any }): any
	local inst = Instance.new(className)
	for key, value in pairs(props) do
		if key == "Parent" then continue end
		local obj = inst :: any
		obj[key] = value
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

	TrackConnection(dragHandle.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
		end
	end))

	TrackConnection(UserInputService.InputChanged:Connect(function(input: InputObject)
		if dragging then
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - dragStart
				target.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end
	end))

	TrackConnection(UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

local function Round(value: number, increment: number): number
	if increment <= 0 then return value end
	return math.floor((value / increment) + 0.5) * increment
end

-- ============================================================
-- Global Tooltip System
-- ============================================================

local Tooltip = {
	Frame = nil :: Frame?,
	Label = nil :: TextLabel?,
	Connection = nil :: RBXScriptConnection?
}

local function ShowTooltip(scope: Instance, title: string, desc: string?)
	local screenGui = scope:FindFirstAncestorWhichIsA("ScreenGui")
	if not screenGui then return end

	if not Tooltip.Frame then
		Tooltip.Frame = Create("Frame", {
			Name = "__Tooltip",
			BackgroundColor3 = Theme.Elevated,
			AutomaticSize = Enum.AutomaticSize.XY,
			ZIndex = 100000,
			Visible = false,
			Parent = screenGui
		})
		AddCorner(Tooltip.Frame, Theme.CornerRadiusSmall)
		AddStroke(Tooltip.Frame, Theme.Border, 1)
		AddPadding(Tooltip.Frame, 8)

		Tooltip.Label = Create("TextLabel", {
			Name = "Text",
			BackgroundTransparency = 1,
			Font = Theme.Font,
			TextColor3 = Theme.TextPrimary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			AutomaticSize = Enum.AutomaticSize.XY,
			RichText = true,
			Parent = Tooltip.Frame,
		})

		RegisterThemeRefresh(function()
			if Tooltip.Frame then Tooltip.Frame.BackgroundColor3 = Theme.Elevated end
			if Tooltip.Label then Tooltip.Label.TextColor3 = Theme.TextPrimary end
		end)
	end

	local tip = "<b>" .. title .. "</b>"
	if desc then tip = tip .. "\n<font color='rgb(165,165,175)'>" .. desc .. "</font>" end

	Tooltip.Label.Text = tip
	Tooltip.Frame.Visible = true

	if Tooltip.Connection then Tooltip.Connection:Disconnect() end
	Tooltip.Connection = TrackConnection(RunService.RenderStepped:Connect(function()
		local mouse = UserInputService:GetMouseLocation()
		if Tooltip.Frame then
			Tooltip.Frame.Position = UDim2.fromOffset(mouse.X + 15, mouse.Y - 20)
		end
	end))
end

local function HideTooltip()
	if Tooltip.Frame then
		Tooltip.Frame.Visible = false
	end
	if Tooltip.Connection then
		Tooltip.Connection:Disconnect()
		Tooltip.Connection = nil
	end
end

-- ============================================================
-- Library Core & Notification System
-- ============================================================

local UILibrary = {}
UILibrary.__index = UILibrary
UILibrary.Settings = {} :: { [string]: any }

local Registry = {} :: { [string]: any }
local SearchableRows = {} :: { { Row: Frame, SearchText: string } }
local SectionsData = {} :: { { Container: Frame, List: Frame } }
local BoundKeys = {} :: { [Enum.KeyCode]: boolean } 
local NotificationScreenGui = nil

function UILibrary:GetTargetGuiName(): string
	if gethui and TargetGui == gethui() then
		return "Protected UI (gethui)"
	elseif TargetGui == CoreGui then
		return "CoreGui"
	else
		return "PlayerGui"
	end
end

function UILibrary:Notify(config: NotificationConfig)
	if not NotificationScreenGui then
		NotificationScreenGui = Create("ScreenGui", {
			Name = "VariaUINotifications",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			Parent = TargetGui,
		})
	end

	local container = NotificationScreenGui:FindFirstChild("Container")
	if not container then
		container = Create("Frame", {
			Name = "Container",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -20, 1, -20),
			Size = UDim2.new(0, 300, 1, 0),
			BackgroundTransparency = 1,
			Parent = NotificationScreenGui,
		})
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 10),
			Parent = container,
		})
	end

	local card = Create("Frame", {
		Name = "Notification",
		Size = UDim2.new(0, 300, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = container,
	})
	AddCorner(card, Theme.CornerRadiusCard)
	local stroke = AddStroke(card, Theme.Border, 1)
	stroke.Transparency = 1

	AddPadding(card, 14)

	local titleLabel = Create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Theme.FontBold,
		Text = config.Title,
		TextColor3 = Theme.TextPrimary,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 1,
		Parent = card,
	})

	local contentLabel = Create("TextLabel", {
		Name = "Content",
		Position = UDim2.new(0, 0, 0, 20),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Theme.Font,
		Text = config.Content,
		TextColor3 = Theme.TextSecondary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		TextTransparency = 1,
		Parent = card,
	})

	card.Position = UDim2.new(0, 50, 0, 0)
	Tween(card, { BackgroundTransparency = Theme.BackgroundTransparency, Position = UDim2.new(0, 0, 0, 0) })
	Tween(stroke, { Transparency = 0 })
	Tween(titleLabel, { TextTransparency = 0 })
	Tween(contentLabel, { TextTransparency = 0 })

	task.spawn(function()
		task.wait(config.Duration or 3.5)
		if card and card.Parent then
			Tween(card, { BackgroundTransparency = 1, Position = UDim2.new(0, 50, 0, 0) })
			Tween(stroke, { Transparency = 1 })
			Tween(titleLabel, { TextTransparency = 1 })
			Tween(contentLabel, { TextTransparency = 1 })
			task.wait(0.2)
			card:Destroy()
		end
	end)
end

-- ---------- Component builders ----------

local function BuildRow(parent: Instance, title: string, description: string?, textColor: Color3?, rightOffset: number?)
	local baseOffset = rightOffset or 100
	local inlineOffset = 0

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
		Size = UDim2.new(1, -baseOffset, description and 0.55 or 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.FontSemibold,
		Text = title,
		TextColor3 = textColor or Theme.TextPrimary,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	local descLabel
	if description then
		descLabel = Create("TextLabel", {
			Name = "Description",
			Position = UDim2.new(0, 0, 0.55, 0),
			Size = UDim2.new(1, -baseOffset, 0.45, 0),
			BackgroundTransparency = 1,
			Font = Theme.Font,
			Text = description,
			TextColor3 = Theme.TextSecondary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = false,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
	end

	local inlineContainer = Create("Frame", {
		Name = "InlineContainer",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -baseOffset - 8, 0.5, 0),
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = row,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		Parent = inlineContainer,
	})

	RegisterThemeRefresh(function()
		row.BackgroundColor3 = Theme.Elevated
		titleLabel.TextColor3 = textColor or Theme.TextPrimary
		if descLabel then descLabel.TextColor3 = Theme.TextSecondary end
	end)

	local hoverTick = 0
	TrackConnection(row.MouseEnter:Connect(function()
		hoverTick = os.clock()
		local currentTick = hoverTick
		task.delay(0.5, function()
			if hoverTick == currentTick then ShowTooltip(row, title, description) end
		end)
	end))
	TrackConnection(row.MouseLeave:Connect(function()
		hoverTick = 0
		HideTooltip()
	end))

	table.insert(SearchableRows, { 
		Row = row, 
		SearchText = string.lower(title .. " " .. (description or ""))
	})

	return {
		Instance = row,
		InlineContainer = inlineContainer,
		SetTitle = function(newTitle: string) titleLabel.Text = newTitle end,
		UpdateOffset = function(extraWidth: number)
			inlineOffset += extraWidth + 8
			local totalOffset = baseOffset + inlineOffset
			titleLabel.Size = UDim2.new(1, -totalOffset, description and 0.55 or 1, 0)
			if descLabel then descLabel.Size = UDim2.new(1, -totalOffset, 0.45, 0) end
		end
	}
end

-- ============================================================
-- Core Components
-- ============================================================

local CreateColorPicker

local function ConstructKeybind(parent: Instance, config: KeybindConfig, isInline: boolean)
	local rowObj, buttonParent, width
	local key = config.Default or Enum.KeyCode.Unknown

	if key ~= Enum.KeyCode.Unknown then
		if BoundKeys[key] then
			key = Enum.KeyCode.Unknown
		else
			BoundKeys[key] = true
		end
	end

	if config.Flag then
		UILibrary.Settings[config.Flag] = key.Name
	end

	if isInline then
		buttonParent = parent
		width = 60
	else
		rowObj = BuildRow(parent, config.Title, config.Description, config.TextColor, 74)
		buttonParent = rowObj.Instance
		width = 64
	end

	local button = Create("TextButton", {
		Name = "Keybind",
		AnchorPoint = isInline and Vector2.new(0, 0) or Vector2.new(1, 0.5),
		Position = isInline and UDim2.new(0, 0, 0, 0) or UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, width, 0, 26),
		BackgroundColor3 = Theme.Background,
		Font = Theme.FontSemibold,
		Text = key == Enum.KeyCode.Unknown and "[ None ]" or "[ " .. key.Name .. " ]",
		TextColor3 = Theme.TextPrimary,
		TextSize = 12,
		AutoButtonColor = false,
		ZIndex = 11,
		Parent = buttonParent,
	})
	AddCorner(button, Theme.CornerRadiusSmall)
	AddStroke(button)

	RegisterThemeRefresh(function()
		button.BackgroundColor3 = Theme.Background
		button.TextColor3 = Theme.TextPrimary
	end)

	local waitingForInput = false

	local function setKey(newKey: Enum.KeyCode)
		if newKey == key then
			button.Text = key == Enum.KeyCode.Unknown and "[ None ]" or "[ " .. key.Name .. " ]"
			return true
		end

		if newKey ~= Enum.KeyCode.Unknown and BoundKeys[newKey] then
			UILibrary:Notify({
				Title = "Key Unavailable",
				Content = "The key [" .. newKey.Name .. "] is already bound to another action.",
				Duration = 3
			})
			button.Text = key == Enum.KeyCode.Unknown and "[ None ]" or "[ " .. key.Name .. " ]"
			return false
		end

		if key ~= Enum.KeyCode.Unknown then
			BoundKeys[key] = nil
		end
		if newKey ~= Enum.KeyCode.Unknown then
			BoundKeys[newKey] = true
		end

		key = newKey
		button.Text = key == Enum.KeyCode.Unknown and "[ None ]" or "[ " .. key.Name .. " ]"
		if config.Flag then UILibrary.Settings[config.Flag] = key.Name end

		if config.ChangedCallback then task.spawn(config.ChangedCallback, key) end

		return true
	end

	TrackConnection(button.MouseButton1Click:Connect(function()
		waitingForInput = true
		button.Text = "[ ... ]"
	end))

	TrackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
		if waitingForInput then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local blockList = { Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space }
				if not table.find(blockList, input.KeyCode) then
					setKey(input.KeyCode)
					waitingForInput = false
				end
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
				setKey(Enum.KeyCode.Unknown)
				waitingForInput = false
			end
		elseif not gpe and input.KeyCode == key and key ~= Enum.KeyCode.Unknown then
			if config.Callback then task.spawn(config.Callback, key) end
		end
	end))

	local api = {}
	function api.SetValue(_self, keyName: string)
		pcall(function()
			setKey(Enum.KeyCode[keyName])
		end)
	end
	function api.GetValue(_self)
		return key.Name
	end

	if config.Flag then
		Registry[config.Flag] = api
	end

	return api
end

local function CreateKeybind(parent: Instance, config: KeybindConfig)
	return ConstructKeybind(parent, config, false)
end

local function CreateButton(parent: Instance, config: ButtonConfig)
	local rowObj = BuildRow(parent, config.Title, config.Description, config.TextColor, 74)

	local button = Create("TextButton", {
		Name = "Button",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 64, 0, 26),
		BackgroundColor3 = Theme.Secondary,
		Font = Theme.FontSemibold,
		Text = "Run",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 13,
		AutoButtonColor = false,
		ZIndex = 11,
		Parent = rowObj.Instance,
	})
	AddCorner(button, Theme.CornerRadiusSmall)

	RegisterThemeRefresh(function() button.BackgroundColor3 = Theme.Secondary end)

	TrackConnection(button.MouseEnter:Connect(function() Tween(button, { BackgroundColor3 = Theme.Accent }) end))
	TrackConnection(button.MouseLeave:Connect(function() Tween(button, { BackgroundColor3 = Theme.Secondary }) end))
	TrackConnection(button.MouseButton1Click:Connect(function()
		Tween(button, { BackgroundColor3 = Theme.Accent }, TweenInfo.new(0.08))
		task.delay(0.08, function() 
			if button and button.Parent then 
				Tween(button, { BackgroundColor3 = Theme.Secondary }) 
			end 
		end)
		if config.Callback then task.spawn(config.Callback) end
	end))

	local api = {}
	function api.AddKeybind(_self, subConfig: KeybindConfig)
		rowObj.UpdateOffset(60)
		ConstructKeybind(rowObj.InlineContainer, subConfig, true)
		return api
	end
	function api.AddColorPicker(_self, subConfig: ColorPickerConfig)
		rowObj.UpdateOffset(36)
		CreateColorPicker(rowObj.InlineContainer, subConfig, true)
		return api
	end

	return api
end

local function CreateToggle(parent: Instance, config: ToggleConfig)
	local rowObj = BuildRow(parent, config.Title, config.Description, config.TextColor, 45)
	local state = config.Default or false

	if config.Flag then UILibrary.Settings[config.Flag] = state end

	local track = Create("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 42, 0, 22),
		BackgroundColor3 = state and Theme.Secondary or Theme.Background,
		Parent = rowObj.Instance,
	})
	AddCorner(track, UDim.new(1, 0))
	local trackStroke = AddStroke(track, state and Theme.Secondary or Theme.Border, 1)

	local knob = Create("Frame", {
		Name = "Knob",
		Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0, 18, 0, 18),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = track,
	})
	AddCorner(knob, UDim.new(1, 0))
	Create("UIStroke", {
		Color = Color3.new(0, 0, 0),
		Thickness = 1,
		Transparency = 0.8,
		Parent = knob
	})

	local clickArea = Create("TextButton", {
		Name = "ClickArea",
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 1,
		Parent = rowObj.Instance,
	})

	local function render()
		Tween(track, { BackgroundColor3 = state and Theme.Secondary or Theme.Background })
		Tween(trackStroke, { Color = state and Theme.Secondary or Theme.Border })
		Tween(knob, { Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) })
		if config.Flag then UILibrary.Settings[config.Flag] = state end
	end

	RegisterThemeRefresh(function()
		if state then
			track.BackgroundColor3 = Theme.Secondary
			trackStroke.Color = Theme.Secondary
		else
			track.BackgroundColor3 = Theme.Background
			trackStroke.Color = Theme.Border
		end
	end)

	local api = {}
	function api.SetValue(_self, value: boolean)
		state = value
		render()
		if config.Callback then task.spawn(config.Callback, state) end
	end
	function api.GetValue(_self) return state end

	function api.AddKeybind(_self, subConfig: KeybindConfig)
		rowObj.UpdateOffset(60)
		ConstructKeybind(rowObj.InlineContainer, subConfig, true)
		return api
	end
	function api.AddColorPicker(_self, subConfig: ColorPickerConfig)
		rowObj.UpdateOffset(36)
		CreateColorPicker(rowObj.InlineContainer, subConfig, true)
		return api
	end

	if config.Flag then Registry[config.Flag] = api end

	TrackConnection(clickArea.MouseButton1Click:Connect(function()
		state = not state
		render()
		if config.Callback then task.spawn(config.Callback, state) end
	end))

	return api
end

local function CreateSlider(parent: Instance, config: SliderConfig)
	local increment = config.Increment or 1
	local value = math.clamp(config.Default or config.Min, config.Min, config.Max)

	if config.Flag then UILibrary.Settings[config.Flag] = value end

	local rowHeight = config.Description and 88 or 64
	local rowObj = BuildRow(parent, config.Title, config.Description, config.TextColor, 50)
	local row = rowObj.Instance
	row.Size = UDim2.new(1, 0, 0, rowHeight)

	local titleLabel = row:FindFirstChild("Title") :: TextLabel
	local descLabel = row:FindFirstChild("Description") :: TextLabel?

	titleLabel.Size = UDim2.new(1, -50, 0, 16)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)

	if descLabel then
		descLabel.Size = UDim2.new(1, -50, 0, 14)
		descLabel.Position = UDim2.new(0, 0, 0, 22)
	end

	local valueLabel = Create("TextLabel", {
		Name = "Value",
		Size = UDim2.new(0, 50, 0, 16),
		Position = UDim2.new(1, -50, 0, 0),
		BackgroundTransparency = 1,
		Font = Theme.FontSemibold,
		Text = tostring(value),
		TextColor3 = Theme.TextSecondary,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})

	local trackArea = Create("TextButton", {
		Name = "TrackArea",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
		Parent = row,
	})

	local track = Create("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.new(1, -20, 0, 8),
		BackgroundColor3 = Theme.Border,
		BackgroundTransparency = 0.35,
		ZIndex = 2,
		Parent = trackArea,
	})
	AddCorner(track, UDim.new(1, 0))

	local fillRatio = (value - config.Min) / math.max(config.Max - config.Min, 1e-6)
	local fill = Create("Frame", {
		Name = "Fill",
		Size = UDim2.new(fillRatio, 0, 1, 0),
		BackgroundColor3 = Theme.Secondary,
		ZIndex = 2,
		Parent = track,
	})
	AddCorner(fill, UDim.new(1, 0))

	RegisterThemeRefresh(function()
		valueLabel.TextColor3 = Theme.TextSecondary
		fill.BackgroundColor3 = Theme.Secondary
	end)

	local knob = Create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(fillRatio, 0, 0.5, 0),
		Size = UDim2.new(0, 20, 0, 20),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
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
		if config.Flag then UILibrary.Settings[config.Flag] = value end
	end

	TrackConnection(trackArea.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromRatio((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
			if config.Callback then task.spawn(config.Callback, value) end
		end
	end))

	TrackConnection(UserInputService.InputChanged:Connect(function(input: InputObject)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromRatio((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
			if config.Callback then task.spawn(config.Callback, value) end
		end
	end))

	TrackConnection(UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	local api = {}
	function api.SetValue(_self, newValue: number)
		setFromRatio((newValue - config.Min) / math.max(config.Max - config.Min, 1e-6))
		if config.Callback then task.spawn(config.Callback, value) end
	end
	function api.GetValue(_self) return value end

	if config.Flag then Registry[config.Flag] = api end
	return api
end

local DefaultNoneLabels = { ["none"]=true, ["nothing"]=true, ["n/a"]=true, ["na"]=true, ["empty"]=true, ["-"]=true }
local function CreateDropdown(parent: Instance, config: DropdownConfig)
	local isMulti = config.Multi or false
	local selected: { [string]: boolean } = {}
	if not isMulti then selected[config.Default or config.Options[1]] = true end

	local extraNoneLabels: { [string]: boolean } = {}
	if config.NoneOptions then
		for _, name in ipairs(config.NoneOptions) do extraNoneLabels[name:lower()] = true end
	end

	local function isNoneOption(n: string) return DefaultNoneLabels[n:lower()] or extraNoneLabels[n:lower()] end
	local function sanitizeSelection()
		local hasReal = false
		for n, sel in pairs(selected) do
			if sel and not isNoneOption(n) then hasReal = true break end
		end
		if hasReal then
			for n, sel in pairs(selected) do
				if sel and isNoneOption(n) then selected[n] = false end
			end
		end
	end
	sanitizeSelection()

	local rowObj = BuildRow(parent, config.Title, config.Description, config.TextColor, 175)
	local row = rowObj.Instance
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
		TextTruncate = Enum.TextTruncate.AtEnd,
		AutoButtonColor = false,
		ZIndex = 11,
		Parent = row,
	})
	AddCorner(display, Theme.CornerRadiusSmall)
	AddStroke(display)

	local expandButton = Create("TextButton", {
		Name = "Expand",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -(140 + 6), 0.5, 0),
		Size = UDim2.new(0, 24, 0, 26),
		BackgroundColor3 = Theme.Background,
		Font = Theme.FontBold,
		Text = "↗",
		TextColor3 = Theme.TextSecondary,
		TextSize = 16,
		AutoButtonColor = false,
		ZIndex = 11,
		Parent = row,
	})
	AddCorner(expandButton, Theme.CornerRadiusSmall)
	AddStroke(expandButton)

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

	local list = Create("TextButton", {
		Name = "List",
		Size = UDim2.new(0, 140, 0, math.min(#config.Options * 28, 168)),
		BackgroundColor3 = Theme.Elevated,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 1001,
		ClipsDescendants = true,
		Parent = overlay,
	})
	AddCorner(list, Theme.CornerRadiusSmall)
	AddStroke(list)

	local listLayout = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
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

	local expandBackdrop = Create("TextButton", {
		Name = "ExpandBackdrop",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.45,
		AutoButtonColor = false,
		Text = "",
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 2000,
		Visible = false,
		Parent = overlay,
	})

	local expandPanel = Create("TextButton", {
		Name = "ExpandPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 320, 0, 420),
		BackgroundColor3 = Theme.Elevated,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 2001,
		Visible = false,
		Parent = overlay,
	})
	AddCorner(expandPanel, Theme.CornerRadiusCard)
	AddStroke(expandPanel)

	local expandHeader = Create("TextButton", { Name = "Header", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2002, Parent = expandPanel })
	Create("TextLabel", { Name = "Title", Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Font = Theme.FontBold, Text = config.Title, TextColor3 = Theme.TextPrimary, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2002, Parent = expandHeader })
	local expandClose = Create("TextButton", { Name = "Close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = Theme.Background, Font = Theme.FontBold, Text = "×", TextColor3 = Theme.TextSecondary, TextSize = 16, AutoButtonColor = false, ZIndex = 2003, Parent = expandHeader })
	AddCorner(expandClose, Theme.CornerRadiusSmall)

	MakeDraggable(expandHeader, expandPanel)

	local expandSearch = Create("TextBox", {
		Name = "Search",
		Position = UDim2.new(0, 14, 0, 44),
		Size = UDim2.new(1, -28, 0, 30),
		BackgroundColor3 = Theme.Background,
		Font = Theme.Font,
		PlaceholderText = "Search...",
		Text = "",
		TextColor3 = Theme.TextPrimary,
		PlaceholderColor3 = Theme.TextMuted,
		TextSize = 13,
		ClearTextOnFocus = false,
		ZIndex = 2002,
		Parent = expandPanel,
	})
	AddCorner(expandSearch, Theme.CornerRadiusSmall)
	AddStroke(expandSearch)
	AddPadding(expandSearch, 8)

	local expandScroller = Create("ScrollingFrame", {
		Name = "Scroller",
		Position = UDim2.new(0, 14, 0, 84),
		Size = UDim2.new(1, -28, 1, -98),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 2002,
		Parent = expandPanel,
	})

	local expandColumns = math.max(1, math.floor(config.ExpandColumns or 1))
	if expandColumns > 1 then
		Create("UIGridLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			CellPadding = UDim2.new(0, 6, 0, 6),
			CellSize = UDim2.new(1 / expandColumns, -6, 0, 30),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Parent = expandScroller,
		})
	else
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = expandScroller })
	end

	local open, expandOpen = false, false
	local function setOpen(val: boolean)
		open = val
		if val then
			local pos = display.AbsolutePosition
			local sz = display.AbsoluteSize
			list.Position = UDim2.fromOffset(pos.X + sz.X - list.AbsoluteSize.X, pos.Y + sz.Y + 4)
		end
		list.Visible = val; blocker.Visible = val
	end

	local function setExpandOpen(val: boolean)
		expandOpen = val
		expandBackdrop.Visible = val; expandPanel.Visible = val
		if val then expandSearch.Text = "" end
	end

	TrackConnection(blocker.MouseButton1Click:Connect(function() setOpen(false) end))
	TrackConnection(expandBackdrop.MouseButton1Click:Connect(function() setExpandOpen(false) end))
	TrackConnection(expandClose.MouseButton1Click:Connect(function() setExpandOpen(false) end))
	TrackConnection(expandButton.MouseButton1Click:Connect(function() setOpen(false) setExpandOpen(not expandOpen) end))
	TrackConnection(display.MouseButton1Click:Connect(function() setExpandOpen(false) setOpen(not open) end))

	TrackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if expandOpen and input.KeyCode == Enum.KeyCode.Escape then setExpandOpen(false) end
	end))

	local function updateDisplayText()
		if isMulti then
			local names = {}
			for n, s in pairs(selected) do if s then table.insert(names, n) end end
			display.Text = #names > 0 and table.concat(names, ", ") or "Select..."
		else
			for n, s in pairs(selected) do
				if s then display.Text = n break end
			end
		end
	end

	local function syncFlag()
		if not config.Flag then return end
		if isMulti then
			local names = {}
			for n, s in pairs(selected) do if s then table.insert(names, n) end end
			UILibrary.Settings[config.Flag] = names
		else
			for n, s in pairs(selected) do
				if s then UILibrary.Settings[config.Flag] = n break end
			end
		end
	end

	local optionButtons = {}
	local function refreshHighlight()
		display.BackgroundColor3 = Theme.Background; display.TextColor3 = Theme.TextPrimary
		list.BackgroundColor3 = Theme.Elevated; expandPanel.BackgroundColor3 = Theme.Elevated
		for name, buttons in pairs(optionButtons) do
			for _, btn in ipairs(buttons) do
				btn.BackgroundColor3 = selected[name] and Theme.Secondary or Theme.Elevated
				btn.TextColor3 = Theme.TextPrimary
			end
		end
	end
	RegisterThemeRefresh(refreshHighlight)

	local function selectOption(option: string)
		if isMulti then
			local turningOn = not selected[option]
			selected[option] = turningOn
			if turningOn then
				if isNoneOption(option) then
					for n in pairs(selected) do if n ~= option then selected[n] = false end end
				else
					for n in pairs(selected) do if n ~= option and isNoneOption(n) then selected[n] = false end end
				end
			end
		else
			for n in pairs(selected) do selected[n] = false end
			selected[option] = true
			setOpen(false)
			setExpandOpen(false)
		end
		refreshHighlight(); updateDisplayText(); syncFlag()
		if config.Callback then
			if isMulti then
				local names = {}
				for n, s in pairs(selected) do if s then table.insert(names, n) end end
				task.spawn(config.Callback, names)
			else task.spawn(config.Callback, option) end
		end
	end

	for i, option in ipairs(config.Options) do
		optionButtons[option] = {}
		local btn1 = Create("TextButton", { Name = option, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Theme.Elevated, Font = Theme.Font, Text = option, TextColor3 = Theme.TextPrimary, TextSize = 13, ZIndex = 10, Parent = scroller })
		AddCorner(btn1, Theme.CornerRadiusSmall)
		table.insert(optionButtons[option], btn1)
		TrackConnection(btn1.MouseButton1Click:Connect(function() selectOption(option) end))

		local btn2 = Create("TextButton", { Name = option, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Elevated, Font = Theme.Font, Text = option, TextColor3 = Theme.TextPrimary, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2002, Parent = expandScroller })
		AddCorner(btn2, Theme.CornerRadiusSmall)
		AddPadding(btn2, 8)
		table.insert(optionButtons[option], btn2)
		TrackConnection(btn2.MouseButton1Click:Connect(function() selectOption(option) end))
	end

	TrackConnection(expandSearch:GetPropertyChangedSignal("Text"):Connect(function()
		local q = expandSearch.Text:lower()
		for _, opt in ipairs(config.Options) do
			local matches = q == "" or opt:lower():find(q, 1, true) ~= nil
			for _, btn in ipairs(optionButtons[opt] or {}) do
				if btn.Parent == expandScroller then btn.Visible = matches end
			end
		end
	end))

	updateDisplayText(); syncFlag(); refreshHighlight()

	local api = {}
	function api.SetValue(_self, value: any)
		if isMulti then
			for n in pairs(selected) do selected[n] = false end
			if type(value) == "table" then for _, n in ipairs(value) do selected[n] = true end end
			sanitizeSelection()
		else
			for n in pairs(selected) do selected[n] = false end
			selected[value] = true
		end
		refreshHighlight(); updateDisplayText(); syncFlag()
		if config.Callback then
			if isMulti then
				local names = {}
				for n, s in pairs(selected) do if s then table.insert(names, n) end end
				task.spawn(config.Callback, names)
			else task.spawn(config.Callback, value) end
		end
	end
	function api.GetValue(_self)
		if isMulti then
			local names = {}
			for n, s in pairs(selected) do if s then table.insert(names, n) end end
			return names
		end
		for n, s in pairs(selected) do if s then return n end end
		return nil
	end

	function api.AddKeybind(_self, subConfig: KeybindConfig)
		rowObj.UpdateOffset(60)
		ConstructKeybind(rowObj.InlineContainer, subConfig, true)
		return api
	end

	if config.Flag then Registry[config.Flag] = api end
	return api
end

local function CreateMultiDropdown(parent: Instance, config: MultiDropdownConfig)
	if config.Default then
		local seed = {}
		for _, name in ipairs(config.Default) do seed[name] = true end
	end
	local api = CreateDropdown(parent, {
		Title = config.Title, Description = config.Description, TextColor = config.TextColor, Options = config.Options,
		Multi = true, Flag = config.Flag, NoneOptions = config.NoneOptions, Callback = config.Callback, ExpandColumns = config.ExpandColumns,
	} :: DropdownConfig)
	if config.Default then api:SetValue(config.Default) end
	return api
end

local function CreateLabel(parent: Instance, config: LabelConfig)
	local rowObj = BuildRow(parent, config.Title, config.Description, config.TextColor, 10)
	local row = rowObj.Instance
	row.BackgroundTransparency = 1
	local api = {}
	function api.SetText(_self, text: string) rowObj.SetTitle(text) end
	return api
end

local function CreateInput(parent: Instance, config: InputConfig)
	local rowObj = BuildRow(parent, config.Title, config.Description, config.TextColor, 74)
	local value = config.Default or 0
	if config.Flag then UILibrary.Settings[config.Flag] = value end

	local box = Create("TextBox", {
		Name = "Input",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 64, 0, 26),
		BackgroundColor3 = Theme.Background,
		Font = Theme.Font,
		PlaceholderText = config.Placeholder or "0",
		Text = config.Default and tostring(config.Default) or "",
		TextColor3 = Theme.TextPrimary,
		PlaceholderColor3 = Theme.TextMuted,
		TextSize = 13,
		ClearTextOnFocus = false,
		ZIndex = 11,
		Parent = rowObj.Instance,
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
		if not num then box.Text = tostring(value) return end
		if config.Min then num = math.max(num, config.Min) end
		if config.Max then num = math.min(num, config.Max) end
		value = num
		box.Text = tostring(value)
		if config.Flag then UILibrary.Settings[config.Flag] = value end
		if config.Callback then task.spawn(config.Callback, value) end
	end

	TrackConnection(box.FocusLost:Connect(function() commit() end))

	local api = {}
	function api.SetValue(_self, newValue: number) box.Text = tostring(newValue); commit() end
	function api.GetValue(_self) return value end

	function api.AddKeybind(_self, subConfig: KeybindConfig)
		rowObj.UpdateOffset(60)
		ConstructKeybind(rowObj.InlineContainer, subConfig, true)
		return api
	end

	if config.Flag then Registry[config.Flag] = api end
	return api
end

local function CreateStringInput(parent: Instance, config: StringInputConfig)
	local rowObj = BuildRow(parent, config.Title, config.Description, config.TextColor, 190)
	local value = config.Default or ""
	if config.Flag then UILibrary.Settings[config.Flag] = value end

	local box = Create("TextBox", {
		Name = "StringInput",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 150, 0, 26),
		BackgroundColor3 = Theme.Background,
		Font = Theme.Font,
		PlaceholderText = config.Placeholder or "Enter text...",
		Text = value,
		TextColor3 = Theme.TextPrimary,
		PlaceholderColor3 = Theme.TextMuted,
		TextSize = 13,
		ClearTextOnFocus = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 11,
		Parent = rowObj.Instance,
	})
	AddCorner(box, Theme.CornerRadiusSmall)
	AddStroke(box)
	AddPadding(box, 6)

	local expandButton = Create("TextButton", {
		Name = "Expand", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(150 + 6), 0.5, 0),
		Size = UDim2.new(0, 24, 0, 26), BackgroundColor3 = Theme.Background, Font = Theme.FontBold,
		Text = "↗", TextColor3 = Theme.TextSecondary, TextSize = 16, AutoButtonColor = false, ZIndex = 11, Parent = rowObj.Instance,
	})
	AddCorner(expandButton, Theme.CornerRadiusSmall)
	AddStroke(expandButton)

	local overlay = GetOverlay(rowObj.Instance)

	local expandBackdrop = Create("TextButton", { Name = "ExpandBackdrop", BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.45, AutoButtonColor = false, Text = "", Size = UDim2.new(1, 0, 1, 0), ZIndex = 2000, Visible = false, Parent = overlay })
	local expandPanel = Create("TextButton", { Name = "ExpandPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 360, 0, 320), BackgroundColor3 = Theme.Elevated, Text = "", AutoButtonColor = false, ZIndex = 2001, Visible = false, Parent = overlay })
	AddCorner(expandPanel, Theme.CornerRadiusCard)
	AddStroke(expandPanel)

	local expandHeader = Create("TextButton", { Name = "Header", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2002, Parent = expandPanel })
	Create("TextLabel", { Name = "Title", Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Font = Theme.FontBold, Text = config.Title, TextColor3 = Theme.TextPrimary, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2002, Parent = expandHeader })
	local expandClose = Create("TextButton", { Name = "Close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = Theme.Background, Font = Theme.FontBold, Text = "×", TextColor3 = Theme.TextSecondary, TextSize = 16, AutoButtonColor = false, ZIndex = 2003, Parent = expandHeader })
	AddCorner(expandClose, Theme.CornerRadiusSmall)

	MakeDraggable(expandHeader, expandPanel)

	local expandBox = Create("TextBox", {
		Name = "LargeInput", Position = UDim2.new(0, 14, 0, 44), Size = UDim2.new(1, -28, 1, -58),
		BackgroundColor3 = Theme.Background, Font = Theme.Font, PlaceholderText = config.Placeholder or "Enter text...",
		Text = value, TextColor3 = Theme.TextPrimary, PlaceholderColor3 = Theme.TextMuted, TextSize = 13, ClearTextOnFocus = false, TextWrapped = true, MultiLine = true, TextYAlignment = Enum.TextYAlignment.Top, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2002, Parent = expandPanel,
	})
	AddCorner(expandBox, Theme.CornerRadiusSmall)
	AddStroke(expandBox)
	AddPadding(expandBox, 8)

	local function setExpandOpen(val: boolean) expandBackdrop.Visible = val; expandPanel.Visible = val end
	TrackConnection(expandButton.MouseButton1Click:Connect(function() setExpandOpen(true) end))
	TrackConnection(expandClose.MouseButton1Click:Connect(function() setExpandOpen(false) end))
	TrackConnection(expandBackdrop.MouseButton1Click:Connect(function() setExpandOpen(false) end))

	local isSyncing = false
	TrackConnection(box:GetPropertyChangedSignal("Text"):Connect(function()
		if isSyncing then return end
		isSyncing = true; value = box.Text; expandBox.Text = value; if config.Flag then UILibrary.Settings[config.Flag] = value end; isSyncing = false
	end))
	TrackConnection(expandBox:GetPropertyChangedSignal("Text"):Connect(function()
		if isSyncing then return end
		isSyncing = true; value = expandBox.Text; box.Text = value; if config.Flag then UILibrary.Settings[config.Flag] = value end; isSyncing = false
	end))

	local function commit()
		value = box.Text
		if config.Flag then UILibrary.Settings[config.Flag] = value end
		if config.Callback then task.spawn(config.Callback, value) end
	end
	TrackConnection(box.FocusLost:Connect(commit))
	TrackConnection(expandBox.FocusLost:Connect(commit))

	local api = {}
	function api.SetValue(_self, newValue: string) box.Text = newValue; commit() end
	function api.GetValue(_self) return value end
	function api.AddKeybind(_self, subConfig: KeybindConfig)
		rowObj.UpdateOffset(60)
		ConstructKeybind(rowObj.InlineContainer, subConfig, true)
		return api
	end
	if config.Flag then Registry[config.Flag] = api end
	return api
end

CreateColorPicker = function(parent: Instance, config: ColorPickerConfig, isInline: boolean?)
	local rowObj, swatchParent, offsetAmt
	local currentColor = config.Default or Color3.fromRGB(255, 0, 0)
	local h, s, v = currentColor:ToHSV()

	if config.Flag then UILibrary.Settings[config.Flag] = currentColor end

	if isInline then
		swatchParent = parent
		offsetAmt = 36
	else
		rowObj = BuildRow(parent, config.Title, config.Description, config.TextColor, 55)
		swatchParent = rowObj.Instance
		offsetAmt = 48
	end

	local swatch = Create("TextButton", {
		Name = "Swatch",
		AnchorPoint = isInline and Vector2.new(0, 0) or Vector2.new(1, 0.5),
		Position = isInline and UDim2.new(0, 0, 0, 0) or UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, offsetAmt, 0, 26),
		BackgroundColor3 = currentColor,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 11,
		Parent = swatchParent,
	})
	AddCorner(swatch, Theme.CornerRadiusSmall)
	AddStroke(swatch)

	local overlay = GetOverlay(swatch)
	local blocker = Create("TextButton", { Name = "Blocker", BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 1, 0), ZIndex = 1000, Visible = false, Parent = overlay })
	local popup = Create("Frame", { Name = "Popup", Size = UDim2.new(0, 196, 0, 168), BackgroundColor3 = Theme.Elevated, Visible = false, ZIndex = 1001, Parent = overlay })
	AddCorner(popup, Theme.CornerRadiusCard)
	AddStroke(popup)
	AddPadding(popup, 14)

	local svSquare = Create("Frame", { Name = "SVSquare", Size = UDim2.new(0, 140, 0, 140), BackgroundColor3 = Color3.fromHSV(h, 1, 1), ZIndex = 1002, Parent = popup })
	AddCorner(svSquare, Theme.CornerRadiusSmall)
	local whiteOverlay = Create("Frame", { Name = "WhiteOverlay", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 1003, Parent = svSquare })
	AddCorner(whiteOverlay, Theme.CornerRadiusSmall); Create("UIGradient", { Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}), Parent = whiteOverlay })
	local blackOverlay = Create("Frame", { Name = "BlackOverlay", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 1004, Parent = svSquare })
	AddCorner(blackOverlay, Theme.CornerRadiusSmall); Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}), Parent = blackOverlay })

	local svHitArea = Create("Frame", { Name = "HitArea", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Active = true, ZIndex = 1006, Parent = svSquare })
	local svCursor = Create("Frame", { Name = "Cursor", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(s, 0, 1 - v, 0), Size = UDim2.new(0, 12, 0, 12), BackgroundTransparency = 1, ZIndex = 1005, Parent = svSquare })
	AddCorner(svCursor, UDim.new(1, 0)); AddStroke(svCursor, Color3.new(1, 1, 1), 2)

	local hueStrip = Create("Frame", { Name = "HueStrip", Position = UDim2.new(0, 152, 0, 0), Size = UDim2.new(0, 16, 0, 140), Active = true, ZIndex = 1002, Parent = popup })
	AddCorner(hueStrip, UDim.new(1, 0))
	Create("UIGradient", { Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)), ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)), ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)), ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)), ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)), ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)), ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))}), Parent = hueStrip })
	local hueCursor = Create("Frame", { Name = "Cursor", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, h, 0), Size = UDim2.new(1, 4, 0, 4), BackgroundTransparency = 1, ZIndex = 1005, Parent = hueStrip })
	AddCorner(hueCursor, UDim.new(1, 0)); AddStroke(hueCursor, Color3.new(1, 1, 1), 2)

	local function updateColor()
		currentColor = Color3.fromHSV(h, s, v); swatch.BackgroundColor3 = currentColor; svSquare.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.new(s, 0, 1 - v, 0); hueCursor.Position = UDim2.new(0.5, 0, h, 0)
		if config.Flag then UILibrary.Settings[config.Flag] = currentColor end
		if config.Callback then task.spawn(config.Callback, currentColor) end
	end

	local draggingSV, draggingHue = false, false
	local function setOpen(val: boolean)
		if val then local pos = swatch.AbsolutePosition; popup.Position = UDim2.fromOffset(pos.X + swatch.AbsoluteSize.X - popup.AbsoluteSize.X, pos.Y + swatch.AbsoluteSize.Y + 4)
		else draggingSV, draggingHue = false, false end
		popup.Visible = val; blocker.Visible = val
	end

	TrackConnection(swatch.MouseButton1Click:Connect(function() setOpen(not popup.Visible) end))
	TrackConnection(blocker.MouseButton1Click:Connect(function() setOpen(false) end))

	TrackConnection(svHitArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSV = true; s = math.clamp((input.Position.X - svSquare.AbsolutePosition.X) / svSquare.AbsoluteSize.X, 0, 1)
			v = 1 - math.clamp((input.Position.Y - svSquare.AbsolutePosition.Y) / svSquare.AbsoluteSize.Y, 0, 1); updateColor()
		end
	end))
	TrackConnection(hueStrip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingHue = true; h = math.clamp((input.Position.Y - hueStrip.AbsolutePosition.Y) / hueStrip.AbsoluteSize.Y, 0, 1); updateColor()
		end
	end))
	TrackConnection(UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if draggingSV then s = math.clamp((input.Position.X - svSquare.AbsolutePosition.X) / svSquare.AbsoluteSize.X, 0, 1); v = 1 - math.clamp((input.Position.Y - svSquare.AbsolutePosition.Y) / svSquare.AbsoluteSize.Y, 0, 1); updateColor()
		elseif draggingHue then h = math.clamp((input.Position.Y - hueStrip.AbsolutePosition.Y) / hueStrip.AbsoluteSize.Y, 0, 1); updateColor() end
	end))
	TrackConnection(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSV, draggingHue = false, false end
	end))

	local api = {}
	function api.SetValue(_self, color: Color3) h, s, v = color:ToHSV(); updateColor(); if config.Callback then task.spawn(config.Callback, currentColor) end end
	function api.GetValue(_self) return currentColor end

	if config.Flag then Registry[config.Flag] = api end
	return api
end


-- ---------- Section ----------

local Section = {}
Section.__index = Section

function Section.new(parent: Instance, title: string, textColor: Color3?, columns: number?, rowHeight: number?)
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

	local numColumns = math.max(1, math.floor(columns or 1))
	if numColumns > 1 then
		Create("UIGridLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			CellPadding = UDim2.new(0, 6, 0, 6),
			CellSize = UDim2.new(1 / numColumns, -6, 0, rowHeight or 44),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Parent = list,
		})
	else
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = list })
	end

	RegisterThemeRefresh(function() header.TextColor3 = textColor or Theme.TextMuted end)

	table.insert(SectionsData, { Container = container, List = list })

	self._container = container
	self._list = list
	return self
end

function Section:CreateButton(config: ButtonConfig) return CreateButton(self._list, config) end
function Section:CreateToggle(config: ToggleConfig) return CreateToggle(self._list, config) end
function Section:CreateSlider(config: SliderConfig) return CreateSlider(self._list, config) end
function Section:CreateDropdown(config: DropdownConfig) return CreateDropdown(self._list, config) end
function Section:CreateMultiDropdown(config: MultiDropdownConfig) return CreateMultiDropdown(self._list, config) end
function Section:CreateLabel(config: LabelConfig) return CreateLabel(self._list, config) end
function Section:CreateInput(config: InputConfig) return CreateInput(self._list, config) end
function Section:CreateStringInput(config: StringInputConfig) return CreateStringInput(self._list, config) end
function Section:CreateColorPicker(config: ColorPickerConfig) return CreateColorPicker(self._list, config) end
function Section:CreateKeybind(config: KeybindConfig) return CreateKeybind(self._list, config) end

-- ---------- Tab ----------

local Tab = {}
Tab.__index = Tab

function Tab.new(pageContainer: ScrollingFrame, tabButton: TextButton)
	local self = setmetatable({}, Tab)
	self._page = pageContainer
	self._button = tabButton
	return self
end

function Tab:CreateSection(title: string, textColor: Color3?, columns: number?, rowHeight: number?) return Section.new(self._page, title, textColor, columns, rowHeight) end
function Tab:CreateButton(config: ButtonConfig) return CreateButton(self._page, config) end
function Tab:CreateToggle(config: ToggleConfig) return CreateToggle(self._page, config) end
function Tab:CreateSlider(config: SliderConfig) return CreateSlider(self._page, config) end
function Tab:CreateDropdown(config: DropdownConfig) return CreateDropdown(self._page, config) end
function Tab:CreateMultiDropdown(config: MultiDropdownConfig) return CreateMultiDropdown(self._page, config) end
function Tab:CreateLabel(config: LabelConfig) return CreateLabel(self._page, config) end
function Tab:CreateInput(config: InputConfig) return CreateInput(self._page, config) end
function Tab:CreateStringInput(config: StringInputConfig) return CreateStringInput(self._page, config) end
function Tab:CreateColorPicker(config: ColorPickerConfig) return CreateColorPicker(self._page, config) end
function Tab:CreateKeybind(config: KeybindConfig) return CreateKeybind(self._page, config) end

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
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = screenGui,
	})
	AddCorner(main, Theme.CornerRadius)

	local borderFrame = Create("Frame", {
		Name = "BorderFrame",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.999,
		ZIndex = 100,
		Parent = main,
	})
	AddCorner(borderFrame, Theme.CornerRadius)
	AddStroke(borderFrame, Theme.Border, 1)

	local mainBg = Create("Frame", {
		Name = "MainBackground",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = Theme.BackgroundTransparency,
		BorderSizePixel = 0,
		ZIndex = -10,
		Parent = main,
	})
	AddCorner(mainBg, Theme.CornerRadius)

	local mainGradient = Create("UIGradient", {
		Name = "Gradient", Rotation = 45,
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.GradientColor1), ColorSequenceKeypoint.new(1, Theme.GradientColor2) }),
		Enabled = Theme.UseGradient, Parent = mainBg,
	})

	local elevatedGroup = Create("CanvasGroup", {
		Name = "ElevatedGroup", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, GroupTransparency = Theme.ElevatedTransparency,
		BorderSizePixel = 0, ZIndex = -5, Parent = main,
	})
	AddCorner(elevatedGroup, Theme.CornerRadius)

	local topBarVisual = Create("Frame", { Name = "TopBarVisual", Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Theme.Elevated, BorderSizePixel = 0, Parent = elevatedGroup })
	local tabBarVisual = Create("Frame", { Name = "TabBarVisual", Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(0, 140, 1, -44), BackgroundColor3 = Theme.Elevated, BorderSizePixel = 0, Parent = elevatedGroup })

	local topBar = Create("Frame", { Name = "TopBar", Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = main })
	local topBarContent = Create("Frame", { Name = "Content", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = topBar })
	AddPadding(topBarContent, 12)

	self._windowIconId = FormatAssetId(config.Icon or "108153360181769")
	self._bubbleIconId = FormatAssetId(config.BubbleIcon or "130469235401309")

	local textOffset = 32
	self._titleIcon = Create("ImageLabel", {
		Name = "TitleIcon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 24, 0, 24),
		BackgroundTransparency = 1,
		Image = self._windowIconId,
		ScaleType = Enum.ScaleType.Fit,
		Parent = topBarContent,
	})
	AddCorner(self._titleIcon, UDim.new(1, 0))

	local windowTitle = Create("TextLabel", {
		Name = "Title",
		Position = UDim2.new(0, textOffset, 0, 0),
		Size = UDim2.new(1, -180 - textOffset, 1, 0),
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

	local controls = Create("Frame", { Name = "Controls", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 56, 0, 24), BackgroundTransparency = 1, Parent = topBarContent })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Parent = controls })

	local minimizeButton = Create("TextButton", { Name = "Minimize", Size = UDim2.new(0, 24, 0, 24), BackgroundColor3 = Theme.Border, BackgroundTransparency = 0.3, AutoButtonColor = false, Text = "", Parent = controls })
	AddCorner(minimizeButton, UDim.new(1, 0)); Create("Frame", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 10, 0, 2), BackgroundColor3 = Theme.TextSecondary, BorderSizePixel = 0, Parent = minimizeButton })

	local closeButton = Create("TextButton", { Name = "Close", Size = UDim2.new(0, 24, 0, 24), BackgroundColor3 = Theme.Danger, BackgroundTransparency = 0.3, AutoButtonColor = false, Text = "", Parent = controls })
	AddCorner(closeButton, UDim.new(1, 0)); Create("Frame", { Name = "IconA", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 12, 0, 2), Rotation = 45, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = closeButton }); Create("Frame", { Name = "IconB", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 12, 0, 2), Rotation = -45, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = closeButton })

	TrackConnection(minimizeButton.MouseEnter:Connect(function() Tween(minimizeButton, { BackgroundTransparency = 0 }) end))
	TrackConnection(minimizeButton.MouseLeave:Connect(function() Tween(minimizeButton, { BackgroundTransparency = 0.3 }) end))
	TrackConnection(closeButton.MouseEnter:Connect(function() Tween(closeButton, { BackgroundTransparency = 0 }) end))
	TrackConnection(closeButton.MouseLeave:Connect(function() Tween(closeButton, { BackgroundTransparency = 0.3 }) end))

	MakeDraggable(topBar, main)

	local body = Create("Frame", { Name = "Body", Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(1, 0, 1, -44), BackgroundTransparency = 1, Parent = main })

	local tabBarContainer = Create("Frame", { Name = "TabBarContainer", Size = UDim2.new(0, 140, 1, 0), BackgroundTransparency = 1, Parent = body })

	local searchContainer = Create("Frame", {
		Name = "SearchContainer",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Parent = tabBarContainer
	})
	AddPadding(searchContainer, 8)

	local searchBox = Create("TextBox", {
		Name = "SearchBox",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.Background,
		Font = Theme.Font,
		PlaceholderText = "Search...",
		Text = "",
		TextColor3 = Theme.TextPrimary,
		PlaceholderColor3 = Theme.TextMuted,
		TextSize = 12,
		ClearTextOnFocus = false,
		Parent = searchContainer,
	})
	AddCorner(searchBox, Theme.CornerRadiusSmall)
	AddStroke(searchBox)
	AddPadding(searchBox, 6)

	local tabBar = Create("ScrollingFrame", {
		Name = "TabBar",
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(1, 0, 1, -40),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = tabBarContainer,
	})
	AddPadding(tabBar, 8)
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = tabBar })

	local pages = Create("Frame", { Name = "Pages", Position = UDim2.new(0, 140, 0, 0), Size = UDim2.new(1, -140, 1, 0), BackgroundTransparency = 1, Parent = body })

	local resizeHandle = Create("Frame", { Name = "ResizeHandle", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 1, Active = true, ZIndex = 50, Parent = main })
	for _, p in ipairs({ {2,0}, {1,1}, {2,1}, {0,2}, {1,2}, {2,2} }) do
		local d = Create("Frame", { Size = UDim2.new(0, 3, 0, 3), Position = UDim2.new(0, p[1]*5, 0, p[2]*5), BackgroundColor3 = Theme.TextMuted, BackgroundTransparency = 0.3, ZIndex = 50, Parent = resizeHandle })
		AddCorner(d, UDim.new(1, 0))
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
	self._toggleKey = config.ToggleKey :: Enum.KeyCode?

	TrackConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query = searchBox.Text:lower()
		for _, data in ipairs(SearchableRows) do
			if query == "" then
				data.Row.Visible = true
			else
				data.Row.Visible = string.find(data.SearchText, query, 1, true) ~= nil
			end
		end

		for _, sec in ipairs(SectionsData) do
			if query == "" then
				sec.Container.Visible = true
			else
				local hasVisible = false
				for _, child in ipairs(sec.List:GetChildren()) do
					if child:IsA("Frame") and child.Name == "Row" and child.Visible then
						hasVisible = true
						break
					end
				end
				sec.Container.Visible = hasVisible
			end
		end
	end))

	RegisterThemeRefresh(function()
		if Theme.UseGradient then
			mainBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			mainGradient.Enabled = true
			mainGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.GradientColor1), ColorSequenceKeypoint.new(1, Theme.GradientColor2) })
		else
			mainBg.BackgroundColor3 = Theme.Background
			mainGradient.Enabled = false
		end
		mainBg.BackgroundTransparency = Theme.BackgroundTransparency
		elevatedGroup.GroupTransparency = Theme.ElevatedTransparency
		topBarVisual.BackgroundColor3 = Theme.Elevated; tabBarVisual.BackgroundColor3 = Theme.Elevated
		windowTitle.TextColor3 = Theme.TextPrimary

		searchBox.BackgroundColor3 = Theme.Background
		searchBox.TextColor3 = Theme.TextPrimary
		searchBox.PlaceholderColor3 = Theme.TextMuted

		local mainStroke = borderFrame:FindFirstChildWhichIsA("UIStroke")
		if mainStroke then mainStroke.Color = Theme.Border end

		for _, tab in ipairs(self._tabs) do
			local stroke = tab._button:FindFirstChildWhichIsA("UIStroke")
			if tab._button == self._activeTabButton then
				tab._button.BackgroundColor3 = Theme.Background
				tab._button.BackgroundTransparency = Theme.UseGradient and 1 or 0
				tab._button.TextColor3 = Theme.TextPrimary
				if stroke then stroke.Color = Theme.Secondary; stroke.Transparency = 0 end
			else
				tab._button.BackgroundColor3 = Theme.Background
				tab._button.BackgroundTransparency = 0
				tab._button.TextColor3 = Theme.TextSecondary
				if stroke then stroke.Color = Theme.Border; stroke.Transparency = 0 end
			end
		end
	end)

	TrackConnection(minimizeButton.MouseButton1Click:Connect(function() self:Minimize() end))
	TrackConnection(closeButton.MouseButton1Click:Connect(function() if self._onClose then task.spawn(self._onClose) end self:Destroy() end))

	local resizing, resizeStart, startSize = false, Vector2.new(), UDim2.new()
	TrackConnection(resizeHandle.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = true; resizeStart = input.Position; startSize = main.Size end end))
	TrackConnection(UserInputService.InputChanged:Connect(function(input)
		if resizing then
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				main.Size = UDim2.new(0, math.clamp(startSize.X.Offset + (input.Position.X - resizeStart.X), self._minSize.X, self._maxSize.X), 0, math.clamp(startSize.Y.Offset + (input.Position.Y - resizeStart.Y), self._minSize.Y, self._maxSize.Y))
			end
		end
	end))
	TrackConnection(UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = false end end))

	TrackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if self._toggleKey and input.KeyCode == self._toggleKey then
			if self._minimized then self:Restore() else self:Minimize() end
		end
	end))

	return self
end

function Window:SetWindowIcon(assetId: string)
	self._windowIconId = FormatAssetId(assetId)
	if self._titleIcon then
		self._titleIcon.Image = self._windowIconId
	end
end

function Window:SetBubbleIcon(assetId: string)
	self._bubbleIconId = FormatAssetId(assetId)
	if self._bubbleIconImage then
		self._bubbleIconImage.Image = self._bubbleIconId
	end
end

function Window:SetToggleKey(key: Enum.KeyCode)
	task.delay(0.1, function()
		self._toggleKey = key
	end)
end

function Window:CreateTabCategory(name: string, textColor: Color3?)
	self._tabBarOrder += 1
	local label = Create("TextLabel", { Name = "Category_" .. name, LayoutOrder = self._tabBarOrder, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Font = Theme.FontBold, Text = string.upper(name), TextColor3 = textColor or Theme.TextMuted, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = self._tabBar })
	RegisterThemeRefresh(function() label.TextColor3 = textColor or Theme.TextMuted end)
	return label
end

function Window:CreateTab(config: TabConfig)
	self._tabBarOrder += 1
	local button = Create("TextButton", { Name = "Tab_" .. config.Name, LayoutOrder = self._tabBarOrder, Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Background, AutoButtonColor = false, Font = Theme.FontSemibold, Text = config.Name, TextColor3 = Theme.TextSecondary, TextSize = 13, Parent = self._tabBar })
	AddCorner(button, Theme.CornerRadiusSmall)
	local stroke = AddStroke(button, Theme.Border, 1)
	stroke.Transparency = 0

	local page = Create("ScrollingFrame", { Name = "Page_" .. config.Name, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = self._pages })
	AddPadding(page, 12)
	local pageColumns = math.max(1, math.floor(config.Columns or 1))
	if pageColumns > 1 then Create("UIGridLayout", { SortOrder = Enum.SortOrder.LayoutOrder, CellPadding = UDim2.new(0, 10, 0, 10), CellSize = UDim2.new(1 / pageColumns, -10, 0, config.RowHeight or 44), FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Left, Parent = page })
	else Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = page }) end

	local tab = Tab.new(page, button)
	table.insert(self._tabs, tab)

	local function selectTab()
		for _, other in ipairs(self._tabs) do
			other._page.Visible = false
			Tween(other._button, { BackgroundColor3 = Theme.Background, TextColor3 = Theme.TextSecondary })
			local otherStroke = other._button:FindFirstChildWhichIsA("UIStroke")
			if otherStroke then Tween(otherStroke, { Color = Theme.Border, Transparency = 0 }) end
			other._button.BackgroundTransparency = 0
		end
		page.Visible = true
		local targetTrans = Theme.UseGradient and 1 or 0
		Tween(button, { BackgroundColor3 = Theme.Background, TextColor3 = Theme.TextPrimary, BackgroundTransparency = targetTrans })
		Tween(stroke, { Color = Theme.Secondary, Transparency = 0 })
		self._activeTabButton = button
	end

	TrackConnection(button.MouseButton1Click:Connect(selectTab))
	if not self._firstTab then self._firstTab = page; selectTab() end
	return tab
end

function Window:CreateThemeTab(config: TabConfig?)
	local tab = self:CreateTab(config or { Name = "Theme Settings" })

	local menuSection = tab:CreateSection("Menu Settings")
	menuSection:CreateKeybind({ 
		Title = "Menu Toggle Key", 
		Description = "Key used to hide/show the menu.", 
		Default = self._toggleKey or Enum.KeyCode.RightControl, 
		Flag = "Theme_ToggleKey", 
		ChangedCallback = function(key) self:SetToggleKey(key) end 
	})

	local bgSection = tab:CreateSection("Background & Gradient")
	bgSection:CreateToggle({ Title = "Use Gradient Background", Description = "Enable a 2-color gradient transition", Default = Theme.UseGradient, Flag = "Theme_UseGradient", Callback = function(state) UILibrary:SetTheme({ UseGradient = state }) end })
	bgSection:CreateColorPicker({ Title = "Solid Background", Description = "Main background color (when gradient is off)", Default = Theme.Background, Flag = "Theme_Background", Callback = function(color) local h, s, v = color:ToHSV() UILibrary:SetTheme({ Background = color, Elevated = Color3.fromHSV(h, s, math.clamp(v + 0.03, 0, 1)) }) end })
	bgSection:CreateColorPicker({ Title = "Gradient Color 1", Description = "Top-left transition color", Default = Theme.GradientColor1, Flag = "Theme_GradientColor1", Callback = function(color) UILibrary:SetTheme({ GradientColor1 = color }) end })
	bgSection:CreateColorPicker({ Title = "Gradient Color 2", Description = "Bottom-right transition color", Default = Theme.GradientColor2, Flag = "Theme_GradientColor2", Callback = function(color) UILibrary:SetTheme({ GradientColor2 = color }) end })

	local colorSection = tab:CreateSection("Accent Colors")
	colorSection:CreateColorPicker({ Title = "Secondary Color", Description = "Buttons, sliders, selected states", Default = Theme.Secondary, Flag = "Theme_Secondary", Callback = function(color) local h, s, v = color:ToHSV() UILibrary:SetTheme({ Secondary = color, Accent = Color3.fromHSV(h, s, math.clamp(v + 0.15, 0, 1)) }) end })
	colorSection:CreateColorPicker({ Title = "Text Color", Description = "Global color for normal titles and labels", Default = Theme.TextPrimary, Flag = "Theme_Text", Callback = function(color) UILibrary:SetTheme({ TextPrimary = color, TextSecondary = color, TextMuted = color }) end })
	colorSection:CreateColorPicker({ Title = "Border Color", Description = "Color for inactive tabs and element outlines", Default = Theme.Border, Flag = "Theme_Border", Callback = function(color) UILibrary:SetTheme({ Border = color }) end })

	local footerLabel = Create("TextLabel", {
		Name = "StorageFooter",
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Theme.Font,
		Text = "Environment: " .. UILibrary:GetTargetGuiName(),
		TextColor3 = Theme.TextMuted,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 999,
		Parent = tab._page,
	})
	RegisterThemeRefresh(function()
		footerLabel.TextColor3 = Theme.TextMuted
		footerLabel.Text = "Environment: " .. UILibrary:GetTargetGuiName()
	end)

	return tab
end

function Window:CreateIntegrationTab(config: TabConfig?)
	local tab = self:CreateTab(config or { Name = "Integrations" })

	local webhookSection = tab:CreateSection("Discord Webhooks")

	webhookSection:CreateStringInput({
		Title = "Webhook URL",
		Description = "Enter your webhook URL to enable notifications.",
		Placeholder = "https://discord.com/api/webhooks/...",
		Flag = "Theme_DiscordWebhook"
	})

	webhookSection:CreateButton({
		Title = "Test Webhook",
		Description = "Sends a test message to your Discord server.",
		Callback = function()
			local url = UILibrary.Settings["Theme_DiscordWebhook"]

			if not url or url == "" or not string.match(url, "discord%.com/api/webhooks") then
				UILibrary:Notify({ Title = "Webhook Error", Content = "Please enter a valid Discord Webhook URL.", Duration = 3 })
				return
			end

			local requestFunc = request or http_request or (syn and syn.request)
			if not requestFunc then
				UILibrary:Notify({ Title = "Error", Content = "Your executor does not support HTTP requests.", Duration = 3 })
				return
			end

			task.spawn(function()
				local success, response = pcall(function()
					return requestFunc({
						Url = url,
						Method = "POST",
						Headers = { ["Content-Type"] = "application/json" },
						Body = game:GetService("HttpService"):JSONEncode({
							username = "VariaUI Notifications",
							content = "Webhook is Working!"
						})
					})
				end)

				if success then
					UILibrary:Notify({ Title = "Success", Content = "Test webhook sent successfully!", Duration = 3 })
				else
					UILibrary:Notify({ Title = "Failed", Content = "Could not send webhook.", Duration = 3 })
				end
			end)
		end
	})

	return tab
end

function Window:OnClose(callback: () -> ()) self._onClose = callback end

function Window:Destroy() 
	for _, conn in ipairs(ActiveConnections) do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(ActiveConnections)
	table.clear(Registry)
	table.clear(SearchableRows)
	table.clear(SectionsData)
	table.clear(BoundKeys)

	if Tooltip.Connection then
		Tooltip.Connection:Disconnect()
		Tooltip.Connection = nil
	end

	if NotificationScreenGui then
		NotificationScreenGui:Destroy()
		NotificationScreenGui = nil
	end

	self._screenGui:Destroy() 
end

function Window:SetVisible(visible: boolean) self._main.Visible = visible end

function Window:Minimize()
	if self._minimized then return end
	self._minimized = true; self._main.Visible = false
	if self._bubble then local b = self._bubble :: TextButton b.Visible = true return end

	local bubble = Create("TextButton", { Name = "Bubble", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 52, 0, 52), BackgroundColor3 = Color3.fromRGB(10, 10, 12), AutoButtonColor = false, Text = "", ZIndex = 500, Parent = self._screenGui })
	AddCorner(bubble, UDim.new(1, 0)); AddStroke(bubble, Theme.Border, 2)

	self._bubbleIconImage = Create("ImageLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = self._bubbleIconId,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 501,
		Parent = bubble
	})
	AddCorner(self._bubbleIconImage, UDim.new(1, 0))

	local dragging = false
	local dragStart = Vector2.new()
	local startPos = UDim2.new()
	local dragDistance = 0

	TrackConnection(bubble.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then return end
			dragging = true
			dragDistance = 0
			dragStart = input.Position
			startPos = bubble.Position
		end
	end))

	TrackConnection(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			dragDistance = delta.Magnitude
			bubble.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end))

	TrackConnection(UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			if dragDistance < 6 then
				self:Restore()
			end
		end
	end))

	self._bubble = bubble
end

function Window:Restore()
	if not self._minimized then return end
	self._minimized = false; self._main.Visible = true
	if self._bubble then local b = self._bubble :: TextButton b.Visible = false end
end

function Window:ToggleMinimize()
	if self._minimized then self:Restore() else self:Minimize() end
end

function UILibrary:CreateWindow(config: WindowConfig?) return Window.new(config or {}) end

function UILibrary:GetSettings(): { [string]: any }
	local safeSettings = {}
	for key, val in pairs(UILibrary.Settings) do
		if typeof(val) == "Color3" then safeSettings[key] = { type = "Color3", r = val.R, g = val.G, b = val.B } else safeSettings[key] = val end
	end
	return safeSettings
end

function UILibrary:LoadSettings(savedData: { [string]: any })
	if type(savedData) ~= "table" then return end

	local function processFlag(flag, value)
		local parsedValue = value
		if type(value) == "table" and value.type == "Color3" then 
			parsedValue = Color3.new(value.r, value.g, value.b) 
		end

		UILibrary.Settings[flag] = parsedValue
		local componentApi = Registry[flag]

		if componentApi and componentApi.SetValue then 
			pcall(function() componentApi:SetValue(parsedValue) end) 
		end
	end

	for flag, value in pairs(savedData) do
		if string.find(flag, "Theme_") then
			processFlag(flag, value)
		end
	end

	for flag, value in pairs(savedData) do
		if not string.find(flag, "Theme_") then
			processFlag(flag, value)
		end
	end
end

function UILibrary:SetTheme(overrides: { [string]: any })
	for key, value in pairs(overrides) do local t = Theme :: any t[key] = value end
	for _, refresh in ipairs(ThemeRefreshCallbacks) do refresh() end
end

return UILibrary