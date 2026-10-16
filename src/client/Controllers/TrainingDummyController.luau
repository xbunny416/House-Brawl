--!strict
-- TrainingDummyController — the label above each Training Yard dummy: its name, Percent and (in modes with HP) HP.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Localization = require(Shared:WaitForChild("Localization"))

local DUMMY_TAG = "TrainingDummy"
local HEAD_WAIT = 5
local LABEL_SIZE = UDim2.fromScale(6, 2.4) -- studs
local LABEL_OFFSET = Vector3.new(0, 2.6, 0)
local LABEL_DISTANCE = 80
local TEXT_COLOR = Color3.fromHex("#F2E6D0")

local TrainingDummyController = {}

local function describe(model: Model): string
	local percent = model:GetAttribute("Percent")
	local lines = {
		Localization.format("Training.Dummy.Name"),
		Localization.format("Combat.Percent", { math.floor((if type(percent) == "number" then percent else 0) + 0.5) }),
	}
	local hp = model:GetAttribute("HP")
	if type(hp) == "number" then
		table.insert(lines, Localization.format("Combat.HP", { math.ceil(hp) }))
	end
	return table.concat(lines, "\n")
end

local function attach(instance: Instance)
	if not instance:IsA("Model") then
		return
	end
	local model = instance
	local head = model:WaitForChild("Head", HEAD_WAIT)
	if head == nil or not head:IsA("BasePart") or head:FindFirstChild("DummyLabel") then
		return
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "DummyLabel"
	gui.Adornee = head
	gui.Size = LABEL_SIZE
	gui.StudsOffset = LABEL_OFFSET
	gui.MaxDistance = LABEL_DISTANCE
	gui.LightInfluence = 0

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = TEXT_COLOR
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Parent = gui

	local function refresh()
		label.Text = describe(model)
	end
	refresh()
	model:GetAttributeChangedSignal("Percent"):Connect(refresh)
	model:GetAttributeChangedSignal("HP"):Connect(refresh)
	gui.Parent = head
end

function TrainingDummyController.Start(_self: any)
	CollectionService:GetInstanceAddedSignal(DUMMY_TAG):Connect(attach)
	for _, instance in CollectionService:GetTagged(DUMMY_TAG) do
		task.spawn(attach, instance)
	end
end

return TrainingDummyController
