--!strict
--[[
	InteractionController
	---------------------
	Renders custom UI for ProximityPrompts (resource nodes) and highlights the
	node the player is looking at. The engine still handles range checks and
	hold timing; the server validates every collection.
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local ClientState = require(script.Parent.Parent.State.ClientState)
local InteractionPrompt = require(script.Parent.Parent.UI.InteractionPrompt)
local InputController = require(script.Parent.InputController)
local AudioController = require(script.Parent.AudioController)

local InteractionController = {}

type ActivePrompt = {
	ui: InteractionPrompt.PromptUI,
	highlight: Highlight?,
	trove: Trove.Trove,
}

local player = Players.LocalPlayer
local active: { [ProximityPrompt]: ActivePrompt } = {}

local function hidePrompt(prompt: ProximityPrompt)
	local entry = active[prompt]
	if not entry then
		return
	end
	active[prompt] = nil
	entry.trove:Destroy()
end

local function showPrompt(prompt: ProximityPrompt)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
		return
	end
	if active[prompt] or not ClientState.isPlaying then
		return
	end

	local trove = Trove.new()
	local ui = InteractionPrompt.create(prompt, InputController.getInteractGlyph(), player:WaitForChild("PlayerGui"))
	trove:Add(ui, "destroy")

	local model = prompt:FindFirstAncestorOfClass("Model")
	local highlight: Highlight? = nil
	if model then
		local created = Instance.new("Highlight")
		created.Name = "InteractionHighlight"
		created.FillTransparency = 0.85
		created.OutlineTransparency = 0.2
		created.FillColor = Color3.fromRGB(255, 220, 140)
		created.OutlineColor = Color3.fromRGB(255, 236, 190)
		created.DepthMode = Enum.HighlightDepthMode.Occluded
		created.Adornee = model
		created.Parent = model
		trove:Add(created)
		highlight = created
	end

	trove:Connect(prompt.AncestryChanged, function(_, parent)
		if parent == nil then
			hidePrompt(prompt)
		end
	end)
	trove:Connect(InputController.InputKindChanged :: any, function()
		ui:setKeyGlyph(InputController.getInteractGlyph())
	end)

	active[prompt] = { ui = ui, highlight = highlight, trove = trove }
end

function InteractionController.Init()
	ProximityPromptService.PromptShown:Connect(function(prompt)
		showPrompt(prompt)
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		hidePrompt(prompt)
	end)
	ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
		local entry = active[prompt]
		if entry then
			entry.ui:setHolding(true)
		end
	end)
	ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
		local entry = active[prompt]
		if entry then
			entry.ui:setHolding(false)
		end
	end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local entry = active[prompt]
		if entry then
			entry.ui:setHolding(false)
		end
		AudioController.play("UIClick")
	end)

	ClientState.PlayingChanged:Connect(function(playing)
		if not playing then
			for prompt in active do
				hidePrompt(prompt)
			end
		end
	end)
end

return InteractionController
