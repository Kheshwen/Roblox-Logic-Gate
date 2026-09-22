
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

-- Sound Effects
local function createSound(soundId, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.Parent = SoundService
	return sound
end

local sounds = {
	switch = createSound("rbxasset://sounds/switch.mp3", 0.3),
	success = createSound("rbxasset://sounds/victory.mp3", 0.6),
	error = createSound("rbxasset://sounds/error.mp3", 0.3)
}

-- Logic Gate Class
local LogicGate = {}
LogicGate.__index = LogicGate

function LogicGate.new(gateType, position, player)
	local self = setmetatable({}, LogicGate)
	self.type = gateType
	self.inputs = {}
	self.output = false
	self.player = player
	self.id = tostring(math.random(100000, 999999))
	self.part = self:createVisual(position)
	self.outputPart = self:createOutputIndicator()
	self.inputParts = self:createInputIndicators()

	return self
end

function LogicGate:createVisual(position)
	local part = Instance.new("Part")
	part.Name = self.type .. "Gate_" .. self.id
	part.Size = Vector3.new(6, 3, 2)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.BrickColor = BrickColor.new("Dark stone grey")
	part.Parent = workspace

	-- Add 3D label
	local labelPart = Instance.new("Part")
	labelPart.Name = "Label"
	labelPart.Size = Vector3.new(4, 1, 0.1)
	labelPart.Position = position + Vector3.new(0, 0, 1.1)
	labelPart.Anchored = true
	labelPart.CanCollide = false
	labelPart.Transparency = 0.5
	labelPart.BrickColor = BrickColor.new("Really black")
	labelPart.Parent = part

	local gui = Instance.new("SurfaceGui")
	gui.Parent = labelPart
	gui.Face = Enum.NormalId.Front

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = string.upper(self.type)
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	return part
end

function LogicGate:createOutputIndicator()
	local outputPart = Instance.new("Part")
	outputPart.Name = "Output"
	outputPart.Size = Vector3.new(1.5, 1.5, 1.5)
	outputPart.Position = self.part.Position + Vector3.new(4, 0, 0)
	outputPart.Anchored = true
	outputPart.CanCollide = false
	outputPart.Shape = Enum.PartType.Ball
	outputPart.Material = Enum.Material.Neon
	outputPart.BrickColor = BrickColor.new("Really red")
	outputPart.Parent = self.part

	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.new(1, 0, 0)
	pointLight.Brightness = 1
	pointLight.Range = 10
	pointLight.Parent = outputPart

	self.outputLight = pointLight
	return outputPart
end

function LogicGate:createInputIndicators()
	local inputParts = {}
	local inputCount = (self.type == "NOT") and 1 or 2

	for i = 1, inputCount do
		local inputPart = Instance.new("Part")
		inputPart.Name = "Input" .. i
		inputPart.Size = Vector3.new(1, 1, 1)
		local yOffset = (i == 1) and 1 or -1
		if inputCount == 1 then yOffset = 0 end
		inputPart.Position = self.part.Position + Vector3.new(-4, yOffset, 0)
		inputPart.Anchored = true
		inputPart.CanCollide = false
		inputPart.Shape = Enum.PartType.Ball
		inputPart.Material = Enum.Material.Neon
		inputPart.BrickColor = BrickColor.new("Really red")
		inputPart.Parent = self.part

		local inputLight = Instance.new("PointLight")
		inputLight.Color = Color3.new(1, 0, 0)
		inputLight.Brightness = 0.5
		inputLight.Range = 5
		inputLight.Parent = inputPart

		inputParts[i] = {part = inputPart, light = inputLight}
	end

	return inputParts
end

function LogicGate:setInput(inputIndex, value)
	self.inputs[inputIndex] = value
	self:updateInputVisual(inputIndex, value)
	self:updateOutput()
end

function LogicGate:updateInputVisual(inputIndex, value)
	if self.inputParts[inputIndex] then
		local inputObj = self.inputParts[inputIndex]
		if value then
			inputObj.part.BrickColor = BrickColor.new("Bright green")
			inputObj.light.Color = Color3.new(0, 1, 0)
			inputObj.light.Brightness = 1
		else
			inputObj.part.BrickColor = BrickColor.new("Really red")
			inputObj.light.Color = Color3.new(1, 0, 0)
			inputObj.light.Brightness = 0.5
		end
	end
end

function LogicGate:updateOutput()
	-- Get input values with default to false if nil
	local input1 = self.inputs[1] == true
	local input2 = self.inputs[2] == true

	-- Logic gate calculations
	if self.type == "AND" then
		self.output = input1 and input2
	elseif self.type == "OR" then
		self.output = input1 or input2
	elseif self.type == "NOT" then
		self.output = not input1
	elseif self.type == "NAND" then
		self.output = not (input1 and input2)
	elseif self.type == "NOR" then
		self.output = not (input1 or input2)
	elseif self.type == "XOR" then
		self.output = (input1 and not input2) or (not input1 and input2)
	end

	-- Update visual output
	if self.output then
		self.outputPart.BrickColor = BrickColor.new("Bright green")
		self.outputLight.Color = Color3.new(0, 1, 0)
		self.outputLight.Brightness = 2

		self.part.BrickColor = BrickColor.new("Bright yellow") -- glow when active

		-- Pulse effect
		local tween = TweenService:Create(self.outputPart,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Size = Vector3.new(1.8, 1.8, 1.8)}
		)
		tween:Play()
	else
		self.outputPart.BrickColor = BrickColor.new("Really red")
		self.outputLight.Color = Color3.new(1, 0, 0)
		self.outputLight.Brightness = 1
		self.outputPart.Size = Vector3.new(1.5, 1.5, 1.5)

		self.part.BrickColor = BrickColor.new("Dark stone grey") -- revert when off
	end
