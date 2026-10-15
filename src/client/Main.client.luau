--!strict
-- Client entry point. Boots every controller module in StarterPlayerScripts.Client.Controllers.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("Loader"))

local controllers = (script.Parent :: Instance):FindFirstChild("Controllers")
if controllers then
	Loader.Boot(controllers)
end
