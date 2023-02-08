local Services = setmetatable({}, {
	__index = function(self, Index)
		local Value = game.GetService(game, Index)

		rawset(self, Index, Value)

		return Value
	end
})
Services.UIParent = Services.Players.LocalPlayer:WaitForChild("PlayerGui") -- Services.CoreGui  


local Library = {
	Util = {};
	Theme = {};
	Objects = {};
	ObjectCache = {};
	Tabs = { Skeletons = {}; };
	Tweens = {};
}

Library.__index = Library
Library.Tabs.__index = Library.Tabs

--// Create Util Functions
function Library.Util:DeepScanTable(Input, Callback, Stack)
	Stack = Stack or {}

	for Index, Value in next, Input do
		if (not Stack[Value]) then
			Stack[Value] = true

			Callback(Index, Value)

			if type(Value) == "table" then
				self:DeepScanTable(Value, Callback, Stack)
			end
		end
	end
end

function Library.Util:Round(Number, DecimalPlaces)
	return tonumber(string.format("%." .. DecimalPlaces .."f", Number))
end

function Library.Util:OffsetUDim2(V2, OffsetObject)
	local OffsetPosition = OffsetObject.AbsolutePosition
	return UDim2.new(
		0, math.round(V2.X - OffsetPosition.X),
		0, math.round(V2.Y - OffsetPosition.Y)-- + self.Parent.GuiInset.Y
	)
end

function Library.Util:ConcatTable(Input, Seperator, Invert)
	local Output, Count = "", 0

	local Start = (Invert and #Input) or 1
	local Limit = (Invert and 1) or #Input
	local Step  = (Invert and -1) or 1

	for Index = Start, Limit, Step do
		local Value = Input[Index]
		if Value ~= nil then
			Count += 1
			Output = Output .. tostring(Value) .. Seperator
		end
	end

	return Output:sub(1, #Output - #Seperator), Count
end

function Library.Util:MapValue(Value, MinA, MaxA, MinB, MaxB, DecimalPlaces)
	return self:Round((1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB, DecimalPlaces)
end

function Library.Util:GetIndexOfValue(Input, Value)
	for Index, _Value in pairs(Input) do
		if Value == _Value then
			return Index
		end
	end

	return 0
end

function Library.Util:Create(ClassName, Properties)
	local _Instance = Instance.new(ClassName)

	for Property, Value in next, Properties do
		if Property ~= "Parent" then
			_Instance[Property] = Value
		end
	end

	_Instance.Parent = Properties["Parent"]

	return _Instance
end

function Library.Util:Tween(Tweens, Play)
	local TweenTable = {}

	for Object, TweenData in next, Tweens do
		table.insert(TweenTable, Services.TweenService:Create(Object, TweenData[1], TweenData[2]))
	end

	if Play then
		for _, Tween in next, TweenTable do
			Tween:Play()
		end
	end

	return TweenTable
end

function Library.Util:GetMousePosition()
	return (Services.UserInputService:GetMouseLocation() + self.Parent.GuiInset)
end

function Library.Util:GetXInBounds(AbsolutePosition, SliderBounds)
	return math.clamp( (AbsolutePosition.X - SliderBounds.AbsolutePosition.X) , 0, SliderBounds.AbsoluteSize.X)
end

function Library.Util:GetValueFromX(X, SliderBounds, Data)
	return self:MapValue(X, 0, SliderBounds.AbsoluteSize.X, Data.Min, Data.Max, Data.DecimalPlaces)
end

function Library.Util:XToScale(X, SliderBounds)
	return X / SliderBounds.AbsoluteSize.X
end

function Library.Util:SliderUpdateWrapper(SliderBounds, Label, Fill, Data, Object)
	local PreviousValue = 0/0
	return function()
		local MousePosition = self:GetMousePosition()
		local XInBounds = self:GetXInBounds(MousePosition, SliderBounds)

		local Value = self:Round(self:GetValueFromX(XInBounds, SliderBounds, Data), Data.DecimalPlaces)

		if PreviousValue ~= Value then
			PreviousValue = Value
			Object.Callback("Slider", Data.Flag, Value)
			Label.Text = Data.Format:format(Value)
		end
		Fill.Size = UDim2.new(self:XToScale(XInBounds, SliderBounds), 0, 1, -2)
	end
end

function Library.Util:CreateInformationFrame(Object, Skeleton)
	local InformationFrame, Label
	if self.Parent.ObjectCache[Object] then
		InformationFrame = self.Parent.ObjectCache[Object]
		Label = InformationFrame.Label
	else
		InformationFrame = self:Create("Frame", {
			BackgroundColor3 = self.Parent.Theme.Background_2;
			Position = UDim2.new(0, 93, 0, 335);
			Size = UDim2.new(0, 250, 0, 0);
			ZIndex = 19;
			Name = "InformationFrame";
			BackgroundTransparency = 1;
		})

		local UIStroke = self:Create("UIStroke", {
			Color = self.Parent.Theme.Accent;
			Parent = InformationFrame;
			Transparency = 1;
		})

		local UICorner = self:Create("UICorner", {
			CornerRadius = UDim.new(0, 4);
			Parent = InformationFrame;
		})

		Label = self:Create("TextLabel", {
			FontFace = self.Parent.Theme.Font_Regular;
			RichText = true;
			TextColor3 = Color3.new(1, 1, 1);
			TextSize = 16;
			TextWrapped = true;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Top;
			BackgroundColor3 = Color3.new(1, 1, 1);
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 5, 0, 5);
			Size = UDim2.new(1, -10, 1, -10);
			ZIndex = 20;
			Name = "Label";
			Parent = InformationFrame;
			TextTransparency = 1;
		})
	end

	InformationFrame.Parent = Skeleton
	self.Parent.ObjectCache[Object] = InformationFrame

	return InformationFrame, Label
end

function Library.Util:CreateDropdownHolder(Object, Skeleton)
	local Items, ItemHolder
	if self.Parent.ObjectCache[Object] then
		Items = self.Parent.ObjectCache[Object]
		ItemHolder = Items.ItemHolder
	else
		Items = self:Create("Frame", {
			BackgroundColor3 = self.Parent.Theme.Background_2;
			Position = UDim2.new(0, 0, 0, 0);
			Size = UDim2.new(0, 210, 0, 0);
			ZIndex = 5;
			BorderSizePixel = 0;
			Name = "Items";
		})

		local UIStroke = self:Create("UIStroke", {
			Color = self.Parent.Theme.Accent;
			Parent = Items;
			Transparency = 1;
		})

		local UICorner = self:Create("UICorner", {
			CornerRadius = UDim.new(0, 4);
			Parent = Items;
		})

		ItemHolder = self:Create("ScrollingFrame", {
			BottomImage = "";
			CanvasSize = UDim2.new(1, 0, 0, 0);
			ScrollBarImageColor3 = self.Parent.Theme.Accent;
			ScrollBarThickness = 3;
			TopImage = "";
			VerticalScrollBarInset = Enum.ScrollBarInset.Always;
			Active = true;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 6;
			Name = "Holder";
			Parent = Items;
		})

		local UIListLayout = self:Create("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = ItemHolder;
			Padding = UDim.new(0,5);
		})

		local UIPadding = self:Create("UIPadding", {
			PaddingTop = UDim.new(0, 5);
			Parent = ItemHolder;
		})

		Object:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			local SkeletonPosition = Skeleton.AbsolutePosition
			local ObjectPosition = Object.AbsolutePosition
			Items.Position = UDim2.new(
				0, math.round(ObjectPosition.X - SkeletonPosition.X),
				0, math.round(ObjectPosition.Y - SkeletonPosition.Y) + self.Parent.GuiInset.Y
			)
		end)
	end

	Items.Parent = Skeleton
	self.Parent.ObjectCache[Object] = Items

	return Items, ItemHolder
end