end

-- Input Switch Class
local InputSwitch = {}
InputSwitch.__index = InputSwitch

function InputSwitch.new(position, player, label)
	local self = setmetatable({}, InputSwitch)
	self.output = false
	self.player = player
	self.label = label or "INPUT"
	self.id = tostring(math.random(100000, 999999))
	self.part = self:createVisual(position)
	self.connectedGate = nil
	self.connectedInputIndex = nil

	return self
end

function InputSwitch:createVisual(position)
	local part = Instance.new("Part")
	part.Name = "InputSwitch_" .. self.id
	part.Size = Vector3.new(3, 3, 3)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Shape = Enum.PartType.Cylinder
	part.Material = Enum.Material.Neon
	part.BrickColor = BrickColor.new("Really red")
	part.Parent = workspace

	-- Add label
	local labelPart = Instance.new("Part")
	labelPart.Size = Vector3.new(3, 0.5, 0.1)
	labelPart.Position = position + Vector3.new(0, -2.5, 2.1)
	labelPart.Anchored = true
	labelPart.CanCollide = false
	labelPart.BrickColor = BrickColor.new("Really black")
	labelPart.Transparency = 0.3
	labelPart.Parent = part

	local gui = Instance.new("SurfaceGui")
	gui.Parent = labelPart

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = self.label
	textLabel.TextScaled = true
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = gui

	-- Add lighting
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.new(1, 0, 0)
	pointLight.Brightness = 1
	pointLight.Range = 8
	pointLight.Parent = part

	self.light = pointLight

	-- Click detection for interaction
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 50
	clickDetector.Parent = part

	clickDetector.MouseClick:Connect(function(player)
		if player == self.player then
			self:toggle()
		end
	end)

	return part
end

function InputSwitch:toggle()
	self.output = not self.output

	if self.output then
		self.part.BrickColor = BrickColor.new("Bright green")
		self.light.Color = Color3.new(0, 1, 0)
		self.light.Brightness = 2
	else
		self.part.BrickColor = BrickColor.new("Really red")
		self.light.Color = Color3.new(1, 0, 0)
		self.light.Brightness = 1
	end

	sounds.switch:Play()

	-- VFX burst
	local particle = Instance.new("ParticleEmitter")
	particle.Texture = "rbxassetid://243660364" -- sparkle texture
	particle.Rate = 100
	particle.Lifetime = NumberRange.new(0.3)
	particle.Speed = NumberRange.new(2, 4)
	particle.Size = NumberSequence.new(0.5)
	particle.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	particle.Parent = self.part

	task.delay(0.3, function()
		particle.Enabled = false
		particle:Destroy()
	end)

	-- Update connected gate
	if self.connectedGate and self.connectedInputIndex then
		self.connectedGate:setInput(self.connectedInputIndex, self.output)
	end
end


function InputSwitch:connectTo(gate, inputIndex)
	self.connectedGate = gate
	self.connectedInputIndex = inputIndex
	gate:setInput(inputIndex, self.output)
end

-- Learning Platform Class
local LearningPlatform = {}
LearningPlatform.__index = LearningPlatform

