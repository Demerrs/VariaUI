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

export type PriorityListConfig = {
	Title: string,
	Description: string?,
	TextColor: Color3?,
	Items: { string },
	Flag: string?,
	Callback: ((items: { string }) -> ())?,
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
	StartHidden: boolean?,
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
-- Theme & Global State
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
	KnobColor = Color3.fromRGB(255, 255, 255),
	ButtonTextColor = Color3.fromRGB(255, 255, 255),
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

local GlobalIsDragging = false

-- ============================================================
-- Per-Window Context
-- ============================================================

local function NewContext()
	local ctx = {
		_RawSettings = {} :: { [string]: any },
		Registry = {} :: { [string]: any },
		SearchableRows = {} :: { { Row: Frame, SearchText: string } },
		SectionsData = {} :: { { Container: Frame, List: Frame, TitleLower: string } },
		ExpandableGroups = {} :: { { Container: Frame, Content: Frame, Arrow: TextLabel?, TitleLower: string, GetExpanded: () -> boolean } },
		BoundKeys = {} :: { [Enum.KeyCode]: boolean },
		ActiveConnections = {} :: { RBXScriptConnection },
		OnChange = nil :: ((settings: { [string]: any }) -> ())?,
		IsLoading = false,
		SaveTick = 0,
	}

	ctx.Settings = setmetatable({}, {
		__index = ctx._RawSettings,
		__newindex = function(_, key, value)
			ctx._RawSettings[key] = value

			if ctx.OnChange and not ctx.IsLoading then
				ctx.SaveTick += 1
				local currentTick = ctx.SaveTick

				task.delay(0.5, function()
					if ctx.SaveTick == currentTick then
						local safeSettings = {}
						for k, v in pairs(ctx._RawSettings) do
							if typeof(v) == "Color3" then
								safeSettings[k] = { type = "Color3", r = v.R, g = v.G, b = v.B }
							else
								safeSettings[k] = v
							end
						end
						task.spawn(ctx.OnChange, safeSettings)
					end
				end)
			end
		end
	})

	return ctx
end

local function TrackConnection(ctx: any, conn: RBXScriptConnection): RBXScriptConnection
	table.insert(ctx.ActiveConnections, conn)
	return conn
end

-- ============================================================
-- Utilities
-- ============================================================

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
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 1000,
		Parent = screenGui,
	}) :: Frame
end

