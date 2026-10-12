--!strict
--[[
	MenuController
	--------------
	Title screen on join, pause menu afterwards. Opening the menu switches
	the game into "menu" mode (cinematic camera, controls disabled, HUD
	hidden); resuming blends back into third person.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local ClientState = require(script.Parent.Parent.State.ClientState)
local MainMenu = require(script.Parent.Parent.UI.MainMenu)
local AudioController = require(script.Parent.AudioController)
local CameraController = require(script.Parent.CameraController)
local InputController = require(script.Parent.InputController)

local MenuController = {}

local player = Players.LocalPlayer
local menu: MainMenu.MenuUI? = nil
local announcedReady = false

local function openMenu(mode: "Main" | "Pause")
	local ui = menu
	if not ui then
		return
	end
	ui:show(mode)
	CameraController.setCursorFree("Menu", true)
	ClientState.setPlaying(false)
	if mode == "Pause" then
		AudioController.play("UIOpen")
	end
end

local function closeMenu()
	local ui = menu
	if not ui then
		return
	end
	ui:hide()
	CameraController.setCursorFree("Menu", false)
	CameraController.setCursorFree("UserToggle", false)
	ClientState.setPlaying(true)
	AudioController.play("UIClick")
	if not announcedReady then
		announcedReady = true
		Remotes.getEvent(Remotes.Events.ClientReady):FireServer()
	end
end

function MenuController.Init()
	local playerGui = player:WaitForChild("PlayerGui")
	local ui = MainMenu.create(playerGui)
	menu = ui

	ui.PlayPressed:Connect(closeMenu)

	InputController.ActionBegan:Connect(function(action)
		if action ~= "Menu" then
			return
		end
		if ClientState.isPlaying then
			openMenu("Pause")
		elseif ClientState.hasPlayed then
			closeMenu()
		end
	end)
end

function MenuController.Start()
	openMenu("Main")
end

function MenuController.isOpen(): boolean
	local ui = menu
	return ui ~= nil and ui:isVisible()
end

return MenuController
