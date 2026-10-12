--!strict
--[[
	Remotes
	-------
	Declares every RemoteEvent / RemoteFunction the game uses and hands out
	references in a realm-aware way:

	* Server: `Remotes.initServer()` creates the instances inside
	  ReplicatedStorage.Remotes once at startup. Getters then return them.
	* Client: getters wait for the instances to replicate.

	Payload shapes are documented next to each name and typed in Shared.Types.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local Remotes = {}

Remotes.Events = {
	-- Client -> Server
	SprintState = "SprintState", -- (wantsSprint: boolean)
	CrouchState = "CrouchState", -- (isCrouching: boolean)
	ClientReady = "ClientReady", -- ()

	-- Server -> Client
	InventoryUpdate = "InventoryUpdate", -- (snapshot: Types.InventorySnapshot)
	ResourceCollected = "ResourceCollected", -- (payload: Types.ResourceCollectedPayload)
	Notification = "Notification", -- (payload: Types.NotificationPayload)
	ObjectiveUpdate = "ObjectiveUpdate", -- (state: Types.ObjectiveState)
	SprintDenied = "SprintDenied", -- () server refused/ended a sprint (stamina empty)
}

Remotes.Functions = {
	-- Client -> Server
	GetInitialState = "GetInitialState", -- () -> Types.InitialState
}

local cachedFolder: Folder? = nil

local function getFolder(): Folder
	local cached = cachedFolder
	if cached then
		return cached
	end

	local resolved: Folder
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if existing and existing:IsA("Folder") then
			resolved = existing
		else
			local created = Instance.new("Folder")
			created.Name = FOLDER_NAME
			created.Parent = ReplicatedStorage
			resolved = created
		end
	else
		resolved = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
	end

	cachedFolder = resolved
	return resolved
end

local function ensure(className: "RemoteEvent" | "RemoteFunction", name: string): Instance
	local container = getFolder()
	local existing = container:FindFirstChild(name)
	if existing then
		return existing
	end

	if RunService:IsServer() then
		local instance = Instance.new(className)
		instance.Name = name
		instance.Parent = container
		return instance
	end

	return container:WaitForChild(name)
end

--[[
	Creates every declared remote. Called once by the server bootstrap before
	any service starts so clients never wait on a remote that doesn't exist.
]]
function Remotes.initServer()
	assert(RunService:IsServer(), "Remotes.initServer must run on the server")
	for _, name in pairs(Remotes.Events) do
		ensure("RemoteEvent", name)
	end
	for _, name in pairs(Remotes.Functions) do
		ensure("RemoteFunction", name)
	end
end

function Remotes.getEvent(name: string): RemoteEvent
	assert(Remotes.Events[name] ~= nil, ("Unknown RemoteEvent '%s'"):format(name))
	return ensure("RemoteEvent", name) :: RemoteEvent
end

function Remotes.getFunction(name: string): RemoteFunction
	assert(Remotes.Functions[name] ~= nil, ("Unknown RemoteFunction '%s'"):format(name))
	return ensure("RemoteFunction", name) :: RemoteFunction
end

return Remotes
