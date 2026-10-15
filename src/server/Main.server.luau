--!strict
-- Server entry point. Boots every service module in ServerScriptService.Server.Services.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("Loader"))

local services = (script.Parent :: Instance):FindFirstChild("Services")
if services then
	Loader.Boot(services)
end
