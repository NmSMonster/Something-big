--!strict
--[[
	Types
	-----
	Data shapes shared between server and client. Anything that crosses a
	RemoteEvent/RemoteFunction is described here so both sides agree.
]]

export type ResourceId = string

export type InventorySnapshot = {
	counts: { [ResourceId]: number },
	total: number,
	capacity: number,
}

export type ObjectiveState = {
	index: number, -- 1-based index into ObjectiveDefinitions.List of the ACTIVE objective
	progress: number,
	target: number,
	completedId: string?, -- id of an objective that was just completed (transition flag)
	allComplete: boolean,
}

export type NotificationKind = "info" | "success" | "warning" | "danger" | "objective"

export type NotificationPayload = {
	title: string,
	body: string?,
	kind: NotificationKind?,
	duration: number?,
}

export type ResourceCollectedPayload = {
	resourceId: ResourceId,
	amount: number,
	position: Vector3,
	nodeId: number,
	collectorUserId: number,
}

export type InitialState = {
	inventory: InventorySnapshot,
	objective: ObjectiveState,
	serverVersion: string,
}

export type Zone = {
	id: string,
	cframe: CFrame,
	size: Vector3,
}

export type ResourceSpawn = {
	resourceId: ResourceId,
	position: Vector3, -- studs, world space; the node rests on this point
	amountMin: number,
	amountMax: number,
	rotation: number?, -- yaw in radians
}

export type KitchenBuildResult = {
	model: Model,
	spawnCFrames: { CFrame },
	resourceSpawns: { ResourceSpawn },
	zones: { Zone },
}

return nil