function Library.Util:LoadItemList(Dropdown, ItemList, Callback, IsSelectable)
	local function PlayState(Tweens, State)
		for _, Tween in next, Tweens[State] do
			Tween:Play()
		end
	end

	local ButtonList = {}

	for Index, Value in ipairs(ItemList) do
		local IsSelected = (not IsSelectable and true) or (false)

		local Button = self:Create("TextButton", {
			FontFace = self.Parent.Theme.Font_Regular;
			Text = "";
			TextColor3 = Color3.new(0, 0, 0);
			TextSize = 14;
			AutoButtonColor = false;
			BackgroundColor3 = self.Parent.Theme.Background_2;
			Position = UDim2.new(0.112, 0, 0.02, 0);
			Size = UDim2.new(1, -10, 0, 20);
			ZIndex = 20;
			Name = "Button";
			Parent = Dropdown;
		})

		local UICorner = self:Create("UICorner", {
			CornerRadius = UDim.new(0, 4);
			Parent = Button;
		})

		local Label = self:Create("TextLabel", {
			FontFace = self.Parent.Theme.Font_Regular;
			RichText = true;
			Text = Value;
			TextColor3 = Color3.new(1, 1, 1);
			TextSize = 16;
			TextStrokeColor3 = self.Parent.Theme.Background_2;
			TextWrapped = true;
			TextXAlignment = Enum.TextXAlignment.Left;
			AnchorPoint = Vector2.new(0, 0.5);
			BackgroundColor3 = Color3.new(1, 1, 1);
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 5, 0.5, 0);
			Size = UDim2.new(1, -5, 1, 0);
			ZIndex = 24;
			Name = "Label";
			Parent = Button;
		})

		local UIStroke = self:Create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
			Color = self.Parent.Theme.Accent;
			Parent = Button;
		})

		local Tweens = {
			Hover = self:Tween({
				[Label] = {self.Parent.TweenInfo, { TextTransparency = 0.35 }};
				[UIStroke] = {self.Parent.TweenInfo, { Transparency = 0.4 }};
			});
			Normal = self:Tween({
				[Label] = {self.Parent.TweenInfo, { TextTransparency = 0.7 }};
				[UIStroke] = {self.Parent.TweenInfo, { Transparency = 0.6 }};
			});
			Pressing = self:Tween({
				[Label] = {self.Parent.TweenInfo, { TextTransparency = 0.2 }};
				[UIStroke] = {self.Parent.TweenInfo,  { Transparency = 0.25 }};
			});
			Enabled = self:Tween({
				[Label] = {self.Parent.TweenInfo, { TextTransparency = 0 }};
				[UIStroke] = {self.Parent.TweenInfo, { Transparency = 0 }};
			});
		}
	
		local ButtonState, IsHovering = "Normal", false
	
		Button.MouseButton1Down:Connect(function()
			PlayState(Tweens, "Pressing")
		end)
	
		Button.MouseButton1Up:Connect(function()
			if (not IsSelectable) then
				PlayState(Tweens, "Normal")
			else
				IsSelected = not IsSelected
			end

			if IsSelected then
				ButtonState = "Enabled"
			else
				ButtonState = IsHovering and "Hover" or "Normal"
			end
			Callback(Index, Value, IsSelected)
			PlayState(Tweens, ButtonState)
		end)
	
		Button.MouseEnter:Connect(function()
			IsHovering = true
			ButtonState = "Hover"
			if IsSelectable and IsSelected then
				return
			end
			PlayState(Tweens, ButtonState)
		end)
	
		Button.MouseLeave:Connect(function()
			IsHovering = false
			ButtonState = "Normal"
			if IsSelectable and IsSelected then 
				return 
			end
			PlayState(Tweens, ButtonState)
		end)
	
		PlayState(Tweens, "Normal")

		ButtonList[Index] = {
			Button = Button;
			Select = function(self, SelectedValue, NoCallback)
				IsSelected = SelectedValue
				if IsSelected then
					task.spawn(PlayState, Tweens, (IsSelected and "Enabled") or "Normal")
				end
				Callback(Index, Value, IsSelected, NoCallback)
			end,
		}
	end

	return ButtonList
end

--// UIObject
local BaseObjects = {}
BaseObjects.__index = BaseObjects

--// Objects
function BaseObjects:Button(Data)
	local ButtonObject = self.Library.Util:Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5);
		BackgroundColor3 = self.Library.Theme.Background_2;
		BorderSizePixel = 0;
		Position = UDim2.new(0.076, 67, 0.45, 0);
		Size = UDim2.new(0, 20, 0, 20);
		Name = "ButtonObject";
		Parent = self.Object;
		LayoutOrder = Data.LayoutOrder
	})

	local UICorner = self.Library.Util:Create("UICorner", {
		CornerRadius = UDim.new(0, 4);
		Parent = ButtonObject;
	})

	local UIStroke = self.Library.Util:Create("UIStroke", {
		Color = self.Library.Theme.Accent;
		Parent = ButtonObject;
	})

	local Button = self.Library.Util:Create("ImageButton", {
		Image = "rbxassetid://10519263435";
		ScaleType = Enum.ScaleType.Fit;
		BackgroundColor3 = Color3.new(1, 1, 1);
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 1, 0, 1);
		Size = UDim2.new(1, -2, 1, -2);
		Name = "Button";
		Parent = ButtonObject;
	})

	local Tweens = {
		Hover = self.Library.Util:Tween({
			[Button] = {self.TweenInfo, { ImageTransparency = 0.35 }};
			[UIStroke] = {self.TweenInfo, { Transparency = 0.4 }};
		});
		Normal = self.Library.Util:Tween({
			[Button] = {self.TweenInfo, { ImageTransparency = 0.7 }};
			[UIStroke] = {self.TweenInfo, { Transparency = 0.6 }};
		});
		Pressing = self.Library.Util:Tween({
			[Button] = {self.TweenInfo, { ImageTransparency = 0 }};
			[UIStroke] = {self.TweenInfo,  { Transparency = 0.25 }};
		});
	}

	local ButtonState = "Normal"

	local function PlayButtonState(State)
		State = State or ButtonState
		for _, Tween in next, Tweens[State] do
			Tween:Play()
		end
	end

	Button.MouseButton1Down:Connect(function()
		PlayButtonState("Pressing")
	end)

	Button.MouseButton1Up:Connect(function()
		self.Callback(Data.Flag)
		PlayButtonState()
	end)

	Button.MouseEnter:Connect(function()
		ButtonState = "Hover"
		PlayButtonState()
	end)

	Button.MouseLeave:Connect(function()
		ButtonState = "Normal"
		PlayButtonState()
	end)

	PlayButtonState("Normal")
end

