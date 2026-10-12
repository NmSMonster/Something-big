--!strict
--[[
	NotificationService
	-------------------
	Sends toast notifications to one player or everybody.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local NotificationService = {}

local remote: RemoteEvent? = nil

local function getRemote(): RemoteEvent
	local cached = remote
	if cached then
		return cached
	end
	local resolved = Remotes.getEvent(Remotes.Events.Notification)
	remote = resolved
	return resolved
end

function NotificationService.Init()
	getRemote()
end

function NotificationService.send(player: Player, payload: Types.NotificationPayload)
	getRemote():FireClient(player, payload)
end

function NotificationService.broadcast(payload: Types.NotificationPayload)
	getRemote():FireAllClients(payload)
end

return NotificationService