function LearningPlatform.new(gateType, position, platformNumber)
	local self = setmetatable({}, LearningPlatform)
	self.gateType = gateType
	self.position = position
	self.platformNumber = platformNumber
	self.switches = {}
	self.gate = nil
	self.truthTable = self:getTruthTableData()

	self:createPlatform()
	self:createTruthTableDisplay()
	self:createInstructions()

	return self
end

function LearningPlatform:getTruthTableData()
	local tables = {
		AND = {
			{inputs = {false, false}, output = false},
			{inputs = {false, true}, output = false},
			{inputs = {true, false}, output = false},
			{inputs = {true, true}, output = true}
		},
		OR = {
			{inputs = {false, false}, output = false},
			{inputs = {false, true}, output = true},
			{inputs = {true, false}, output = true},
			{inputs = {true, true}, output = true}
		},
		NOT = {
			{inputs = {false}, output = true},
			{inputs = {true}, output = false}
		},
		NAND = {
			{inputs = {false, false}, output = true},
			{inputs = {false, true}, output = true},
			{inputs = {true, false}, output = true},
			{inputs = {true, true}, output = false}
		},
		NOR = {
			{inputs = {false, false}, output = true},
			{inputs = {false, true}, output = false},
			{inputs = {true, false}, output = false},
			{inputs = {true, true}, output = false}
		},
		XOR = {
			{inputs = {false, false}, output = false},
			{inputs = {false, true}, output = true},
			{inputs = {true, false}, output = true},
			{inputs = {true, true}, output = false}
		}
	}
	return tables[self.gateType] or {}
end

function LearningPlatform:createPlatform()
	-- Main platform
	local platform = Instance.new("Part")
	platform.Name = self.gateType .. "_Platform_" .. self.platformNumber
	platform.Size = Vector3.new(40, 2, 30)
	platform.Position = self.position
	platform.Anchored = true
	platform.BrickColor = BrickColor.new("Medium stone grey")
	platform.Material = Enum.Material.Concrete
	platform.Parent = workspace

	-- Platform number display
	local numberPart = Instance.new("Part")
	numberPart.Size = Vector3.new(8, 1, 8)
	numberPart.Position = self.position + Vector3.new(-15, 2, -10)
	numberPart.Anchored = true
	numberPart.BrickColor = BrickColor.new("Really black")
	numberPart.Material = Enum.Material.Neon
	numberPart.Parent = platform

	local numberGui = Instance.new("SurfaceGui")
	numberGui.Parent = numberPart

	local numberLabel = Instance.new("TextLabel")
	numberLabel.Size = UDim2.new(1, 0, 1, 0)
	numberLabel.BackgroundTransparency = 1
	numberLabel.Text = tostring(self.platformNumber)
	numberLabel.TextScaled = true
	numberLabel.TextColor3 = Color3.new(1, 1, 1)
	numberLabel.Font = Enum.Font.GothamBold
	numberLabel.Parent = numberGui

	-- Gate title
	local titlePart = Instance.new("Part")
	titlePart.Size = Vector3.new(12, 3, 1)
	titlePart.Position = self.position + Vector3.new(0, 5, -14)
	titlePart.Anchored = true
	titlePart.BrickColor = BrickColor.new("Really black")
	titlePart.Material = Enum.Material.ForceField
	titlePart.Parent = platform

	local titleGui = Instance.new("SurfaceGui")
	titleGui.Parent = titlePart

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = self.gateType .. " GATE LEARNING PLATFORM"
	titleLabel.TextScaled = true
	titleLabel.TextColor3 = Color3.new(1, 1, 0)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = titleGui
end

function LearningPlatform:setupForPlayer(player)
	-- Create gate
	self.gate = LogicGate.new(self.gateType, self.position + Vector3.new(0, 3, 0), player)

	-- Create input switches
	if self.gateType == "NOT" then
		local switchA = InputSwitch.new(self.position + Vector3.new(-8, 3, 0), player, "INPUT A")
		switchA:connectTo(self.gate, 1)
		table.insert(self.switches, switchA)
	else
		local switchA = InputSwitch.new(self.position + Vector3.new(-8, 3, 2), player, "INPUT A")
		local switchB = InputSwitch.new(self.position + Vector3.new(-8, 3, -2), player, "INPUT B")
		switchA:connectTo(self.gate, 1)
		switchB:connectTo(self.gate, 2)
		table.insert(self.switches, switchA)
		table.insert(self.switches, switchB)
	end
end