function BaseObjects:Slider(Data)
	Data.DecimalPlaces = Data.DecimalPlaces or 0
	Data.DecimalPlaces = math.clamp(Data.DecimalPlaces, 0, 99)
	Data.Format = Data.Format or "%s"

	local SliderObject = self.Library.Util:Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5);
		BackgroundColor3 = self.Library.Theme.Background_2;
		BorderSizePixel = 0;
		Position = UDim2.new(0.076, 67, 0.45, 0);
		Size = UDim2.new(0, 129, 0, 18);
		Name = "SliderObject";
		Parent = self.Object;
		LayoutOrder = Data.LayoutOrder;
	})

	local UICorner = self.Library.Util:Create("UICorner", {
		CornerRadius = UDim.new(0, 4);
		Parent = SliderObject;
	})

	local UIStroke = self.Library.Util:Create("UIStroke", {
		Color = self.Library.Theme.Accent;
		Parent = SliderObject;
	})

	local Label = self.Library.Util:Create("TextLabel", {
		FontFace = self.Library.Theme.Font_Regular;
		Text = "";
		TextColor3 = Color3.new(1, 1, 1);
		TextSize = 16;
		TextStrokeColor3 = self.Library.Theme.Background_2;
		TextStrokeTransparency = 0;
		TextWrapped = true;
		BackgroundColor3 = Color3.new(1, 1, 1);
		BackgroundTransparency = 1;
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 2;
		Name = "Label";
		Parent = SliderObject;
	})

	local SliderBounds = self.Library.Util:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0);
		BackgroundColor3 = Color3.new(1, 1, 1);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Position = UDim2.new(0.5, 0, 0, 0);
		Size = UDim2.new(1, -2, 1, 0);
		Name = "SliderBounds";
		Parent = SliderObject;
	})

	local Fill = self.Library.Util:Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5);
		BackgroundColor3 = self.Library.Theme.Accent;
		BorderSizePixel = 0;
		Position = UDim2.new(0, 0, 0.5, 0);
		Size = UDim2.new(0.5, 0, 1, -2);
		Name = "Fill";
		Parent = SliderBounds;
	})

	local UICorner = self.Library.Util:Create("UICorner", {
		CornerRadius = UDim.new(0, 4);
		Parent = Fill;
	})

	local Tweens = {
		Normal = self.Library.Util:Tween({
			[Label] = {self.TweenInfo, { TextTransparency = 0.5 }};
			[UIStroke] = {self.TweenInfo, { Transparency = 0.6 }};
		});
		Hover = self.Library.Util:Tween({
			[Label] = {self.TweenInfo, { TextTransparency = 0.35 }};
			[UIStroke] = {self.TweenInfo, { Transparency = 0.2 }};
		});
		Sliding = self.Library.Util:Tween({
			[Label] = {self.TweenInfo, { TextTransparency = 0 }};
			[UIStroke] = {self.TweenInfo,  { Transparency = 0 }};
		});
	}

	local function PlaySliderTween(Tween)
		for _, Tween in next, Tweens[Tween] do
			Tween:Play()
		end
	end

	local MinRoundingX = (UICorner.CornerRadius.Offset * 2) + 10
	local CurrentState = "Normal"

	local ChangedConnection, UpdateConnection, CurrentInput
	local function InputChanged(PropertyName)
		if (not CurrentInput) then
			return
		end

		local PropertyValue = CurrentInput[PropertyName]
		if PropertyName == "UserInputState" then
			if PropertyValue == Enum.UserInputState.End then
				CurrentInput = nil
				ChangedConnection:Disconnect()
				UpdateConnection:Disconnect()

				PlaySliderTween(CurrentState)
			end
		end
	end
	local Update = self.Library.Util:SliderUpdateWrapper(SliderBounds, Label, Fill, Data, self)
	
	SliderObject.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			PlaySliderTween("Sliding")
			CurrentInput = Input
			ChangedConnection = Input.Changed:Connect(InputChanged)
			UpdateConnection = Services.RunService.RenderStepped:Connect(Update)
		end
	end)

	SliderObject.MouseEnter:Connect(function()
		CurrentState = "Hover"
		if (not CurrentInput) then
			PlaySliderTween(CurrentState)
		end
	end)

	SliderObject.MouseLeave:Connect(function()
		CurrentState = "Normal"
		if (not CurrentInput) then
			PlaySliderTween(CurrentState)
		end
	end)

	PlaySliderTween("Normal")

	Fill:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local CurrentX = Fill.AbsoluteSize.X
		if CurrentX < MinRoundingX then
			local Value = (1 - (CurrentX / MinRoundingX))
			Fill.BackgroundTransparency = Value
		else
			Fill.BackgroundTransparency = 0
		end
	end)

	Fill.Size = UDim2.new(
		self.Library.Util:XToScale(
			self.Library.Util:MapValue(Data.Default, Data.Min, Data.Max, 0, SliderBounds.AbsoluteSize.X, Data.DecimalPlaces),
			SliderBounds
		),
		0,
		1,
		-2
	)
	Label.Text = Data.Format:format(self.Library.Util:Round(Data.Default, Data.DecimalPlaces))

	if not (Data.NoStartCallback) then
		self.Callback("Slider", Data.Flag, Data.Default)
	end
end

function BaseObjects:Toggle(Data)
	local Value = Data.Default or false 

	local ToggleIndicator = self.Library.Util:Create("Frame", {
		BackgroundColor3 = self.Library.Theme.Accent;
		BorderSizePixel = 0;
		Position = UDim2.new(0, 42, 0, 0);
		Size = UDim2.new(0, 20, 0, 20);
		Name = "ToggleIndicator";
		Parent = self.Object;
		LayoutOrder = Data.LayoutOrder;
	})

	local ToggleUICorner = self.Library.Util:Create("UICorner", {
		CornerRadius = UDim.new(0, 6);
		Parent = ToggleIndicator;
	})

	local Background = self.Library.Util:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5);
		BackgroundColor3 = (Value and self.Library.Theme.Accent) or (self.Library.Theme.Background_3);
		BorderSizePixel = 0;
		Position = UDim2.new(0.5, 0, 0.5, 0);
		Size = UDim2.new(1, -4, 1, -4);
		Name = "Background";
		Parent = ToggleIndicator;
	})

	local BackgroundUICorner = self.Library.Util:Create("UICorner", {
		CornerRadius = UDim.new(0, 4);
		Parent = Background;
	})

	local UIStroke = self.Library.Util:Create("UIStroke", {
		Color = self.Library.Theme.Background_2;
		Parent = Background;
	})

	local Trigger = self.Library.Util:Create("TextButton", {
		FontFace = self.Library.Theme.Font_Regular;
		Text = "";
		TextColor3 = Color3.new(0, 0, 0);
		TextSize = 14;
		BackgroundTransparency = 1;
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 3;
		Parent = ToggleIndicator;
	})

	local Tweens = {
		Hover = self.Library.Util:Tween({
			[ToggleIndicator] = {self.TweenInfo, { Transparency = 0.4 }};
		});
		Pressing = self.Library.Util:Tween({
			[ToggleIndicator] = {self.TweenInfo, { Transparency = 0.2 }};
		});
		[true] = self.Library.Util:Tween({
			[Background] = {self.TweenInfo, { BackgroundColor3 = self.Library.Theme.Accent, Transparency = 0 }};
			[ToggleIndicator] = {self.TweenInfo,  { Transparency = 0 }};
		});
		[false] = self.Library.Util:Tween({
			[Background] = {self.TweenInfo, { BackgroundColor3 = self.Library.Theme.Background_3, Transparency = 1 }};
			[ToggleIndicator] = {self.TweenInfo,  { Transparency = 0.6 }};
		});
	}


	local function PlayToggleTween(Tween)
		Tween = Tween or Value
		for _, Tween in next, Tweens[Tween] do
			Tween:Play()
		end
	end

	Trigger.MouseButton1Down:Connect(function()
		PlayToggleTween("Pressing")
	end)

	Trigger.MouseButton1Up:Connect(function()
		Value = not Value

		PlayToggleTween(Value)

		self.Callback("Toggle", Data.Flag, Value)
	end)

	Trigger.MouseEnter:Connect(function()
		PlayToggleTween("Hover")
	end)

	Trigger.MouseLeave:Connect(function()
		PlayToggleTween(Value)
	end)
	PlayToggleTween(Value)
end

function BaseObjects:Label(Data)
	local Label = self.Library.Util:Create("TextLabel", {
		FontFace = self.Library.Theme.Font_Regular;
		TextColor3 = self.Library.Theme.White;
		TextSize = 16;
		TextXAlignment = Enum.TextXAlignment.Left;
		AnchorPoint = Vector2.new(0, 0.5);
		BackgroundColor3 = self.Library.Theme.White;
		BackgroundTransparency = 1;
		Position = UDim2.new(0.118, 0, 0.5, 0);
		Name = "Label";
		Text = Data.Text;
		Parent = self.Object;
		LayoutOrder = Data.LayoutOrder;
	})
	Label.Size = UDim2.new(0, Label.TextBounds.X, 1, 0);

	local Tweens = {
		[true] = self.Library.Util:Tween({
			[Label] = {self.TweenInfo, { TextTransparency = 0 }};
		});
		[false] = self.Library.Util:Tween({
			[Label] = {self.TweenInfo, { TextTransparency = 0.3 }};
		});
	}

	self.Hovering.Event:Connect(function(Value)
		for _, Tween in next, Tweens[Value] do
			Tween:Play()
		end
	end)
	
	for _, Tween in next, Tweens[false] do
		Tween:Play()
	end

	return Label