local function MakeDraggable(ctx: any, dragHandle: GuiObject, target: GuiObject)
	local dragging = false
	local dragStart: Vector3
	local startPos: UDim2

	TrackConnection(ctx, dragHandle.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			GlobalIsDragging = true
			dragStart = input.Position
			startPos = target.Position
		end
	end))

	TrackConnection(ctx, UserInputService.InputChanged:Connect(function(input: InputObject)
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

	TrackConnection(ctx, UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			GlobalIsDragging = false
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
	if GlobalIsDragging then return end

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
	Tooltip.Connection = RunService.RenderStepped:Connect(function()
		local mouse = UserInputService:GetMouseLocation()
		if Tooltip.Frame then
			Tooltip.Frame.Position = UDim2.fromOffset(mouse.X + 15, mouse.Y - 20)
		end
	end)
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

-- ---------- Responsive layout helpers ----------

local MIN_STACK_TITLE_WIDTH = 90
local ROW_PADDING_X = 28
local STACK_GAP = 6

local function MakeRowResponsive(ctx: any, row: Frame, titleLabel: TextLabel, descLabel: TextLabel?, baseOffset: number, controlHeight: number?)
	local cHeight = controlHeight or 26
	local hasDesc = descLabel ~= nil

	local controls = {}
	for _, child in ipairs(row:GetChildren()) do
		if child:IsA("GuiObject") and child.AnchorPoint.X >= 1 and child.AnchorPoint.Y == 0.5 then
			table.insert(controls, {
				Inst = child,
				WideAnchor = child.AnchorPoint,
				WidePosition = child.Position,
			})
		end
	end
	if #controls == 0 then return end

	local wideTitlePos, wideTitleSize, wideTitleAlign = titleLabel.Position, titleLabel.Size, titleLabel.TextYAlignment
	local wideDescPos, wideDescSize
	if descLabel then
		wideDescPos = descLabel.Position
		wideDescSize = descLabel.Size
	end
	local wideRowSize = row.Size

	local textBlockHeight = hasDesc and 32 or 18
	local controlLineY = textBlockHeight + STACK_GAP
	local stackedHeight = controlLineY + cHeight + ROW_PADDING_X

	local isStacked = false

	local function applyLayout()
		local avail = row.AbsoluteSize.X
		if avail <= 0 then return end

		local actualTextWidth = titleLabel.TextBounds.X
		local needed = baseOffset + actualTextWidth + ROW_PADDING_X
		local shouldStack = avail < needed
		isStacked = shouldStack

		if isStacked then
			titleLabel.Position = UDim2.new(0, 0, 0, 0)
			titleLabel.Size = UDim2.new(1, 0, 0, 16)
			titleLabel.TextYAlignment = Enum.TextYAlignment.Top

			if descLabel then
				descLabel.Position = UDim2.new(0, 0, 0, 18)
				descLabel.Size = UDim2.new(1, 0, 0, 14)
			end

			for _, c in ipairs(controls) do
				c.Inst.AnchorPoint = Vector2.new(0, 0)
				c.Inst.Position = UDim2.new(0, 0, 0, controlLineY)
			end

			row.Size = UDim2.new(wideRowSize.X.Scale, wideRowSize.X.Offset, 0, stackedHeight)
		else
			titleLabel.Position = wideTitlePos
			titleLabel.Size = wideTitleSize
			titleLabel.TextYAlignment = wideTitleAlign

			if descLabel and wideDescPos and wideDescSize then
				descLabel.Position = wideDescPos
				descLabel.Size = wideDescSize
			end

			for _, c in ipairs(controls) do
				c.Inst.AnchorPoint = c.WideAnchor
				c.Inst.Position = c.WidePosition
			end

			row.Size = wideRowSize
		end
	end

	TrackConnection(ctx, row:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyLayout))
	applyLayout()
end

local MIN_GRID_COLUMN_WIDTH = 190

local function MakeGridResponsive(ctx: any, container: Frame, gridLayout: UIGridLayout, maxColumns: number, cellHeight: number, minColumnWidth: number?)
	local minWidth = minColumnWidth or MIN_GRID_COLUMN_WIDTH
	local currentColumns = maxColumns

	local function apply()
		local avail = container.AbsoluteSize.X
		if avail <= 0 then return end

		local fitColumns = math.max(1, math.floor((avail + 6) / (minWidth + 6)))
		local newColumns = math.clamp(fitColumns, 1, maxColumns)

		local maxH = cellHeight
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("GuiObject") and child ~= gridLayout then
				if child.Size.Y.Offset > maxH then
					maxH = child.Size.Y.Offset
				end
			end
		end

		if newColumns ~= currentColumns or gridLayout.CellSize.Y.Offset ~= maxH then
			currentColumns = newColumns
			gridLayout.CellSize = UDim2.new(1 / currentColumns, -6, 0, maxH)
		end
	end

	TrackConnection(ctx, container:GetPropertyChangedSignal("AbsoluteSize"):Connect(apply))

	TrackConnection(ctx, container.ChildAdded:Connect(function(child)
		if child:IsA("GuiObject") then
			TrackConnection(ctx, child:GetPropertyChangedSignal("Size"):Connect(apply))
			apply()
		end
	end))

	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") and child ~= gridLayout then
			TrackConnection(ctx, child:GetPropertyChangedSignal("Size"):Connect(apply))
		end
	end

	apply()
end

local MIN_PAGE_COLUMN_WIDTH = 220

local function MakePageColumnsResponsive(ctx: any, columnsContainer: Frame, listLayout: UIListLayout, columns: { Frame }, columnCount: number)
	local isStacked = false

	local function apply()
		local avail = columnsContainer.AbsoluteSize.X
		if avail <= 0 then return end

		local shouldStack = avail < (MIN_PAGE_COLUMN_WIDTH * columnCount + 10 * (columnCount - 1))
		if shouldStack == isStacked then return end
		isStacked = shouldStack

		if isStacked then
			listLayout.FillDirection = Enum.FillDirection.Vertical
			for _, col in ipairs(columns) do
				col.Size = UDim2.new(1, 0, 0, 0)
			end
		else
			listLayout.FillDirection = Enum.FillDirection.Horizontal
			for _, col in ipairs(columns) do
				col.Size = UDim2.new(1 / columnCount, -10 * (columnCount - 1) / columnCount, 0, 0)
			end
		end
	end

	TrackConnection(ctx, columnsContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(apply))
	apply()
end

-- ---------- Component builders ----------

local function BuildRow(ctx: any, parent: Instance, title: string, description: string?, textColor: Color3?, rightOffset: number?)
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
		Position = UDim2.new(0, 0, 0, description and -4 or 0),
		Size = UDim2.new(1, -baseOffset, description and 0 or 1, description and 16 or 0),
		BackgroundTransparency = 1,
		Font = Theme.FontSemibold,
		Text = title,
		TextColor3 = textColor or Theme.TextPrimary,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = description and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		TextWrapped = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	local descLabel
	if description then
		descLabel = Create("TextLabel", {
			Name = "Description",
			Position = UDim2.new(0, 0, 0, 14), 
			Size = UDim2.new(1, -baseOffset, 0, 14),
			BackgroundTransparency = 1,
			Font = Theme.Font,
			Text = description,
			TextColor3 = Theme.TextSecondary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
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
	TrackConnection(ctx, row.MouseEnter:Connect(function()
		hoverTick = os.clock()
		local currentTick = hoverTick
		task.delay(0.5, function()
			if hoverTick == currentTick then ShowTooltip(row, title, description) end
		end)
	end))
	TrackConnection(ctx, row.MouseLeave:Connect(function()
		hoverTick = 0
		HideTooltip()
	end))

	table.insert(ctx.SearchableRows, { 
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
			titleLabel.Size = UDim2.new(1, -totalOffset, description and 0 or 1, description and 16 or 0)
			if descLabel then descLabel.Size = UDim2.new(1, -totalOffset, 0, 14) end
		end,

		Finalize = function(controlHeight: number?)
			MakeRowResponsive(ctx, row, titleLabel, descLabel, baseOffset, controlHeight)
		end,
	}
end

-- ============================================================
-- Core Components
-- ============================================================

local CreateColorPicker

local function ConstructKeybind(ctx: any, parent: Instance, config: KeybindConfig, isInline: boolean)
	local rowObj, buttonParent, width
	local key = config.Default or Enum.KeyCode.Unknown

	if key ~= Enum.KeyCode.Unknown then
		if ctx.BoundKeys[key] then
			key = Enum.KeyCode.Unknown
		else
			ctx.BoundKeys[key] = true
		end
	end

	if config.Flag then
		ctx.Settings[config.Flag] = key.Name
	end

	if isInline then
		buttonParent = parent
		width = 60
	else
		rowObj = BuildRow(ctx, parent, config.Title, config.Description, config.TextColor, 74)
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

		if newKey ~= Enum.KeyCode.Unknown and ctx.BoundKeys[newKey] then
			UILibrary:Notify({
				Title = "Key Unavailable",
				Content = "The key [" .. newKey.Name .. "] is already bound to another action.",
				Duration = 3
			})
			button.Text = key == Enum.KeyCode.Unknown and "[ None ]" or "[ " .. key.Name .. " ]"
			return false
		end

		if key ~= Enum.KeyCode.Unknown then
			ctx.BoundKeys[key] = nil
		end
		if newKey ~= Enum.KeyCode.Unknown then
			ctx.BoundKeys[newKey] = true
		end

		key = newKey
		button.Text = key == Enum.KeyCode.Unknown and "[ None ]" or "[ " .. key.Name .. " ]"
		if config.Flag then ctx.Settings[config.Flag] = key.Name end

		if config.ChangedCallback then task.spawn(config.ChangedCallback, key) end

		return true
	end

	TrackConnection(ctx, button.MouseButton1Click:Connect(function()
		waitingForInput = true
		button.Text = "[ ... ]"
	end))

	TrackConnection(ctx, UserInputService.InputBegan:Connect(function(input, gpe)
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
		ctx.Registry[config.Flag] = api
	end

	if rowObj then rowObj.Finalize(26) end

	return api
end

local function CreateKeybind(ctx: any, parent: Instance, config: KeybindConfig)
	return ConstructKeybind(ctx, parent, config, false)
end

local function CreateButton(ctx: any, parent: Instance, config: ButtonConfig)
	local rowObj = BuildRow(ctx, parent, config.Title, config.Description, config.TextColor, 74)

	local button = Create("TextButton", {
		Name = "Button",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 64, 0, 26),
		BackgroundColor3 = Theme.Secondary,
		Font = Theme.FontSemibold,
		Text = "Run",
		TextColor3 = Theme.ButtonTextColor,
		TextSize = 13,
		AutoButtonColor = false,
		ZIndex = 11,
		Parent = rowObj.Instance,
	})
	AddCorner(button, Theme.CornerRadiusSmall)

	RegisterThemeRefresh(function() 
		button.BackgroundColor3 = Theme.Secondary
		button.TextColor3 = Theme.ButtonTextColor 
	end)

	TrackConnection(ctx, button.MouseEnter:Connect(function() Tween(button, { BackgroundColor3 = Theme.Accent }) end))
	TrackConnection(ctx, button.MouseLeave:Connect(function() Tween(button, { BackgroundColor3 = Theme.Secondary }) end))
	TrackConnection(ctx, button.MouseButton1Click:Connect(function()
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
		ConstructKeybind(ctx, rowObj.InlineContainer, subConfig, true)
		return api
	end
	function api.AddColorPicker(_self, subConfig: ColorPickerConfig)
		rowObj.UpdateOffset(36)
		CreateColorPicker(ctx, rowObj.InlineContainer, subConfig, true)
		return api
	end

	rowObj.Finalize(26)

	return api
end

local function CreateToggle(ctx: any, parent: Instance, config: ToggleConfig)
	local rowObj = BuildRow(ctx, parent, config.Title, config.Description, config.TextColor, 45)
	local state = config.Default or false

	if config.Flag then ctx.Settings[config.Flag] = state end

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
		BackgroundColor3 = Theme.KnobColor,
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
		if config.Flag then ctx.Settings[config.Flag] = state end
	end

	RegisterThemeRefresh(function()
		knob.BackgroundColor3 = Theme.KnobColor
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
		ConstructKeybind(ctx, rowObj.InlineContainer, subConfig, true)
		return api
	end
	function api.AddColorPicker(_self, subConfig: ColorPickerConfig)
		rowObj.UpdateOffset(36)
		CreateColorPicker(ctx, rowObj.InlineContainer, subConfig, true)
		return api
	end

	if config.Flag then ctx.Registry[config.Flag] = api end

	TrackConnection(ctx, clickArea.MouseButton1Click:Connect(function()
		state = not state
		render()
		if config.Callback then task.spawn(config.Callback, state) end
	end))

	rowObj.Finalize(22)

	return api
end

local function CreateSlider(ctx: any, parent: Instance, config: SliderConfig)
	local increment = config.Increment or 1
	local value = math.clamp(config.Default or config.Min, config.Min, config.Max)

	if config.Flag then ctx.Settings[config.Flag] = value end

	local rowHeight = config.Description and 88 or 64
	local rowObj = BuildRow(ctx, parent, config.Title, config.Description, config.TextColor, 50)
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

	local knob = Create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(fillRatio, 0, 0.5, 0),
		Size = UDim2.new(0, 20, 0, 20),
		BackgroundColor3 = Theme.KnobColor,
		ZIndex = 3,
		Parent = track,
	})
	AddCorner(knob, UDim.new(1, 0))

	RegisterThemeRefresh(function()
		valueLabel.TextColor3 = Theme.TextSecondary
		fill.BackgroundColor3 = Theme.Secondary
		knob.BackgroundColor3 = Theme.KnobColor
	end)

	local dragging = false

	local function setFromRatio(ratio: number)
		ratio = math.clamp(ratio, 0, 1)
		local raw = config.Min + (config.Max - config.Min) * ratio
		value = math.clamp(Round(raw, increment), config.Min, config.Max)
		local newRatio = (value - config.Min) / math.max(config.Max - config.Min, 1e-6)
		fill.Size = UDim2.new(newRatio, 0, 1, 0)
		knob.Position = UDim2.new(newRatio, 0, 0.5, 0)
		valueLabel.Text = tostring(value)
		if config.Flag then ctx.Settings[config.Flag] = value end
	end

	TrackConnection(ctx, trackArea.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			GlobalIsDragging = true
			setFromRatio((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
			if config.Callback then task.spawn(config.Callback, value) end
		end
	end))

	TrackConnection(ctx, UserInputService.InputChanged:Connect(function(input: InputObject)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromRatio((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
			if config.Callback then task.spawn(config.Callback, value) end
		end
	end))

	TrackConnection(ctx, UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			GlobalIsDragging = false
		end
	end))

	local api = {}
	function api.SetValue(_self, newValue: number)
		setFromRatio((newValue - config.Min) / math.max(config.Max - config.Min, 1e-6))
		if config.Callback then task.spawn(config.Callback, value) end
	end
	function api.GetValue(_self) return value end

	if config.Flag then ctx.Registry[config.Flag] = api end
	return api
end

local DefaultNoneLabels = { ["none"]=true, ["nothing"]=true, ["n/a"]=true, ["na"]=true, ["empty"]=true, ["-"]=true }
local function CreateDropdown(ctx: any, parent: Instance, config: DropdownConfig)
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

	local rowObj = BuildRow(ctx, parent, config.Title, config.Description, config.TextColor, 175)
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
		Position = UDim2.new(0, 0, 0, 0),
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
		Position = UDim2.new(0, 0, 0, 0),
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
	local expandTitle = Create("TextLabel", { Name = "Title", Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Font = Theme.FontBold, Text = config.Title, TextColor3 = Theme.TextPrimary, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2002, Parent = expandHeader })
	local expandClose = Create("TextButton", { Name = "Close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = Theme.Background, Font = Theme.FontBold, Text = "×", TextColor3 = Theme.TextSecondary, TextSize = 16, AutoButtonColor = false, ZIndex = 2003, Parent = expandHeader })
	AddCorner(expandClose, Theme.CornerRadiusSmall)

	MakeDraggable(ctx, expandHeader, expandPanel)

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
		local expandGridLayout = Create("UIGridLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			CellPadding = UDim2.new(0, 6, 0, 6),
			CellSize = UDim2.new(1 / expandColumns, -6, 0, 30),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Parent = expandScroller,
		})
		MakeGridResponsive(ctx, expandScroller, expandGridLayout, expandColumns, 30, 100)
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

	TrackConnection(ctx, blocker.MouseButton1Click:Connect(function() setOpen(false) end))
	TrackConnection(ctx, expandBackdrop.MouseButton1Click:Connect(function() setExpandOpen(false) end))
	TrackConnection(ctx, expandClose.MouseButton1Click:Connect(function() setExpandOpen(false) end))
	TrackConnection(ctx, expandButton.MouseButton1Click:Connect(function() setOpen(false) setExpandOpen(not expandOpen) end))
	TrackConnection(ctx, display.MouseButton1Click:Connect(function() setExpandOpen(false) setOpen(not open) end))

	TrackConnection(ctx, UserInputService.InputBegan:Connect(function(input, gpe)
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
			ctx.Settings[config.Flag] = names
		else
			for n, s in pairs(selected) do
				if s then ctx.Settings[config.Flag] = n break end
			end
		end
	end

	local optionButtons = {}

	local function refreshHighlight()
		display.BackgroundColor3 = Theme.Background; display.TextColor3 = Theme.TextPrimary
		list.BackgroundColor3 = Theme.Elevated; expandPanel.BackgroundColor3 = Theme.Elevated

		expandButton.BackgroundColor3 = Theme.Background
		expandButton.TextColor3 = Theme.TextSecondary
		local expandBtnStroke = expandButton:FindFirstChildWhichIsA("UIStroke")
		if expandBtnStroke then expandBtnStroke.Color = Theme.Border end

		if expandTitle then expandTitle.TextColor3 = Theme.TextPrimary end
		expandClose.BackgroundColor3 = Theme.Background
		expandClose.TextColor3 = Theme.TextSecondary
		expandSearch.BackgroundColor3 = Theme.Background
		expandSearch.TextColor3 = Theme.TextPrimary
		expandSearch.PlaceholderColor3 = Theme.TextMuted

		local panelStroke = expandPanel:FindFirstChildWhichIsA("UIStroke")
		if panelStroke then panelStroke.Color = Theme.Border end
		local searchStroke = expandSearch:FindFirstChildWhichIsA("UIStroke")
		if searchStroke then searchStroke.Color = Theme.Border end

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
		TrackConnection(ctx, btn1.MouseButton1Click:Connect(function() selectOption(option) end))

		local btn2 = Create("TextButton", { Name = option, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Elevated, Font = Theme.Font, Text = option, TextColor3 = Theme.TextPrimary, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2002, Parent = expandScroller })
		AddCorner(btn2, Theme.CornerRadiusSmall)
		AddPadding(btn2, 8)
		table.insert(optionButtons[option], btn2)
		TrackConnection(ctx, btn2.MouseButton1Click:Connect(function() selectOption(option) end))
	end

	TrackConnection(ctx, expandSearch:GetPropertyChangedSignal("Text"):Connect(function()
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
		ConstructKeybind(ctx, rowObj.InlineContainer, subConfig, true)
		return api
	end

	if config.Flag then ctx.Registry[config.Flag] = api end
	rowObj.Finalize(26)
	return api
end

local function CreateMultiDropdown(ctx: any, parent: Instance, config: MultiDropdownConfig)
	local api = CreateDropdown(ctx, parent, {
		Title = config.Title, Description = config.Description, TextColor = config.TextColor, Options = config.Options,
		Multi = true, Flag = config.Flag, NoneOptions = config.NoneOptions, Callback = config.Callback, ExpandColumns = config.ExpandColumns,
	} :: DropdownConfig)
	if config.Default then api:SetValue(config.Default) end
	return api
end

local function CreateLabel(ctx: any, parent: Instance, config: LabelConfig)
	local rowObj = BuildRow(ctx, parent, config.Title, config.Description, config.TextColor, 10)
	local row = rowObj.Instance
	row.BackgroundTransparency = 1
	local api = {}
	function api.SetText(_self, text: string) rowObj.SetTitle(text) end
	return api
end

local function CreateInput(ctx: any, parent: Instance, config: InputConfig)
	local rowObj = BuildRow(ctx, parent, config.Title, config.Description, config.TextColor, 74)
	local value = config.Default or 0
	if config.Flag then ctx.Settings[config.Flag] = value end

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
		if config.Flag then ctx.Settings[config.Flag] = value end
		if config.Callback then task.spawn(config.Callback, value) end
	end

	TrackConnection(ctx, box.FocusLost:Connect(function() commit() end))

	local api = {}
	function api.SetValue(_self, newValue: number) box.Text = tostring(newValue); commit() end
	function api.GetValue(_self) return value end

	function api.AddKeybind(_self, subConfig: KeybindConfig)
		rowObj.UpdateOffset(60)
		ConstructKeybind(ctx, rowObj.InlineContainer, subConfig, true)
		return api
	end

	if config.Flag then ctx.Registry[config.Flag] = api end
	rowObj.Finalize(26)
	return api
end

local function CreateStringInput(ctx: any, parent: Instance, config: StringInputConfig)
	local rowObj = BuildRow(ctx, parent, config.Title, config.Description, config.TextColor, 190)
	local value = config.Default or ""
	if config.Flag then ctx.Settings[config.Flag] = value end

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

	local expandBackdrop = Create("TextButton", { Name = "ExpandBackdrop", BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.45, AutoButtonColor = false, Text = "", Position = UDim2.new(0,0,0,0), Size = UDim2.new(1, 0, 1, 0), ZIndex = 2000, Visible = false, Parent = overlay })
	local expandPanel = Create("TextButton", { Name = "ExpandPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 360, 0, 320), BackgroundColor3 = Theme.Elevated, Text = "", AutoButtonColor = false, ZIndex = 2001, Visible = false, Parent = overlay })
	AddCorner(expandPanel, Theme.CornerRadiusCard)
	AddStroke(expandPanel)

	local expandHeader = Create("TextButton", { Name = "Header", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2002, Parent = expandPanel })
	local expandTitle = Create("TextLabel", { Name = "Title", Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Font = Theme.FontBold, Text = config.Title, TextColor3 = Theme.TextPrimary, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2002, Parent = expandHeader })
	local expandClose = Create("TextButton", { Name = "Close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = Theme.Background, Font = Theme.FontBold, Text = "×", TextColor3 = Theme.TextSecondary, TextSize = 16, AutoButtonColor = false, ZIndex = 2003, Parent = expandHeader })
	AddCorner(expandClose, Theme.CornerRadiusSmall)

	MakeDraggable(ctx, expandHeader, expandPanel)

	local expandBox = Create("TextBox", {
		Name = "LargeInput", Position = UDim2.new(0, 14, 0, 44), Size = UDim2.new(1, -28, 1, -58),
		BackgroundColor3 = Theme.Background, Font = Theme.Font, PlaceholderText = config.Placeholder or "Enter text...",
		Text = value, TextColor3 = Theme.TextPrimary, PlaceholderColor3 = Theme.TextMuted, TextSize = 13, ClearTextOnFocus = false, TextWrapped = true, MultiLine = true, TextYAlignment = Enum.TextYAlignment.Top, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2002, Parent = expandPanel,
	})
	AddCorner(expandBox, Theme.CornerRadiusSmall)
	AddStroke(expandBox)
	AddPadding(expandBox, 8)

	local function setExpandOpen(val: boolean) expandBackdrop.Visible = val; expandPanel.Visible = val end
	TrackConnection(ctx, expandButton.MouseButton1Click:Connect(function() setExpandOpen(true) end))
	TrackConnection(ctx, expandClose.MouseButton1Click:Connect(function() setExpandOpen(false) end))
	TrackConnection(ctx, expandBackdrop.MouseButton1Click:Connect(function() setExpandOpen(false) end))

	local isSyncing = false
	TrackConnection(ctx, box:GetPropertyChangedSignal("Text"):Connect(function()
		if isSyncing then return end
		isSyncing = true; value = box.Text; expandBox.Text = value; if config.Flag then ctx.Settings[config.Flag] = value end; isSyncing = false
	end))
	TrackConnection(ctx, expandBox:GetPropertyChangedSignal("Text"):Connect(function()
		if isSyncing then return end
		isSyncing = true; value = expandBox.Text; box.Text = value; if config.Flag then ctx.Settings[config.Flag] = value end; isSyncing = false
	end))

	local function commit()
		value = box.Text
		if config.Flag then ctx.Settings[config.Flag] = value end
		if config.Callback then task.spawn(config.Callback, value) end
	end
	TrackConnection(ctx, box.FocusLost:Connect(commit))
	TrackConnection(ctx, expandBox.FocusLost:Connect(commit))

	RegisterThemeRefresh(function()
		box.BackgroundColor3 = Theme.Background
		box.TextColor3 = Theme.TextPrimary
		box.PlaceholderColor3 = Theme.TextMuted
		local boxStroke = box:FindFirstChildWhichIsA("UIStroke")
		if boxStroke then boxStroke.Color = Theme.Border end

		expandButton.BackgroundColor3 = Theme.Background
		expandButton.TextColor3 = Theme.TextSecondary
		local expandBtnStroke = expandButton:FindFirstChildWhichIsA("UIStroke")
		if expandBtnStroke then expandBtnStroke.Color = Theme.Border end

		expandPanel.BackgroundColor3 = Theme.Elevated
		local panelStroke = expandPanel:FindFirstChildWhichIsA("UIStroke")
		if panelStroke then panelStroke.Color = Theme.Border end

		if expandTitle then expandTitle.TextColor3 = Theme.TextPrimary end
		expandClose.BackgroundColor3 = Theme.Background
		expandClose.TextColor3 = Theme.TextSecondary

		expandBox.BackgroundColor3 = Theme.Background
		expandBox.TextColor3 = Theme.TextPrimary
		expandBox.PlaceholderColor3 = Theme.TextMuted
		local expandBoxStroke = expandBox:FindFirstChildWhichIsA("UIStroke")
		if expandBoxStroke then expandBoxStroke.Color = Theme.Border end
	end)

	local api = {}
	function api.SetValue(_self, newValue: string) box.Text = newValue; commit() end
	function api.GetValue(_self) return value end
	function api.AddKeybind(_self, subConfig: KeybindConfig)
		rowObj.UpdateOffset(60)
		ConstructKeybind(ctx, rowObj.InlineContainer, subConfig, true)
		return api
	end
	if config.Flag then ctx.Registry[config.Flag] = api end
	rowObj.Finalize(26)
	return api
end

CreateColorPicker = function(ctx: any, parent: Instance, config: ColorPickerConfig, isInline: boolean?)
	local rowObj, swatchParent, offsetAmt
	local currentColor = config.Default or Color3.fromRGB(255, 0, 0)
	local h, s, v = currentColor:ToHSV()

	if config.Flag then ctx.Settings[config.Flag] = currentColor end

	if isInline then
		swatchParent = parent
		offsetAmt = 36
	else
		rowObj = BuildRow(ctx, parent, config.Title, config.Description, config.TextColor, 55)
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
	local blocker = Create("TextButton", { Name = "Blocker", BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Position = UDim2.new(0,0,0,0), Size = UDim2.new(1, 0, 1, 0), ZIndex = 1000, Visible = false, Parent = overlay })
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
		if config.Flag then ctx.Settings[config.Flag] = currentColor end
		if config.Callback then task.spawn(config.Callback, currentColor) end
	end

	local draggingSV, draggingHue = false, false
	local function setOpen(val: boolean)
		if val then local pos = swatch.AbsolutePosition; popup.Position = UDim2.fromOffset(pos.X + swatch.AbsoluteSize.X - popup.AbsoluteSize.X, pos.Y + swatch.AbsoluteSize.Y + 4)
		else draggingSV, draggingHue = false, false end
		popup.Visible = val; blocker.Visible = val
	end

	TrackConnection(ctx, swatch.MouseButton1Click:Connect(function() setOpen(not popup.Visible) end))
	TrackConnection(ctx, blocker.MouseButton1Click:Connect(function() setOpen(false) end))

	TrackConnection(ctx, svHitArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSV = true; s = math.clamp((input.Position.X - svSquare.AbsolutePosition.X) / svSquare.AbsoluteSize.X, 0, 1)
			v = 1 - math.clamp((input.Position.Y - svSquare.AbsolutePosition.Y) / svSquare.AbsoluteSize.Y, 0, 1); updateColor()
		end
	end))
	TrackConnection(ctx, hueStrip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingHue = true; h = math.clamp((input.Position.Y - hueStrip.AbsolutePosition.Y) / hueStrip.AbsoluteSize.Y, 0, 1); updateColor()
		end
	end))
	TrackConnection(ctx, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if draggingSV then s = math.clamp((input.Position.X - svSquare.AbsolutePosition.X) / svSquare.AbsoluteSize.X, 0, 1); v = 1 - math.clamp((input.Position.Y - svSquare.AbsolutePosition.Y) / svSquare.AbsoluteSize.Y, 0, 1); updateColor()
		elseif draggingHue then h = math.clamp((input.Position.Y - hueStrip.AbsolutePosition.Y) / hueStrip.AbsoluteSize.Y, 0, 1); updateColor() end
	end))
	TrackConnection(ctx, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSV, draggingHue = false, false end
	end))

	local api = {}
	function api.SetValue(_self, color: Color3) h, s, v = color:ToHSV(); updateColor(); if config.Callback then task.spawn(config.Callback, currentColor) end end
	function api.GetValue(_self) return currentColor end

	if config.Flag then ctx.Registry[config.Flag] = api end
	if rowObj then rowObj.Finalize(26) end
	return api
end

local function CreatePriorityList(ctx: any, parent: Instance, config: PriorityListConfig)
	local rowObj = BuildRow(ctx, parent, config.Title, config.Description, config.TextColor, 140)
	local row = rowObj.Instance
	local items = {}
	for _, v in ipairs(config.Items) do table.insert(items, v) end

	if config.Flag then ctx.Settings[config.Flag] = items end

	local displayBtn = Create("TextButton", {
		Name = "Display", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 140, 0, 26), BackgroundColor3 = Theme.Background, Font = Theme.Font,
		Text = "Edit Priorities", TextColor3 = Theme.TextPrimary, TextSize = 13,
		AutoButtonColor = false, ZIndex = 11, Parent = row,
	})
	AddCorner(displayBtn, Theme.CornerRadiusSmall)
	AddStroke(displayBtn)

	local overlay = GetOverlay(row)

	local expandBackdrop = Create("TextButton", {
		Name = "ExpandBackdrop", BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.45,
		AutoButtonColor = false, Text = "", Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0), ZIndex = 2000, Visible = false, Parent = overlay
	})

	local expandPanel = Create("TextButton", {
		Name = "PriorityPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 360, 0, 380), BackgroundColor3 = Theme.Elevated, Text = "", AutoButtonColor = false,
		ZIndex = 2001, Visible = false, Parent = overlay
	})
	AddCorner(expandPanel, Theme.CornerRadiusCard)
	AddStroke(expandPanel)

	local expandHeader = Create("TextButton", { Name = "Header", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2002, Parent = expandPanel })
	local expandTitle = Create("TextLabel", { Name = "Title", Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Font = Theme.FontBold, Text = config.Title, TextColor3 = Theme.TextPrimary, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2002, Parent = expandHeader })
	local expandClose = Create("TextButton", { Name = "Close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = Theme.Background, Font = Theme.FontBold, Text = "×", TextColor3 = Theme.TextSecondary, TextSize = 16, AutoButtonColor = false, ZIndex = 2003, Parent = expandHeader })
	AddCorner(expandClose, Theme.CornerRadiusSmall)

	MakeDraggable(ctx, expandHeader, expandPanel)

	local scroller = Create("ScrollingFrame", {
		Name = "Scroller", Position = UDim2.new(0, 14, 0, 44), Size = UDim2.new(1, -28, 1, -58),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 2002, Parent = expandPanel,
	})
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = scroller })

	local activeRows = {}

	RegisterThemeRefresh(function()
		displayBtn.BackgroundColor3 = Theme.Background
		displayBtn.TextColor3 = Theme.TextPrimary
		local displayStroke = displayBtn:FindFirstChildWhichIsA("UIStroke")
		if displayStroke then displayStroke.Color = Theme.Border end

		expandPanel.BackgroundColor3 = Theme.Elevated
		local panelStroke = expandPanel:FindFirstChildWhichIsA("UIStroke")
		if panelStroke then panelStroke.Color = Theme.Border end

		expandTitle.TextColor3 = Theme.TextPrimary
		expandClose.BackgroundColor3 = Theme.Background
		expandClose.TextColor3 = Theme.TextSecondary

		for _, rowData in ipairs(activeRows) do
			if not rowData.Frame or not rowData.Frame.Parent then continue end
			rowData.Frame.BackgroundColor3 = Theme.Background
			local rowStroke = rowData.Frame:FindFirstChildWhichIsA("UIStroke")
			if rowStroke then rowStroke.Color = Theme.Border end

			rowData.RankLabel.TextColor3 = Theme.Accent
			rowData.NameLabel.TextColor3 = Theme.TextPrimary

			local btns = rowData.Frame:FindFirstChild("Btns")
			if btns then
				for _, btn in ipairs(btns:GetChildren()) do
					if btn:IsA("TextButton") then
						btn.BackgroundColor3 = Theme.Elevated
						btn.TextColor3 = Theme.TextPrimary
					end
				end
			end
		end
	end)

	local function triggerCallback()
		if config.Flag then ctx.Settings[config.Flag] = items end
		if config.Callback then task.spawn(config.Callback, items) end
	end

	local isDragging = false
	local dragData = nil
	local ghostFrame = nil
	local dragOffset = Vector2.new()

	local function getRowByOrder(order)
		for _, r in ipairs(activeRows) do
			if r.LayoutOrder == order then return r end
		end
		return nil
	end

	local renderItems

	TrackConnection(ctx, UserInputService.InputChanged:Connect(function(input)
		if isDragging and dragData and ghostFrame then
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local mousePos = UserInputService:GetMouseLocation()
				ghostFrame.Position = UDim2.fromOffset(mousePos.X - dragOffset.X, mousePos.Y - dragOffset.Y)

				if #items == 0 or not scroller.Parent then return end

				local localY = input.Position.Y - scroller.AbsolutePosition.Y + scroller.CanvasPosition.Y
				local targetOrder = math.clamp(math.floor(localY / 38) + 1, 1, #items)

				if targetOrder ~= dragData.LayoutOrder then
					local targetRow = getRowByOrder(targetOrder)
					if targetRow then
						local oldOrder = dragData.LayoutOrder

						targetRow.LayoutOrder = oldOrder
						targetRow.Frame.LayoutOrder = oldOrder
						targetRow.RankLabel.Text = "#" .. oldOrder

						dragData.LayoutOrder = targetOrder
						dragData.Frame.LayoutOrder = targetOrder
						dragData.RankLabel.Text = "#" .. targetOrder
					end
				end
			end
		end
	end))

	TrackConnection(ctx, UserInputService.InputEnded:Connect(function(input)
		if isDragging and dragData then
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDragging = false
				GlobalIsDragging = false

				if ghostFrame then 
					ghostFrame:Destroy() 
					ghostFrame = nil 
				end

				local newItems = {}
				local changed = false
				for i = 1, #items do
					local r = getRowByOrder(i)
					if r then 
						table.insert(newItems, r.Name) 
						if r.Name ~= items[i] then changed = true end
					else
						table.insert(newItems, items[i])
					end
				end

				items = newItems
				dragData = nil

				if changed then triggerCallback() end
				renderItems()
			end
		end
	end))

	renderItems = function()
		for _, child in ipairs(scroller:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		table.clear(activeRows)

		for i, itemName in ipairs(items) do
			local itemRow = Create("Frame", { Name = "Item_" .. i, Size = UDim2.new(1, -6, 0, 32), BackgroundColor3 = Theme.Background, ZIndex = 2003, Parent = scroller, LayoutOrder = i })
			AddCorner(itemRow, Theme.CornerRadiusSmall)
			AddStroke(itemRow, Theme.Border, 1)

			local rankLabel = Create("TextLabel", { Name = "Rank", Size = UDim2.new(0, 32, 1, 0), BackgroundTransparency = 1, Font = Theme.FontBold, Text = "#" .. i, TextColor3 = Theme.Accent, TextSize = 14, ZIndex = 2004, Parent = itemRow })
			local nameLabel = Create("TextLabel", { Name = "Name", Position = UDim2.new(0, 36, 0, 0), Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1, Font = Theme.Font, Text = itemName, TextColor3 = Theme.TextPrimary, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2004, Parent = itemRow })

			local rowInfo = {
				Frame = itemRow,
				RankLabel = rankLabel,
				NameLabel = nameLabel,
				Name = itemName,
				LayoutOrder = i
			}
			table.insert(activeRows, rowInfo)

			local btnContainer = Create("Frame", { Name = "Btns", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.new(0, 56, 1, -8), BackgroundTransparency = 1, ZIndex = 2004, Parent = itemRow })
			Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Right, Parent = btnContainer })

			if i > 1 then
				local upBtn = Create("TextButton", { Name = "Up", Size = UDim2.new(0, 26, 0, 24), BackgroundColor3 = Theme.Elevated, Font = Theme.FontBold, Text = "▲", TextColor3 = Theme.TextPrimary, TextSize = 10, AutoButtonColor = false, ZIndex = 2005, Parent = btnContainer })
				AddCorner(upBtn, Theme.CornerRadiusSmall)
				TrackConnection(ctx, upBtn.MouseButton1Click:Connect(function() items[i], items[i-1] = items[i-1], items[i]; renderItems(); triggerCallback() end))
			end

			if i < #items then
				local downBtn = Create("TextButton", { Name = "Down", Size = UDim2.new(0, 26, 0, 24), BackgroundColor3 = Theme.Elevated, Font = Theme.FontBold, Text = "▼", TextColor3 = Theme.TextPrimary, TextSize = 10, AutoButtonColor = false, ZIndex = 2005, Parent = btnContainer })
				AddCorner(downBtn, Theme.CornerRadiusSmall)
				TrackConnection(ctx, downBtn.MouseButton1Click:Connect(function() items[i], items[i+1] = items[i+1], items[i]; renderItems(); triggerCallback() end))
			end

			local dragArea = Create("TextButton", { Name = "DragArea", Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 2006, Parent = itemRow })

			TrackConnection(ctx, dragArea.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					isDragging = true
					GlobalIsDragging = true
					dragData = rowInfo

					local mousePos = UserInputService:GetMouseLocation()

					dragOffset = Vector2.new(itemRow.AbsoluteSize.X / 2, itemRow.AbsoluteSize.Y / 2)

					ghostFrame = itemRow:Clone()
					ghostFrame.Name = "GhostRow"
					ghostFrame.Parent = overlay
					ghostFrame.Size = UDim2.new(0, itemRow.AbsoluteSize.X, 0, itemRow.AbsoluteSize.Y)
					ghostFrame.Position = UDim2.fromOffset(mousePos.X - dragOffset.X, mousePos.Y - dragOffset.Y)

					local function elevateZIndex(inst)
						if inst:IsA("GuiObject") then inst.ZIndex = inst.ZIndex + 3000 end
						for _, c in ipairs(inst:GetChildren()) do elevateZIndex(c) end
					end
					elevateZIndex(ghostFrame)

					ghostFrame.Active = false

					itemRow.BackgroundTransparency = 0.6
					rankLabel.TextTransparency = 0.6
					nameLabel.TextTransparency = 0.6
					for _, c in ipairs(btnContainer:GetChildren()) do
						if c:IsA("TextButton") then c.BackgroundTransparency = 0.6 c.TextTransparency = 0.6 end
					end
				end
			end))
		end
	end

	local function setExpandOpen(val: boolean)
		expandBackdrop.Visible = val; expandPanel.Visible = val
		if val then renderItems() end
	end

	TrackConnection(ctx, displayBtn.MouseButton1Click:Connect(function() setExpandOpen(true) end))
	TrackConnection(ctx, expandClose.MouseButton1Click:Connect(function() setExpandOpen(false) end))
	TrackConnection(ctx, expandBackdrop.MouseButton1Click:Connect(function() setExpandOpen(false) end))

	local api = {}
	function api.SetValue(_self, newItems: { string })
		if type(newItems) == "table" then
			items = {}; for _, v in ipairs(newItems) do table.insert(items, v) end
			if expandPanel.Visible then renderItems() end
			triggerCallback()
		end
	end
	function api.GetValue(_self) return items end

	if config.Flag then ctx.Registry[config.Flag] = api end
	rowObj.Finalize(26)
	return api
end

-- ---------- Section ----------

local Section = {}
Section.__index = Section

function Section.new(ctx: any, parent: Instance, title: string, textColor: Color3?, columns: number?, rowHeight: number?)
	local self = setmetatable({}, Section)
	self._ctx = ctx

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
		local gridLayout = Create("UIGridLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			CellPadding = UDim2.new(0, 6, 0, 6),
			CellSize = UDim2.new(1 / numColumns, -6, 0, rowHeight or 44),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Parent = list,
		})
		MakeGridResponsive(ctx, list, gridLayout, numColumns, rowHeight or 44)
	else
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = list })
	end

	RegisterThemeRefresh(function() header.TextColor3 = textColor or Theme.TextMuted end)

	table.insert(ctx.SectionsData, { Container = container, List = list, TitleLower = title:lower() })

	self._container = container
	self._list = list
	return self
end

function Section:CreateExpandableGroup(title: string, defaultExpanded: boolean?, columns: number?, rowHeight: number?)
	local ctx = self._ctx

	local container = Create("Frame", {
		Name = "Expandable_" .. title,
		Size = UDim2.new(1, 0, 0, 36),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Elevated,
		BackgroundTransparency = Theme.ElevatedTransparency,
		Parent = self._list,
		ClipsDescendants = true,
	})
	AddCorner(container, Theme.CornerRadiusSmall)
	local containerStroke = AddStroke(container, Theme.Border, 1)

	local headerBtn = Create("TextButton", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Font = Theme.FontSemibold,
		Text = "",
		Parent = container,
	})

	local titleLabel = Create("TextLabel", {
		Name = "Title",
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -44, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.FontSemibold,
		Text = title,
		TextColor3 = Theme.TextPrimary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = headerBtn,
	})

	local arrow = Create("TextLabel", {
		Name = "Arrow",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 20, 0, 20),
		BackgroundTransparency = 1,
		Font = Theme.FontBold,
		Text = defaultExpanded and "-" or "+",
		TextColor3 = Theme.TextSecondary,
		TextSize = 16,
		Parent = headerBtn,
	})

	local contentLayout = Create("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 0, 0, 36),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = defaultExpanded or false,
		Parent = container,
	})
	AddPadding(contentLayout, 10)

	local numColumns = math.max(1, math.floor(columns or 1))
	if numColumns > 1 then
		local gridLayout = Create("UIGridLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			CellPadding = UDim2.new(0, 6, 0, 6),
			CellSize = UDim2.new(1 / numColumns, -6, 0, rowHeight or 42),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Parent = contentLayout,
		})
		MakeGridResponsive(ctx, contentLayout, gridLayout, numColumns, rowHeight or 42)
	else
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = contentLayout })
	end

	local expanded = defaultExpanded or false
	TrackConnection(ctx, headerBtn.MouseButton1Click:Connect(function()
		expanded = not expanded
		contentLayout.Visible = expanded
		arrow.Text = expanded and "-" or "+"
	end))

	RegisterThemeRefresh(function()
		container.BackgroundColor3 = Theme.Elevated
		containerStroke.Color = Theme.Border
		titleLabel.TextColor3 = Theme.TextPrimary
		arrow.TextColor3 = Theme.TextSecondary
	end)

	table.insert(ctx.ExpandableGroups, {
		Container = container,
		Content = contentLayout,
		Arrow = arrow,
		TitleLower = title:lower(),
		GetExpanded = function() return expanded end,
	})

	local expandableObj = setmetatable({}, Section)
	expandableObj._container = container
	expandableObj._list = contentLayout
	expandableObj._ctx = ctx
	return expandableObj
end

function Section:CreateButton(config: ButtonConfig) return CreateButton(self._ctx, self._list, config) end
function Section:CreateToggle(config: ToggleConfig) return CreateToggle(self._ctx, self._list, config) end
function Section:CreateSlider(config: SliderConfig) return CreateSlider(self._ctx, self._list, config) end
function Section:CreateDropdown(config: DropdownConfig) return CreateDropdown(self._ctx, self._list, config) end
function Section:CreateMultiDropdown(config: MultiDropdownConfig) return CreateMultiDropdown(self._ctx, self._list, config) end
function Section:CreateLabel(config: LabelConfig) return CreateLabel(self._ctx, self._list, config) end
function Section:CreateInput(config: InputConfig) return CreateInput(self._ctx, self._list, config) end
function Section:CreateStringInput(config: StringInputConfig) return CreateStringInput(self._ctx, self._list, config) end
function Section:CreateColorPicker(config: ColorPickerConfig) return CreateColorPicker(self._ctx, self._list, config) end
function Section:CreateKeybind(config: KeybindConfig) return CreateKeybind(self._ctx, self._list, config) end
function Section:CreatePriorityList(config: PriorityListConfig) return CreatePriorityList(self._ctx, self._list, config) end

-- ---------- Tab ----------

local Tab = {}
Tab.__index = Tab

function Tab.new(ctx: any, pageContainer: ScrollingFrame, tabButton: TextButton)
	local self = setmetatable({}, Tab)
	self._ctx = ctx
	self._page = pageContainer
	self._button = tabButton
	return self
end

function Tab:CreateSection(title: string, textColor: Color3?, columns: number?, rowHeight: number?) 
	local parentObj = self._page
	if self._columns then
		parentObj = self._columns[self._nextColumn]
		self._nextColumn = self._nextColumn + 1
		if self._nextColumn > #self._columns then self._nextColumn = 1 end
	end
	return Section.new(self._ctx, parentObj, title, textColor, columns, rowHeight) 
end

function Tab:CreateButton(config: ButtonConfig) return CreateButton(self._ctx, self._page, config) end
function Tab:CreateToggle(config: ToggleConfig) return CreateToggle(self._ctx, self._page, config) end
function Tab:CreateSlider(config: SliderConfig) return CreateSlider(self._ctx, self._page, config) end
function Tab:CreateDropdown(config: DropdownConfig) return CreateDropdown(self._ctx, self._page, config) end
function Tab:CreateMultiDropdown(config: MultiDropdownConfig) return CreateMultiDropdown(self._ctx, self._page, config) end
function Tab:CreateLabel(config: LabelConfig) return CreateLabel(self._ctx, self._page, config) end
function Tab:CreateInput(config: InputConfig) return CreateInput(self._ctx, self._page, config) end
function Tab:CreateStringInput(config: StringInputConfig) return CreateStringInput(self._ctx, self._page, config) end
function Tab:CreateColorPicker(config: ColorPickerConfig) return CreateColorPicker(self._ctx, self._page, config) end
function Tab:CreateKeybind(config: KeybindConfig) return CreateKeybind(self._ctx, self._page, config) end
function Tab:CreatePriorityList(config: PriorityListConfig) return CreatePriorityList(self._ctx, self._page, config) end

-- ---------- Window ----------

local Window = {}
Window.__index = Window

function Window.new(config: WindowConfig)
	local self = setmetatable({}, Window)
	local ctx = NewContext()
	self._ctx = ctx

	local screenGui = Create("ScreenGui", {
		Name = "UILibrary",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
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
		Visible = config.StartHidden == false,
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

	TrackConnection(ctx, minimizeButton.MouseEnter:Connect(function() Tween(minimizeButton, { BackgroundTransparency = 0 }) end))
	TrackConnection(ctx, minimizeButton.MouseLeave:Connect(function() Tween(minimizeButton, { BackgroundTransparency = 0.3 }) end))
	TrackConnection(ctx, closeButton.MouseEnter:Connect(function() Tween(closeButton, { BackgroundTransparency = 0 }) end))
	TrackConnection(ctx, closeButton.MouseLeave:Connect(function() Tween(closeButton, { BackgroundTransparency = 0.3 }) end))

	MakeDraggable(ctx, topBar, main)

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

	TrackConnection(ctx, searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query = searchBox.Text:lower()
		for _, data in ipairs(ctx.SearchableRows) do
			if query == "" then
				data.Row.Visible = true
			else
				data.Row.Visible = string.find(data.SearchText, query, 1, true) ~= nil
			end
		end

		for _, sec in ipairs(ctx.SectionsData) do
			if query == "" then
				sec.Container.Visible = true
			else
				local hasVisible = false
				for _, data in ipairs(ctx.SearchableRows) do
					if data.Row.Visible and data.Row:IsDescendantOf(sec.List) then
						hasVisible = true
						break
					end
				end
				local titleMatch = string.find(sec.TitleLower, query, 1, true) ~= nil
				sec.Container.Visible = hasVisible or titleMatch
			end
		end

		for _, group in ipairs(ctx.ExpandableGroups) do
			if query == "" then
				group.Container.Visible = true
				local expanded = group.GetExpanded()
				group.Content.Visible = expanded
				if group.Arrow then group.Arrow.Text = expanded and "-" or "+" end
			else
				local hasRowMatch = false
				for _, data in ipairs(ctx.SearchableRows) do
					if data.Row.Visible and data.Row:IsDescendantOf(group.Content) then
						hasRowMatch = true
						break
					end
				end
				local titleMatch = string.find(group.TitleLower, query, 1, true) ~= nil

				group.Container.Visible = hasRowMatch or titleMatch

				local shouldExpand = hasRowMatch or group.GetExpanded()
				group.Content.Visible = shouldExpand
				if group.Arrow then group.Arrow.Text = shouldExpand and "-" or "+" end
			end
		end

		local firstMatchTab = nil
		local activeHasMatch = (query == "")
		for _, tab in ipairs(self._tabs) do
			local hasMatch = query == ""
			if query ~= "" then
				for _, data in ipairs(ctx.SearchableRows) do
					if data.Row.Visible and data.Row:IsDescendantOf(tab._page) then
						hasMatch = true
						break
					end
				end
			end

			if tab._badge then
				tab._badge.Visible = query ~= "" and hasMatch and tab._button ~= self._activeTabButton
			end
			if query ~= "" and hasMatch and not firstMatchTab then
				firstMatchTab = tab
			end
			if tab._button == self._activeTabButton and hasMatch then
				activeHasMatch = true
			end
		end

		if query ~= "" and not activeHasMatch and firstMatchTab then
			firstMatchTab._selectTab()
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
				Tween(tab._button, {
					BackgroundColor3 = Theme.Background,
					BackgroundTransparency = Theme.UseGradient and 1 or 0,
					TextColor3 = Theme.TextPrimary
				})
				if stroke then Tween(stroke, { Color = Theme.Secondary, Transparency = 0 }) end
			else
				Tween(tab._button, {
					BackgroundColor3 = Theme.Background,
					BackgroundTransparency = 0,
					TextColor3 = Theme.TextSecondary
				})
				if stroke then Tween(stroke, { Color = Theme.Border, Transparency = 0 }) end
			end
		end
	end)

	TrackConnection(ctx, minimizeButton.MouseButton1Click:Connect(function() self:Minimize() end))
	TrackConnection(ctx, closeButton.MouseButton1Click:Connect(function() if self._onClose then task.spawn(self._onClose) end self:Destroy() end))

	local resizing, resizeStart, startSize = false, Vector3.new(), UDim2.new()
	TrackConnection(ctx, resizeHandle.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = true; resizeStart = input.Position; startSize = main.Size end end))
	TrackConnection(ctx, UserInputService.InputChanged:Connect(function(input)
		if resizing then
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				main.Size = UDim2.new(0, math.clamp(startSize.X.Offset + (input.Position.X - resizeStart.X), self._minSize.X, self._maxSize.X), 0, math.clamp(startSize.Y.Offset + (input.Position.Y - resizeStart.Y), self._minSize.Y, self._maxSize.Y))
			end
		end
	end))
	TrackConnection(ctx, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = false end end))

	TrackConnection(ctx, UserInputService.InputBegan:Connect(function(input, gpe)
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

	local searchBadge = Create("Frame", {
		Name = "SearchBadge",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 6, 0, 6),
		BackgroundColor3 = Theme.Accent,
		Visible = false,
		ZIndex = 5,
		Parent = button,
	})
	AddCorner(searchBadge, UDim.new(1, 0))
	RegisterThemeRefresh(function() searchBadge.BackgroundColor3 = Theme.Accent end)

	local page = Create("ScrollingFrame", { Name = "Page_" .. config.Name, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = self._pages })
	AddPadding(page, 12)

	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = page })

	local tab = Tab.new(self._ctx, page, button)
	table.insert(self._tabs, tab)

	local pageColumns = math.max(1, math.floor(config.Columns or 1))
	if pageColumns > 1 then 
		local columnsContainer = Create("Frame", { 
			Name = "ColumnsContainer", 
			Size = UDim2.new(1, -2, 0, 0), 
			AutomaticSize = Enum.AutomaticSize.Y, 
			BackgroundTransparency = 1, 
			Parent = page 
		})
		local columnsListLayout = Create("UIListLayout", { 
			FillDirection = Enum.FillDirection.Horizontal, 
			SortOrder = Enum.SortOrder.LayoutOrder, 
			Padding = UDim.new(0, 10), 
			Parent = columnsContainer 
		})

		tab._columns = {}
		tab._nextColumn = 1
		for i = 1, pageColumns do
			local col = Create("Frame", { 
				Name = "Column_" .. i, 
				Size = UDim2.new(1 / pageColumns, -10 * (pageColumns - 1) / pageColumns, 0, 0), 
				AutomaticSize = Enum.AutomaticSize.Y, 
				BackgroundTransparency = 1, 
				Parent = columnsContainer 
			})
			Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = col })
			table.insert(tab._columns, col)
		end

		MakePageColumnsResponsive(self._ctx, columnsContainer, columnsListLayout, tab._columns, pageColumns)
	end

	local function refreshTabTheme()
		local isActive = self._activeTabButton == button
		button.BackgroundColor3 = Theme.Background
		button.BackgroundTransparency = isActive and (Theme.UseGradient and 1 or 0) or 0
		button.TextColor3 = isActive and Theme.TextPrimary or Theme.TextSecondary
		stroke.Color = isActive and Theme.Secondary or Theme.Border
		stroke.Transparency = 0
	end
	RegisterThemeRefresh(refreshTabTheme)

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

	tab._badge = searchBadge
	tab._selectTab = selectTab

	TrackConnection(self._ctx, button.MouseButton1Click:Connect(selectTab))
	if not self._firstTab then self._firstTab = page; selectTab() end
	return tab