function LearningPlatform:createTruthTableDisplay()
	local display = Instance.new("Part")
	display.Name = self.gateType .. "_TruthTable"
	display.Size = Vector3.new(15, 10, 1)
	display.Position = self.position + Vector3.new(12, 8, -8) -- moved back
	display.Anchored = true
	display.CanCollide = false
	display.BrickColor = BrickColor.new("Really black")
	display.Material = Enum.Material.ForceField
	display.Parent = workspace

	-- Surface GUI and contents remain unchanged...


	local gui = Instance.new("SurfaceGui")
	gui.Parent = display

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
	frame.BackgroundTransparency = 0.3
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.15, 0)
	title.BackgroundTransparency = 1
	title.Text = self.gateType .. " GATE TRUTH TABLE"
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 0)
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	-- Create truth table content
	local tableText = self:generateTruthTableText()
	local content = Instance.new("TextLabel")
	content.Size = UDim2.new(0.9, 0, 0.8, 0)
	content.Position = UDim2.new(0.05, 0, 0.18, 0)
	content.BackgroundTransparency = 1
	content.Text = tableText
	content.TextScaled = true
	content.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	content.Font = Enum.Font.Code
	content.TextXAlignment = Enum.TextXAlignment.Center
	content.TextYAlignment = Enum.TextYAlignment.Top
	content.Parent = frame
end

function LearningPlatform:generateTruthTableText()
	local text = ""

	if self.gateType == "NOT" then
		text = "INPUT A | OUTPUT\n"
		text = text .. "--------+--------\n"
		for _, row in ipairs(self.truthTable) do
			local inputStr = row.inputs[1] and "1" or "0"
			local outputStr = row.output and "1" or "0"
			text = text .. "   " .. inputStr .. "    |   " .. outputStr .. "\n"
		end
	else
		text = "INPUT A | INPUT B | OUTPUT\n"
		text = text .. "--------+--------+--------\n"
		for _, row in ipairs(self.truthTable) do
			local inputAStr = row.inputs[1] and "1" or "0"
			local inputBStr = row.inputs[2] and "1" or "0"
			local outputStr = row.output and "1" or "0"
			text = text .. "   " .. inputAStr .. "    |   " .. inputBStr .. "    |   " .. outputStr .. "\n"
		end
	end

	return text
end