end

function BaseObjects:Dropdown(Data, Skeleton)
	local DropdownObject = self.Library.Util:Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5);
		BackgroundColor3 = self.Library.Theme.Background_2;
		BorderSizePixel = 0;
		Position = UDim2.new(0.076, 67, 0.45, 0);
		Size = UDim2.new(0, 129, 0, 18);
		Name = "DropdownObject";
		Parent = self.Object;
		LayoutOrder = Data.LayoutOrder;
	})		

	local Trigger = self.Library.Util:Create("TextButton", {
		FontFace = self.Library.Theme.Font_Regular;
		Text = "";
		TextColor3 = Color3.new(0, 0, 0);
		TextSize = 14;
		BackgroundTransparency = 1;
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 3;
		Parent = DropdownObject;
	})

	local UICorner = self.Library.Util:Create("UICorner", {
		CornerRadius = UDim.new(0, 4);
		Parent = DropdownObject;
	})

	local UIStroke = self.Library.Util:Create("UIStroke", {
		Color = self.Library.Theme.Accent;
		Parent = DropdownObject;
	})

	local Label = self.Library.Util:Create("TextLabel", {
		FontFace = self.Library.Theme.Font_Regular;
		Text = "Item1";
		TextColor3 = Color3.new(1, 1, 1);
		TextSize = 16;
		TextStrokeColor3 = self.Library.Theme.Background_2;
		TextStrokeTransparency = 0;
		TextXAlignment = Enum.TextXAlignment.Left;
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 3, 0, 0);
		Size = UDim2.new(1, -20, 1, 0);
		ZIndex = 2;
		Name = "Label";
		Parent = DropdownObject;
		ClipsDescendants = true;
	})

	local TransparencyGradient = self.Library.Util:Create("UIGradient", {
		Enabled = false;
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(0.699999988079071, 0, 0), NumberSequenceKeypoint.new(0.9990000128746033, 0.9998999834060669, 0), NumberSequenceKeypoint.new(1, 0, 0)});
		Name = "TransparencyGradient";
		Parent = Label;
	})

	local Indicator = self.Library.Util:Create("TextLabel", {
		FontFace = self.Library.Theme.Font_Regular;
		Text = "˄";
		TextColor3 = Color3.new(1, 1, 1);
		TextSize = 14;
		AnchorPoint = Vector2.new(1, 0);
		BackgroundTransparency = 1;
		Position = UDim2.new(1, 0, 0, 0);
		Size = UDim2.new(0.14, 0, 1, 0);
		Name = "Indicator";
		Parent = DropdownObject;
	})

	local UIAspectRatioConstraint = self.Library.Util:Create("UIAspectRatioConstraint", {
		AspectType = Enum.AspectType.ScaleWithParentSize;
		DominantAxis = Enum.DominantAxis.Height;
		Parent = Indicator;
	})

	local DropdownState = "Normal"

	local IndicatorSkin = {
		[true] = "˅", 
		[false] = "˄"
	}

	local Tweens = {
		Normal = self.Library.Util:Tween({
			[Label] = {self.TweenInfo, { TextTransparency = 0.5 }};
			[UIStroke] = {self.TweenInfo, { Transparency = 0.6 }};
		});
		Hover = self.Library.Util:Tween({
			[Label] = {self.TweenInfo, { TextTransparency = 0.3 }};
			[UIStroke] = {self.TweenInfo, { Transparency = 0.4 }};
		});
		Pressing = self.Library.Util:Tween({
			[Label] = {self.TweenInfo, { TextTransparency = 0.1 }};
			[UIStroke] = {self.TweenInfo,  { Transparency = 0.2 }};
		});
		Open = self.Library.Util:Tween({
			[Label] = {self.TweenInfo, { TextTransparency = 0 }};
			[UIStroke] = {self.TweenInfo,  { Transparency = 0 }};
		});
	}

	local function PlayState(State)
		State = State or DropdownState
		for _, Tween in next, Tweens[State] do
			Tween:Play()
		end
	end

	local IsOpen = false

	Label.TextTransparency = 0.4
	Label.Text = Data.Text
	TransparencyGradient.Enabled = Label.TextBounds.X > Label.AbsoluteSize.X

	local SelectedItems = {}

	local ToggleDropdown, GetDropdownY, GetDropdownX;

	local ListObject, DropdownHolder = self.Library.Util:CreateDropdownHolder(DropdownObject, Skeleton)
	local ItemList = self.Library.Util:LoadItemList(DropdownHolder, Data.Items, function(Index, Value, Selected, NoCallback)
		if (not NoCallback) then
			self.Callback("Dropdown", Index, Value, Selected)
		end

		if Data.SelectMultiple then
			if Selected then
				SelectedItems[#SelectedItems + 1] = Value
			else
				local ValueIndex = self.Library.Util:GetIndexOfValue(SelectedItems, Value)
				table.remove(SelectedItems, ValueIndex)
			end
		else
			SelectedItems[1] = Value
		end

		local NewText, SelectedCount = self.Library.Util:ConcatTable(SelectedItems, ", ", true)
		
		if SelectedCount > 0 then
			Label.TextTransparency = 0 
			Label.Text = NewText
		else
			Label.TextTransparency = 0.4
			Label.Text = Data.Text
		end
		
		TransparencyGradient.Enabled = Label.TextBounds.X > Label.AbsoluteSize.X

		if Data.CloseAfterSelection then
			ToggleDropdown(false)
		end
	end, Data.SelectMultiple)

	ToggleDropdown = function(Forced)
		if Forced ~= nil then
			IsOpen = Forced
		else
			IsOpen = not IsOpen
		end

		local DropdownX = GetDropdownX()
		Indicator.Text = IndicatorSkin[IsOpen]

		Services.TweenService:Create(ListObject, TweenInfo.new(0.125), {
			Size = IsOpen and UDim2.new(0, DropdownX, 0, GetDropdownY()) or UDim2.new(0, DropdownX, 0, 0)
		}):Play()

		Services.TweenService:Create(ListObject.UIStroke, TweenInfo.new(0.125), {
			Transparency = IsOpen and 0 or 1
		}):Play()
		PlayState(IsOpen and "Open" or DropdownState)
	end

	GetDropdownY = function()
		local ItemCount, ItemsY, PaddingY, ListLayoutPaddingY = 0, 0, 0, 0
		for i,v in next, DropdownHolder:GetChildren() do
			if v:IsA("TextButton") then
				ItemCount += 1
				ItemsY += v.Size.Y.Offset
			elseif v:IsA("UIPadding") then
				PaddingY += v.PaddingTop.Offset + v.PaddingRight.Offset + v.PaddingLeft.Offset + v.PaddingBottom.Offset
			elseif v:IsA("UIListLayout") then
				ListLayoutPaddingY = v.Padding.Offset
			end
		end
		return (ItemsY + PaddingY) + (ItemCount * ListLayoutPaddingY)
	end

	GetDropdownX = function()
		local SizeX = DropdownObject.AbsoluteSize.X
		for i,v in next, DropdownHolder:GetChildren() do
			if v:IsA("TextButton") then
				local CurrentX = v.Label.TextBounds.X + 15
				if CurrentX > SizeX then
					SizeX = CurrentX
				end
			end
		end
		return SizeX
	end

	Trigger.MouseButton1Down:Connect(function()
		PlayState("Pressing")
	end)
	
	Trigger.MouseButton1Up:Connect(function()
		ToggleDropdown()
	end)

	Trigger.MouseEnter:Connect(function()
		DropdownState = "Hover"
		if IsOpen then return end
		PlayState()
	end)
	Trigger.MouseLeave:Connect(function()
		DropdownState = "Normal"
		if IsOpen then return end
		PlayState()
	end)

	ToggleDropdown(false)

	return {
		UpdateList = function(self, newItems)
			Data.Items = newItems
		end;
		Toggle = function(self, Visible)
			ToggleDropdown(Visible)
		end,
	}
end

function BaseObjects:Information(Data, Skeleton)
	local TabSkeleton = Skeleton.Parent

	local TweenInfo1 = TweenInfo.new(0.1, Enum.EasingStyle.Quad)
	local TweenInfo2 = TweenInfo.new(0.2, Enum.EasingStyle.Quad)

	local Label = self.Library.Util:Create("TextLabel", {
		FontFace = self.Library.Theme.Font_Regular;
		Text = "(?)";
		TextColor3 = Color3.new(1, 1, 1);
		TextScaled = true;
		TextSize = 16;
		TextTransparency = 0.5;
		TextWrapped = true;
		TextXAlignment = Enum.TextXAlignment.Left;
		AnchorPoint = Vector2.new(0, 0.5);
		BackgroundColor3 = Color3.new(1, 1, 1);
		BackgroundTransparency = 1;
		Position = UDim2.new(0.118, 0, 0.5, 0);
		Size = UDim2.new(1, 0, 1, -2);
		Name = "Label";
		Parent = self.Object;
		LayoutOrder = Data.LayoutOrder;
	})

	local UIAspectRatioConstraint = self.Library.Util:Create("UIAspectRatioConstraint", {
		AspectType = Enum.AspectType.ScaleWithParentSize;
		DominantAxis = Enum.DominantAxis.Height;
		Parent = Label;
	})

	local InformationFrame, InformationLabel = self.Library.Util:CreateInformationFrame(Label, TabSkeleton)
	
	InformationLabel.Text = Data.Text
	
	local Tweens = {
		Hover = self.Library.Util:Tween({
			[Label] = {TweenInfo1, { TextTransparency = 0 }};
			[InformationLabel] = {TweenInfo2, { TextTransparency = 0 }};
			[InformationFrame.UIStroke] = {TweenInfo2, { Transparency = 0 }};
			[InformationFrame] = {TweenInfo2, { BackgroundTransparency = 0 }};
		});
		Normal = self.Library.Util:Tween({
			[Label] = {TweenInfo1, { TextTransparency = 0.5 }};
			[InformationLabel] = {TweenInfo2, { TextTransparency = 1 }};
			[InformationFrame.UIStroke] = {TweenInfo2, { Transparency = 1 }};
			[InformationFrame] = {TweenInfo2, { BackgroundTransparency = 1 }};
		});
	}

	local SizeX = math.clamp(InformationLabel.TextBounds.X + 10, 0, 250)
	Label.MouseEnter:Connect(function()
		local SizeY = InformationLabel.TextBounds.Y + 10

		local Position = Label.AbsolutePosition
		local Size = Label.AbsoluteSize

		InformationFrame.Position = self.Library.Util:OffsetUDim2(Position + Vector2.new(15, 15), TabSkeleton)
		InformationFrame:TweenSize( UDim2.new(0, SizeX, 0, SizeY), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
		for _, Tween in next, Tweens.Hover do
			Tween:Play()
		end
	end)

	Label.MouseLeave:Connect(function()
		InformationFrame:TweenSize(UDim2.new(0, SizeX, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.15, true)
		for _, Tween in next, Tweens.Normal do
			Tween:Play()
		end
	end)
end

function BaseObjects:construct()
	local Hovering = Instance.new("BindableEvent")
	self.Hovering = Hovering

	local Object = self.Library.Util:Create("Frame", {
		BackgroundColor3 = self.Library.Theme.White;
		BackgroundTransparency = 1;
		Position = UDim2.new(-0.133, 0, 0.105, 0);
		Size = UDim2.new(1, 0, 0, 20);
		Name = "Object";
		Parent = self.Groupbox.Objects.Container;
	})

	local UIListLayout = self.Library.Util:Create("UIListLayout", {
		Padding = UDim.new(0, 5);
		FillDirection = Enum.FillDirection.Horizontal;
		SortOrder = Enum.SortOrder.LayoutOrder;
		VerticalAlignment = Enum.VerticalAlignment.Center;
		Parent = Object;
	})

	Object.MouseEnter:Connect(function()
		Hovering:Fire(true)
	end)

	Object.MouseLeave:Connect(function()
		Hovering:Fire(false)
	end)

	self.Object = Object
end

function BaseObjects.new(Callback, Groupbox, Library)
	local self = setmetatable({}, BaseObjects)

	self.Callback = Callback
	self.Groupbox = Groupbox
	self.Library = Library
	self.Container = Groupbox.Objects.Container
	self.TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	self:construct()

	return self
end


--// GroupBox
local GroupBox = {}
GroupBox.__index = GroupBox

function GroupBox:Resize()
	local GroupboxY = 15

	local Children = self.Objects.Container:GetChildren()
	local ChildrenCount = #Children

	GroupboxY = GroupboxY + (ChildrenCount * 20) + ((ChildrenCount - 1 ) * 5) 

	local ObjectsCanvasX = {}
	local ObjectCount = 0
	for _, ItemObject in next, Children do
		if (not ItemObject:IsA("Frame")) then
			continue
		end
		local CanvasX = 0
		for _, ObjectPart in next, ItemObject:GetChildren() do
			if ObjectPart:IsA("UIListLayout") then
				continue
			end
			ObjectCount += 1
			CanvasX = CanvasX + ObjectPart.AbsoluteSize.X
		end
		ObjectsCanvasX[#ObjectsCanvasX+1] = CanvasX
	end	

	local CanvasX = 0
	for _, X in ipairs(ObjectsCanvasX) do
		if CanvasX < X then
			CanvasX = X
		end
	end

	CanvasX = CanvasX + ((ObjectCount - 1) * 5)

	self.Objects.Main.Size = UDim2.new(1, -7, 0, GroupboxY)
	self.Objects.Container.CanvasSize = UDim2.new(0, CanvasX, 0, 0)
end

function GroupBox:CreateObject(ObjectCallback, ObjectList)
	ObjectCallback = (ObjectCallback or print)

	local BaseObject = BaseObjects.new(ObjectCallback, self, self.Library)

	for Index, ObjectData in ipairs(ObjectList) do
		if (not ObjectData["LayoutOrder"]) then
			ObjectData["LayoutOrder"] = Index
		end

		local CreateObjectMethod = BaseObject[ObjectData.Type]
		CreateObjectMethod(BaseObject, ObjectData, self.Objects.Skeleton)
	end

	self:Resize()

	return BaseObject
end

function GroupBox:construct()
	local Tweens = {
		Hover = self.Library.Util:Tween({
			[self.Objects.Label] = {self.TweenInfo, { TextTransparency = 0 }};
			[self.Objects.Stroke] = {self.TweenInfo, { Transparency = 0.4 }};
		});
		Normal = self.Library.Util:Tween({
			[self.Objects.Label] = {self.TweenInfo, { TextTransparency = 0.3 }};
			[self.Objects.Stroke] = {self.TweenInfo, { Transparency = 0.9 }};
		});
	}
	
	local ScrollBarTweens = {
		Open = Services.TweenService:Create(self.Objects.Container, self.TweenInfo, {
			ScrollBarThickness = 4
		}),
		Closed = Services.TweenService:Create(self.Objects.Container, self.TweenInfo, {
			ScrollBarThickness = 1
		})
	}

	local LastChange = tick()

	self.Objects.Tab.Objects.Container:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		LastChange = tick()
	end)

	Services.RunService.RenderStepped:Connect(function()
		local LastChangeDelta = tick() - LastChange
		self.Objects.Container.ScrollBarImageTransparency = (LastChangeDelta > 0.5 and 0) or 1
	end)

	self.Objects.ScrollBarArea.MouseEnter:Connect(function()
		ScrollBarTweens.Open:Play()
	end)

	self.Objects.ScrollBarArea.MouseLeave:Connect(function()
		ScrollBarTweens.Closed:Play()
	end)


	self.Objects.Main.MouseEnter:Connect(function()
		for _, Tween in next, Tweens.Hover do
			Tween:Play()
		end
	end)

	self.Objects.Main.MouseLeave:Connect(function()
		for _, Tween in next, Tweens.Normal do
			Tween:Play()
		end
	end)

	for _, Tween in next, Tweens.Normal do
		Tween:Play()
	end
end

function GroupBox.new(Objects)
	local self = setmetatable({}, GroupBox)
	self.Objects = Objects
	self.Library = Objects.Library
	self.TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	self:construct()
	return self
end


--// Tabs
function Library.Tabs:__CreateTab()
	local TabContainer = self.Parent.Util:Create("ScrollingFrame", {
		ScrollBarImageColor3 = Color3.new(0, 0, 0);
		ScrollBarThickness = 0;
		AnchorPoint = Vector2.new(0.5, 0.5);
		BackgroundTransparency = 1;
		Position = UDim2.new(0.5, 0, 0.5, 0);
		Size = UDim2.new(1, -20, 1, -20);
		Name = "Container";
		Parent = self.Parent.Objects.Main;
	})

	local TabSkeleton = self.Parent.Util:Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BackgroundTransparency = 1;
		ZIndex = 10;
		Name = "TabSkeleton";
		Parent = self.Parent.Objects.Frames;
		ClipsDescendants = true,
	})

	--// Left Container
	local LContainer = self.Parent.Util:Create("Frame", {
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Size = UDim2.new(0.5, 0, 1, 0);
		Name = "LContainer";
		Parent = TabContainer;
	})

	local LSkeleton = self.Parent.Util:Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BackgroundTransparency = 1;
		ZIndex = 10;
		Name = "LSkeleton";
		Parent = TabSkeleton;
		ClipsDescendants = true,
	})

	local LLayout = self.Parent.Util:Create("UIListLayout", {
		Padding = UDim.new(0, 10);
		HorizontalAlignment = Enum.HorizontalAlignment.Center;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = LContainer;
	})

	local LPadding = self.Parent.Util:Create("UIPadding", {
		PaddingTop = UDim.new(0, 1);
		Parent = LContainer;
	})

	--// Right Container
	local RContainer = self.Parent.Util:Create("Frame", {
		AnchorPoint = Vector2.new(1, 0);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Position = UDim2.new(1, 0, 0, 0);
		Size = UDim2.new(0.5, 0, 1, 0);
		Name = "RContainer";
		Parent = TabContainer;
	})

	local RSkeleton = self.Parent.Util:Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BackgroundTransparency = 1;
		ZIndex = 10;
		Name = "RSkeleton";
		Parent = TabSkeleton;
		ClipsDescendants = true,
	})

	local RLayout = self.Parent.Util:Create("UIListLayout", {
		Padding = UDim.new(0, 10);
		HorizontalAlignment = Enum.HorizontalAlignment.Center;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = RContainer;
	})

	local RPadding = self.Parent.Util:Create("UIPadding", {
		PaddingTop = UDim.new(0, 1);
		Parent = RContainer;
	})

	--// Tab Button
	local Button = self.Parent.Util:Create("TextButton", {
		FontFace = self.Parent.Theme.Font_Regular;
		Text = "";
		TextColor3 = Color3.new(0, 0, 0);
		TextSize = 14;
		AutoButtonColor = false;
		BackgroundColor3 = self.Parent.Theme.Background_2;
		Position = UDim2.new(0.178, 0, 0, 0);
		Size = UDim2.new(1, -20, 0, 25);
		Name = "Button";
		Parent = self.Parent.Objects.Side.Container;
	})

	local UIStroke = self.Parent.Util:Create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
		Color = self.Parent.Theme.Accent;
		Parent = Button;
	})

	local UICorner = self.Parent.Util:Create("UICorner", {
		CornerRadius = UDim.new(0, 4);
		Parent = Button;
	})

	local IconContainer = self.Parent.Util:Create("Frame", {
		BackgroundTransparency = 1;
		Size = UDim2.new(1, 0, 1, 0);
		Name = "IconContainer";
		Parent = Button;
	})

	local UIAspectRatioConstraint = self.Parent.Util:Create("UIAspectRatioConstraint", {
		AspectType = Enum.AspectType.ScaleWithParentSize;
		DominantAxis = Enum.DominantAxis.Height;
		Parent = IconContainer;
	})

	local Icon = self.Parent.Util:Create("ImageLabel", {
		Image = self.Data.Icon or "rbxassetid://10403490626";
		AnchorPoint = Vector2.new(0.5, 0.5);
		BackgroundTransparency = 1;
		Position = UDim2.new(0.5, 0, 0.5, 0);
		Size = UDim2.new(1, -4, 1, -4);
		Name = "Icon";
		Parent = IconContainer;
	})

	local Label = self.Parent.Util:Create("TextLabel", {
		FontFace = self.Parent.Theme.Font_Regular;
		RichText = true;
		Text = self.Data.Title;
		TextColor3 = self.Parent.Theme.White;
		TextSize = 16;
		TextWrapped = true;
		TextXAlignment = Enum.TextXAlignment.Left;
		AnchorPoint = Vector2.new(0, 0.5);
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 27, 0.5, 0);
		Size = UDim2.new(1, -27, 1, 0);
		Name = "Label";
		Parent = Button;
	})

	self.Objects = {
		TabButton = Button;
		TabIcon = Icon;
		TabTitle = Label;
		Stroke = UIStroke;
		RContainer = RContainer;
		LContainer = LContainer;
		RSkeleton = RSkeleton;
		LSkeleton = LSkeleton;
		Skeleton = TabSkeleton;
		Container = TabContainer;
	}