end

function Window:CreateThemeTab(config: TabConfig?)
	local tab = self:CreateTab(config or { Name = "Theme Settings" })

	local mainSection = tab:CreateSection("Configuration")

	local menuSection = mainSection:CreateExpandableGroup("Menu Settings", true)
	menuSection:CreateKeybind({ 
		Title = "Menu Toggle Key", 
		Description = "Key used to hide/show the menu.", 
		Default = self._toggleKey or Enum.KeyCode.RightControl, 
		Flag = "Theme_ToggleKey", 
		ChangedCallback = function(key) self:SetToggleKey(key) end 
	})

	local bgSection = mainSection:CreateExpandableGroup("Background & Gradient", false)
	bgSection:CreateToggle({ Title = "Use Gradient Background", Description = "Enable a 2-color gradient transition", Default = Theme.UseGradient, Flag = "Theme_UseGradient", Callback = function(state) UILibrary:SetTheme({ UseGradient = state }) end })
	bgSection:CreateColorPicker({ Title = "Solid Background", Description = "Main background color (when gradient is off)", Default = Theme.Background, Flag = "Theme_Background", Callback = function(color) local h, s, v = color:ToHSV() UILibrary:SetTheme({ Background = color, Elevated = Color3.fromHSV(h, s, math.clamp(v + 0.03, 0, 1)) }) end })
	bgSection:CreateColorPicker({ Title = "Gradient Color 1", Description = "Top-left transition color", Default = Theme.GradientColor1, Flag = "Theme_GradientColor1", Callback = function(color) UILibrary:SetTheme({ GradientColor1 = color }) end })
	bgSection:CreateColorPicker({ Title = "Gradient Color 2", Description = "Bottom-right transition color", Default = Theme.GradientColor2, Flag = "Theme_GradientColor2", Callback = function(color) UILibrary:SetTheme({ GradientColor2 = color }) end })

	local colorSection = mainSection:CreateExpandableGroup("Accent Colors", false)
	colorSection:CreateColorPicker({ Title = "Secondary Color", Description = "Buttons, sliders, selected states", Default = Theme.Secondary, Flag = "Theme_Secondary", Callback = function(color) local h, s, v = color:ToHSV() UILibrary:SetTheme({ Secondary = color, Accent = Color3.fromHSV(h, s, math.clamp(v + 0.15, 0, 1)) }) end })
	colorSection:CreateColorPicker({ Title = "Knob Color", Description = "Color of the slider and toggle circles", Default = Theme.KnobColor, Flag = "Theme_KnobColor", Callback = function(color) UILibrary:SetTheme({ KnobColor = color }) end })
	colorSection:CreateColorPicker({ Title = "Button Text Color", Description = "Color of text inside clickable action buttons", Default = Theme.ButtonTextColor, Flag = "Theme_ButtonTextColor", Callback = function(color) UILibrary:SetTheme({ ButtonTextColor = color }) end })
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
	local self_ = self
	local tab = self:CreateTab(config or { Name = "Integrations" })

	local mainSection = tab:CreateSection("External Services")

	local webhookSection = mainSection:CreateExpandableGroup("Discord Webhooks", true)

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
			local url = self_._ctx.Settings["Theme_DiscordWebhook"]

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
	local ctx = self._ctx

	for _, conn in ipairs(ctx.ActiveConnections) do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(ctx.ActiveConnections)
	table.clear(ctx.Registry)
	table.clear(ctx.SearchableRows)
	table.clear(ctx.SectionsData)
	table.clear(ctx.BoundKeys)

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
	local dragStart = Vector3.new()
	local startPos = UDim2.new()
	local dragDistance = 0

	TrackConnection(self._ctx, bubble.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then return end
			dragging = true
			dragDistance = 0
			dragStart = input.Position
			startPos = bubble.Position
		end
	end))

	TrackConnection(self._ctx, UserInputService.InputChanged:Connect(function(input)
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

	TrackConnection(self._ctx, UserInputService.InputEnded:Connect(function(input)
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

function Window:GetSettings(): { [string]: any }
	local safeSettings = {}
	for key, val in pairs(self._ctx._RawSettings) do
		if typeof(val) == "Color3" then
			safeSettings[key] = { type = "Color3", r = val.R, g = val.G, b = val.B }
		else
			safeSettings[key] = val
		end
	end
	return safeSettings
end

function Window:LoadSettings(savedData: { [string]: any })
	if type(savedData) ~= "table" then return end
	local ctx = self._ctx

	ctx.IsLoading = true

	local function processFlag(flag, value)
		local parsedValue = value
		if type(value) == "table" and value.type == "Color3" then 
			parsedValue = Color3.new(value.r, value.g, value.b) 
		end

		ctx.Settings[flag] = parsedValue
		local componentApi = ctx.Registry[flag]

		if componentApi and componentApi.SetValue then 
			pcall(function() componentApi:SetValue(parsedValue) end) 
		end
	end

	for flag, value in pairs(savedData) do
		if type(value) == "table" and value.type == "Color3" then
			processFlag(flag, value)
		end
	end

	for flag, value in pairs(savedData) do
		if string.find(flag, "Theme_") and not (type(value) == "table" and value.type == "Color3") then
			processFlag(flag, value)
		end
	end

	for flag, value in pairs(savedData) do
		if not string.find(flag, "Theme_") then
			processFlag(flag, value)
		end
	end

	ctx.IsLoading = false
end

function Window:OnChange(callback: (settings: { [string]: any }) -> ())
	self._ctx.OnChange = callback
end

function Window:StartUp(savedData: { [string]: any }?, startMinimized: boolean?)
	if savedData then
		self:LoadSettings(savedData)
	end

	if startMinimized then
		self:Minimize()
	else
		self._minimized = false
		self._main.Visible = true
		if self._bubble then self._bubble.Visible = false end
	end
end

function UILibrary:CreateWindow(config: WindowConfig?) return Window.new(config or {}) end

function UILibrary:SetTheme(overrides: { [string]: any })
	for key, value in pairs(overrides) do local t = Theme :: any t[key] = value end
	for _, refresh in ipairs(ThemeRefreshCallbacks) do refresh() end
end

return UILibrary