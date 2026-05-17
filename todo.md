# Todo
- [ ] Display scores in player list
- [ ] Items in inventories with incompatible filters should be moved to different inventories
- [ ] `witness` should indicate its charges
- [ ] Add `flail`, an artillery-type building
	- [ ] Warning indicator entity 
- [ ] Add `exclusion`, creates a fog that blocks visibility or building for enemy
- [ ] `vault` has passive that blocks lethal damage by consuming items in its inventory
- [ ] Finish implementation of tutorial
- [ ] Add actual preview for ItemsFilterPreview
- [ ] Split `client/ui/game/entity_information`
- [ ] Show the system a cell is part of in ui
- [ ] Show the items and income for the system in that turn
- [ ] Spectator starts off with no visibility
	- Visibility can be granted or revoked by player teams
- [ ] `host` A building that can control time
- [ ] `empath` An offensive building that copies status effects of buildings it kills
- [ ] Change entity_update to use entity_id when adding to queue, then fill with entity at serialization step
- [ ] Find a better name for serializing and structures (or merge them)

# Ongoing
- [ ] `terminal` A building that can allow buildings to "fast travel"
	- [x] New entity status `lock`
- [ ] Entities get respective buffs while on a resource tile
	- [x] Vit: Passive Healing
- [ ] Add settings menu 
	- [x] with configurable keybinds
	- [ ] and configurable UI scales
- [ ] Add keybinds for ui
	- [ ] keybind labels should float (use react portals)
- [ ] Unlock system that unlocks new buildings with each win
	- [ ] Conclusion should show a selection of new buildings to choose from

# Complete
- [x] Make `impression` functional
	- [x] Add `infected` status effect
- [x] `torch` a building that can illuminate areas
- [x] Make `suggestion` functional
- [x] `scout` should physically turn to face its target when attacking
- [x] Remove power from the game. It's too complicated.
- [x] Make `phony` functional
- [x] Split `server/router`
- [x] Make `taunt` functional
	- [x] Range should be extendable by proxy
- [x] Building cards in expanded view should expand horizontally when hovered
- [x] Improve map generation to be less random or add handmade maps
- [x] Add an end screen when only one team is left
	- [x] then send players to lobby