end

function Library.Tabs:SetVisible(Value)
	if Value then
		if (self.Visible) then return end

		if Library.Tabs.ActiveTab then
			Library.Tabs.ActiveTab:SetVisible(false)
		end

		self.Visible = Value
		self.Objects.Container.Visible = Value

		Library.Tabs.ActiveTab = self

		self:PlayButtonState("Enabled")

		self.Objects.Container.Position = UDim2.new(0, 10, 0.5, 0)
		self.Tweens.ShowContainer:Play()
	else
		self.Objects.Container.Position = UDim2.new(0.5, 0, 0.5, 0)

		self.ButtonState = "Normal"
		self:PlayButtonState("Normal")

		self.Tweens.HideContainer:Play()

		self.Objects.Container.Visible = false
		self.Visible = false
	end
end

function Library.Tabs:Groupbox(GroupboxData)
	local ContainerSkeleton = GroupboxData.Side == 1 and self.Objects.LSkeleton or self.Objects.RSkeleton
	local Groupbox = self.Parent.Util:Create("Frame", {
		BackgroundColor3 = self.Parent.Theme.Background_3;
		BorderSizePixel = 0;
		Position = UDim2.new(0, 23, 0, 16);
		Size = UDim2.new(1, -7, 0, 35);
		Name = "Groupbox";
		ClipsDescendants = true,
		Parent = (GroupboxData.Side == 1 and self.Objects.LContainer) or self.Objects.RContainer;
	})

	local ScrollBarArea = self.Parent.Util:Create("Frame", {
		AnchorPoint = Vector2.new(0, 1);
		BackgroundColor3 = Color3.new(1, 1, 1);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Position = UDim2.new(0, 0, 1, 0);
		Size = UDim2.new(1, 0, 0, 20);
		Name = "ScrollBarArea";
		Parent = Groupbox;
	})

	local UICorner = self.Parent.Util:Create("UICorner", {
		Parent = Groupbox;
	})

	local UIStroke = self.Parent.Util:Create("UIStroke", {
		Color = self.Parent.Theme.Accent;
		Transparency = 0.9;
		Parent = Groupbox;
	})

	local Label = self.Parent.Util:Create("TextLabel", {
		FontFace = self.Parent.Theme.Font_Regular;
		Text = GroupboxData.Title;
		TextColor3 = self.Parent.Theme.White;
		TextSize = 18;
		TextXAlignment = Enum.TextXAlignment.Left;
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 7, 0, 7);
		Size = UDim2.new(1, -7, 0, 10);
		Parent = Groupbox;
	})

	local ItemHolder = self.Parent.Util:Create("ScrollingFrame", {
		BottomImage = "";
		TopImage = "";
		CanvasSize = UDim2.new(0, 0, 0, 0);
		ScrollBarImageColor3 = self.Parent.Theme.Accent;
		ScrollBarThickness = 3;
		VerticalScrollBarInset = Enum.ScrollBarInset.Always;
		AnchorPoint = Vector2.new(0.5, 0);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ClipsDescendants = false;
		Position = UDim2.new(0.5, 0, 0, 25);
		Size = UDim2.new(1, -20, 1, -35);
		Name = "ItemHolder";
		Parent = Groupbox;
	})

	local UIListLayout = self.Parent.Util:Create("UIListLayout", {
		Padding = UDim.new(0, 5);
		HorizontalAlignment = Enum.HorizontalAlignment.Center;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = ItemHolder;
	})

	return GroupBox.new({
		Main = Groupbox,
		Container = ItemHolder,
		Stroke = UIStroke,
		Label = Label,
		Tab = self,
		Skeleton = ContainerSkeleton,
		Library = self.Parent,
		ScrollBarArea = ScrollBarArea,
	})
