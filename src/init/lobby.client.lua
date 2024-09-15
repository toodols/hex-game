local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local init_lobby_ui = require(ReplicatedStorage.Client.ui.lobby).init_ui

init_lobby_ui()