function LearningPlatform:createInstructions()
	local instructions = Instance.new("Part")
	instructions.Name = self.gateType .. "_Instructions"
	instructions.Size = Vector3.new(18, 8, 1)
	instructions.Position = self.position + Vector3.new(-12, 8, -8) -- moved back
	instructions.Anchored = true
	instructions.CanCollide = false
	instructions.BrickColor = BrickColor.new("Really black")
	instructions.Material = Enum.Material.ForceField
	instructions.Parent = workspace
	local gui = Instance.new("SurfaceGui")
	gui.Parent = instructions

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
	frame.BackgroundTransparency = 0.2
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.15, 0)
	title.BackgroundTransparency = 1
	title.Text = "HOW TO USE " .. self.gateType .. " GATES"
	title.TextScaled = true
	title.TextColor3 = Color3.new(0, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	local instructionText = self:getGateInstructions()
	local content = Instance.new("TextLabel")
	content.Size = UDim2.new(0.95, 0, 0.8, 0)
	content.Position = UDim2.new(0.025, 0, 0.18, 0)
	content.BackgroundTransparency = 1
	content.Text = instructionText
	content.TextScaled = true
	content.TextColor3 = Color3.new(0.9, 0.9, 1)
	content.Font = Enum.Font.Gotham
	content.TextXAlignment = Enum.TextXAlignment.Left
	content.TextYAlignment = Enum.TextYAlignment.Top
	content.Parent = frame
end

function LearningPlatform:getGateInstructions()
	local instructions = {
		AND = [[
CONTROLS:
• Click the input switches to toggle them ON/OFF
• Watch how the output changes
• Green = ON (TRUE), Red = OFF (FALSE)

AND GATE RULES:
• Output is ON only when BOTH inputs are ON
• If either input is OFF, output is OFF
• Used for: "Both conditions must be true"
• Example: Door opens only if you have key AND permission

TRY THIS:
1. Set both inputs to OFF - output should be OFF
2. Set Input A to ON, B to OFF - output stays OFF
3. Set Input A to OFF, B to ON - output stays OFF
4. Set both inputs to ON - output turns ON!
        ]],
		OR = [[
CONTROLS:
• Click the input switches to toggle them ON/OFF
• Watch how the output changes
• Green = ON (TRUE), Red = OFF (FALSE)

OR GATE RULES:
• Output is ON when ANY input is ON
• Output is OFF only when BOTH inputs are OFF
• Used for: "At least one condition must be true"
• Example: Alarm sounds if door OR window is opened

TRY THIS:
1. Set both inputs to OFF - output should be OFF
2. Set Input A to ON, B to OFF - output turns ON
3. Set Input A to OFF, B to ON - output turns ON
4. Set both inputs to ON - output stays ON
        ]],
		NOT = [[
CONTROLS:
• Click the input switch to toggle it ON/OFF
• Watch how the output changes
• Green = ON (TRUE), Red = OFF (FALSE)

NOT GATE RULES:
• Output is OPPOSITE of input
• If input is ON, output is OFF
• If input is OFF, output is ON
• Used for: "Invert or reverse a signal"
• Example: Light turns OFF when switch is ON

TRY THIS:
1. Set input to OFF - output should be ON
2. Set input to ON - output should be OFF
3. Toggle back and forth to see the inversion
        ]],
		NAND = [[
CONTROLS:
• Click the input switches to toggle them ON/OFF
• Watch how the output changes
• Green = ON (TRUE), Red = OFF (FALSE)

NAND GATE RULES:
• Output is OFF only when BOTH inputs are ON
• NAND = NOT AND (opposite of AND gate)
• Used for: "Not both conditions true"
• Example: Safety system - shut off when both sensors active

TRY THIS:
1. Set both inputs to OFF - output should be ON
2. Set Input A to ON, B to OFF - output stays ON
3. Set Input A to OFF, B to ON - output stays ON
4. Set both inputs to ON - output turns OFF!
        ]],
		NOR = [[
CONTROLS:
• Click the input switches to toggle them ON/OFF
• Watch how the output changes
• Green = ON (TRUE), Red = OFF (FALSE)

NOR GATE RULES:
• Output is ON only when BOTH inputs are OFF
• NOR = NOT OR (opposite of OR gate)
• Used for: "Neither condition is true"
• Example: Safe to proceed only when no alarms are active

TRY THIS:
1. Set both inputs to OFF - output should be ON
2. Set Input A to ON, B to OFF - output turns OFF
3. Set Input A to OFF, B to ON - output turns OFF
4. Set both inputs to ON - output stays OFF
        ]],
		XOR = [[
CONTROLS:
• Click the input switches to toggle them ON/OFF
• Watch how the output changes
• Green = ON (TRUE), Red = OFF (FALSE)

XOR GATE RULES:
• Output is ON when inputs are DIFFERENT
• Output is OFF when inputs are the SAME
• Used for: "Exclusive OR - one or the other, not both"
• Example: Light controlled by two switches

TRY THIS:
1. Set both inputs to OFF - output should be OFF
2. Set Input A to ON, B to OFF - output turns ON
3. Set Input A to OFF, B to ON - output turns ON
4. Set both inputs to ON - output turns OFF!
        ]]
	}
	return instructions[self.gateType] or "Instructions not available for this gate type."
end

-- Main System
local LogicGatesSystem = {}
LogicGatesSystem.platforms = {}
LogicGatesSystem.playerPlatforms = {}

function LogicGatesSystem:init()
	-- Create learning platforms for each gate type
	local gateTypes = {"AND", "OR", "NOT", "NAND", "NOR", "XOR"}
	local startPosition = Vector3.new(0, 10, 0)
	local spacing = 60

	for i, gateType in ipairs(gateTypes) do
		local position = startPosition + Vector3.new((i-1) * spacing, 0, 0)
		local platform = LearningPlatform.new(gateType, position, i)
		table.insert(self.platforms, platform)
	end

	-- Handle player connections
	Players.PlayerAdded:Connect(function(player)
		self:setupPlayerPlatforms(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:cleanupPlayerPlatforms(player)
	end)
end

function LogicGatesSystem:setupPlayerPlatforms(player)
	wait(1) -- Wait for character to load

	self.playerPlatforms[player] = {}

	for _, platform in ipairs(self.platforms) do
		platform:setupForPlayer(player)
		table.insert(self.playerPlatforms[player], platform)
	end

	print("Logic Gates learning platforms set up for " .. player.Name)
end

function LogicGatesSystem:cleanupPlayerPlatforms(player)
	if self.playerPlatforms[player] then
		-- Clean up player-specific objects if needed
		self.playerPlatforms[player] = nil
	end
end

-- Initialize the system
LogicGatesSystem:init()

print("Logic Gates Learning Platform loaded successfully!")
print("Available gates: AND, OR, NOT, NAND, NOR, XOR")
print("Each platform has interactive switches and displays truth tables.")