end

function Library.Tabs:construct(Data)
	local TabTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	self.ButtonState = "Normal"
	self.Data = Data

	self:__CreateTab()

	self.Tweens = {
		HideContainer = Services.TweenService:Create(self.Objects.Container, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0,0,1,-20),
			Position = UDim2.new(1,-10,0.5,0)
		});
		ShowContainer = Services.TweenService:Create(self.Objects.Container, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { 
			Size = UDim2.new(1,-20,1,-20),
			Position = UDim2.new(0.5,0,0.5,0)
		});
		Button = {
			Hover = self.Parent.Util:Tween({
				[self.Objects.Stroke] = {TabTweenInfo, { Transparency = 0.4 }};
				[self.Objects.TabIcon] = {TabTweenInfo, { ImageTransparency = 0.35 }};
				[self.Objects.TabTitle] = {TabTweenInfo, { TextTransparency = 0.35 }};
			});
			Normal = self.Parent.Util:Tween({
				[self.Objects.Stroke] = {TabTweenInfo, { Transparency = 0.6 }};
				[self.Objects.TabIcon] = {TabTweenInfo, { ImageTransparency = 0.5 }};
				[self.Objects.TabTitle] = {TabTweenInfo, { TextTransparency = 0.5 }};
			});
			Pressing = self.Parent.Util:Tween({
				[self.Objects.Stroke] = {TabTweenInfo, { Transparency = 0.25 }};
				[self.Objects.TabIcon] = {TabTweenInfo, { ImageTransparency = 0 }};
				[self.Objects.TabTitle] = {TabTweenInfo, { TextTransparency = 0 }};
			});
			Enabled = self.Parent.Util:Tween({
				[self.Objects.Stroke] = {TabTweenInfo, { Transparency = 0 }};
				[self.Objects.TabIcon] = {TabTweenInfo, { ImageTransparency = 0 }};
				[self.Objects.TabTitle] = {TabTweenInfo, { TextTransparency = 0 }};
			});
		};
	}

	function self:PlayButtonState(State)
		State = State or self.ButtonState
		for _, Tween in next, self.Tweens.Button[State] do
			Tween:Play()
		end
	end

	--// Tab Button
	self.Objects.TabButton.MouseButton1Down:Connect(function()
		if self.Visible then
			return
		end

		self:PlayButtonState("Pressing")
	end)

	self.Objects.TabButton.MouseButton1Up:Connect(function()
		if self.Visible then
			return
		end

		self:PlayButtonState("Enabled")
		self:SetVisible(true)
	end)

	self.Objects.TabButton.MouseEnter:Connect(function()
		if self.Visible then
			return
		end

		self.ButtonState = "Hover"
		self:PlayButtonState()
	end)

	self.Objects.TabButton.MouseLeave:Connect(function()
		if self.Visible then
			return
		end

		self.ButtonState = "Normal"
		self:PlayButtonState()
	end)

	--// Update TabSkeleton
	local function UpdateContainerSkeleton(ParentPos)
		local SizeR = self.Objects.RContainer.AbsoluteSize
		local PositionR = self.Objects.RContainer.AbsolutePosition - ParentPos
		self.Objects.RSkeleton.Size = UDim2.new(0, SizeR.X, 0, SizeR.Y)
		self.Objects.RSkeleton.Position = UDim2.new(0, PositionR.X, 0, PositionR.Y)
		
		local SizeL = self.Objects.LContainer.AbsoluteSize
		local PositionL = self.Objects.LContainer.AbsolutePosition - ParentPos
		self.Objects.LSkeleton.Size = UDim2.new(0, SizeL.X, 0, SizeL.Y)
		self.Objects.LSkeleton.Position = UDim2.new(0, PositionL.X, 0, PositionL.Y)
	end

	local function UpdateTabSkeleton()
		local AbsoluteSize, AbsolutePosition = self.Objects.Container.AbsoluteSize, self.Objects.Container.AbsolutePosition
		self.Objects.Skeleton.Size = UDim2.new(0, AbsoluteSize.X, 0, AbsoluteSize.Y)
		self.Objects.Skeleton.Position = UDim2.new(0, AbsolutePosition.X, 0, AbsolutePosition.Y)

		UpdateContainerSkeleton(AbsolutePosition)
	end

	self.Objects.Container:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdateTabSkeleton)
	self.Objects.Container:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateTabSkeleton)
end

function Library.Tabs.new(TabData)
	local self = setmetatable({
		Visible = false
	}, Library.Tabs)

	self:construct(TabData)

	if (not Library.Tabs.ActiveTab) then
		Library.Tabs.ActiveTab = self
		self:SetVisible(true)
	else
		self:SetVisible(false)
	end

	return self
end

--// Library Methods
function Library:__CreateMainUI()
	local AlaskaUI = self.Util:Create("ScreenGui", {
		Name = "AlaskaUI";
		Parent = self.UIParent or Services.UIParent;
	})

	local Frames = self.Util:Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BackgroundTransparency = 1;
		Size = UDim2.new(1, 0, 1, 0);
		Name = "Frames";
		Parent = AlaskaUI;
	})

	local UiContainer = self.Util:Create("Frame", {
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Position = UDim2.new(0.175, 0, 0.186, 0);
		Size = UDim2.new(0, 700, 0, 565);
		Name = "Container";
		Parent = AlaskaUI;
		Draggable = true;
		Active = true;
	})

	local OuterStroke = self.Util:Create("UIStroke", {
		Color = self.Theme.Accent;
		Transparency = 0.8;
		Parent = UiContainer;
	})

	local Top = self.Util:Create("Frame", {
		AnchorPoint = Vector2.new(1, 0);
		BackgroundColor3 = self.Theme.Background_1;
		BorderSizePixel = 0;
		Position = UDim2.new(1, 0, 0, 0);
		Size = UDim2.new(0.714, 0, 0.106, 0);
		ZIndex = 0;
		Name = "Top";
		Parent = UiContainer;
	})

	local Divider = self.Util:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1);
		BackgroundColor3 = self.Theme.Divider;
		BorderSizePixel = 0;
		Position = UDim2.new(0.5, 0, 1, 0);
		Size = UDim2.new(1, -10, 0, 1);
		Name = "Divider";
		Parent = Top;
	})

	local TopContainer = self.Util:Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5);
		BackgroundTransparency = 1;
		Position = UDim2.new(1, -15, 0.5, 0);
		Size = UDim2.new(0.5, 0, 1, -29);
		Name = "Container";
		Parent = Top;
	})

	local UIListLayout = self.Util:Create("UIListLayout", {
		Padding = UDim.new(0, 10);
		FillDirection = Enum.FillDirection.Horizontal;
		HorizontalAlignment = Enum.HorizontalAlignment.Right;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = TopContainer;
	})

	local Side = self.Util:Create("Frame", {
		BorderSizePixel = 0;
		Size = UDim2.new(0.287, 0, 1, 0);
		Name = "Side";
		Parent = UiContainer;
	})

	local Background = self.Util:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5);
		BackgroundColor3 = self.Theme.Background_1;
		BorderSizePixel = 0;
		Position = UDim2.new(0.5, 0, 0.5, 0);
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = -5;
		Name = "Background";
		Parent = Side;
	})

	local SideContainer = self.Util:Create("ScrollingFrame", {
		ScrollBarImageColor3 = Color3.new(0, 0, 0);
		ScrollBarThickness = 0;
		Active = true;
		AnchorPoint = Vector2.new(0, 1);
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 0, 1, 0);
		Size = UDim2.new(1, 0, 0.894, -8);
		ZIndex = 2;
		Name = "Container";
		Parent = Side;
	})

	local SideListLayout = self.Util:Create("UIListLayout", {
		Padding = UDim.new(0, 10);
		HorizontalAlignment = Enum.HorizontalAlignment.Center;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = SideContainer;
	})

	local SideUIPadding = self.Util:Create("UIPadding", {
		PaddingTop = UDim.new(0, 5);
		Parent = SideContainer;
	})

	local SideTop = self.Util:Create("Frame", {
		BackgroundTransparency = 1;
		BackgroundColor3 = self.Theme.Background_1;
		Size = UDim2.new(1, 0, 0.106, 0);
		Name = "Top";
		BorderSizePixel = 0;
		Parent = Side;
	})

	local SideDivider = self.Util:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1);
		BackgroundColor3 = self.Theme.Divider;
		BorderSizePixel = 0;
		Position = UDim2.new(0.5, 0, 1, 0);
		Size = UDim2.new(1, -10, 0, 1);
		Name = "Divider";
		Parent = SideTop;
	})

	local IconContainer = self.Util:Create("Frame", {
		BackgroundTransparency = 1;
		Size = UDim2.new(1, 0, 1, 0);
		Name = "IconContainer";
		Parent = SideTop;
	})

	local Icon = self.Util:Create("ImageLabel", {
		Image = self.Data.Icon or "rbxassetid://10403490626";
		AnchorPoint = Vector2.new(0.5, 0.5);
		BackgroundTransparency = 1;
		Position = UDim2.new(0.5, 0, 0.5, 0);
		Size = UDim2.new(1, -10, 1, -10);
		Name = "Icon";
		Parent = IconContainer;
	})

	local Label = self.Util:Create("TextLabel", {
		Text = self.Data.Title;
		FontFace = self.Theme.Font_Bold;
		RichText = true;
		TextColor3 = self.Theme.White;
		TextScaled = true;
		TextSize = 18;
		TextWrapped = true;
		TextXAlignment = Enum.TextXAlignment.Left;
		AnchorPoint = Vector2.new(0, 0.5);
		BackgroundTransparency = 1;
		Position = UDim2.new(1, 0, 0.5, 0);
		Size = UDim2.new(0, 120, 0.401, 0);
		Name = "Label";
		Parent = Icon;
	})

	local UIAspectRatioConstraint = self.Util:Create("UIAspectRatioConstraint", {
		AspectType = Enum.AspectType.ScaleWithParentSize;
		DominantAxis = Enum.DominantAxis.Height;
		Parent = IconContainer;
	})

	local UIGradient = self.Util:Create("UIGradient", {
		Color = self.Theme.SideGradient;
		Offset = Vector2.new(-1.2, 0);
		Rotation = -45;
		Transparency = self.Theme.SideTransparency,
		Parent = Side;
	})

	local Main = self.Util:Create("Frame", {
		AnchorPoint = Vector2.new(1, 1);
		BackgroundColor3 = self.Theme.Background_1;
		BorderSizePixel = 0;
		Position = UDim2.new(1, 0, 1, 0);
		Size = UDim2.new(0.714, 0, 0.894, 0);
		Name = "Main";
		ClipsDescendants = true;
		Parent = UiContainer;
	})

	self.Objects["Main"] = Main
	self.Objects["Side"] = Side
	self.Objects["Top"] = Top
	self.Objects["Frames"] = Frames
	self.Objects["UiContainer"] = UiContainer
	self.Objects["Background"] = Background
	self.Objects["Label"] = Label
	self.Objects["SideDivider"] = SideDivider
	self.Objects["Divider"] = Divider
	self.Objects["Stroke"] = OuterStroke
end

function Library:construct(Data)
	self.UIParent = Data.Parent
	self.TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	self.Util.Parent = self
	self.Tabs.Parent = self

	self.GuiInset = Services.GuiService:GetGuiInset()

	self.Theme = {
		Background_1 = Color3.fromRGB(9, 9, 9);
		Background_2 = Color3.fromRGB(2, 5, 10);
		Background_3 = Color3.fromRGB(10, 10, 12);
		Accent = Color3.fromRGB(25, 147, 212);
		White = Color3.fromRGB(255,255,255);
		Gray = Color3.fromRGB(255,255,255);
		Divider = Color3.fromRGB(12, 37, 50);
		Font_Bold = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
		Font_Regular = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
		SideGradient = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(0.0117647, 0.0823529, 0.117647)), ColorSequenceKeypoint.new(0.518, Color3.new(0.0235294, 0.0235294, 0.0235294)), ColorSequenceKeypoint.new(0.9, Color3.new(0.0235294, 0.0235294, 0.0235294)), ColorSequenceKeypoint.new(1, Color3.new(0.0235294, 0.0235294, 0.0235294))});
		SideTransparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(0.1, 0.238, 0), NumberSequenceKeypoint.new(0.497, 0.631, 0), NumberSequenceKeypoint.new(0.891, 0.294, 0), NumberSequenceKeypoint.new(1, 0.131, 0)});
	};

	self.Data = Data

	self:__CreateMainUI()

	local Tweens = {
		Hover = self.Util:Tween({
			[self.Objects.Label] = {self.TweenInfo, { TextTransparency = 0 }};
			[self.Objects.Background] = {self.TweenInfo, { Transparency = 0 }};
			[self.Objects.Stroke] = {self.TweenInfo, { Transparency = 0.4 }};
		});
		Normal = self.Util:Tween({
			[self.Objects.Label] = {self.TweenInfo, { TextTransparency = 0.5 }};
			[self.Objects.Background] = {self.TweenInfo, { Transparency = 1 }};
			[self.Objects.Stroke] = {self.TweenInfo, { Transparency = 0.8 }};
		});
	}
	self.Objects.UiContainer.MouseEnter:Connect(function()
		for _, Tween in next, Tweens.Hover do
			Tween:Play()
		end
	end)
	self.Objects.UiContainer.MouseLeave:Connect(function()
		for _, Tween in next, Tweens.Normal do
			Tween:Play()
		end
	end)
	for _, Tween in next, Tweens.Normal do
		Tween:Play()
	end
end

function Library.new(LibraryData)
	local self = setmetatable({}, Library)

	self:construct(LibraryData)

	return self
end

return Library