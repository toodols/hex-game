# Todo

- [ ] Display scores in player list
- [ ] Add an end screen when only one team is left, then send players to lobby
- [ ] Improve map generation to be less random or add handmade maps
- [ ] Items in inventories with incompatible filters should be moved to different inventories
- [ ] Make `suggestion` functional
- [ ] Buildings get different buffs while placed on any of the deposits
- [ ] Remove `turret`. It's too generic.
- [ ] `witness` should indicate its charges
- [ ] `torch` a building that can illuminate areas
- [ ] Add `mace`, an artillery-type building
	- [ ] Warning indicator entity 
	- [ ] Mace occupies 3 tiles?
- [ ] Add `exclusion`, creates a fog that blocks visibility or building for enemy
- [ ] `vault` has passive that blocks lethal damage by consuming items in its inventory
- [ ] Systems should be visible to the client and should show total items
- [ ] Finish implementation of tutorial
- [ ] Add actual preview for ItemsFilterPreview
- [ ] Make lobby ui look better
- [ ] Split `client/ui/game/entity_information`
- [ ] Add keybinds for ui

- [ ] Spectator starts off with no visibility
	- Visibility can be granted or revoked by player teams

- [ ] `host` A building that can control time
- [ ] `sanction` A mine-like building that detonates when built over it
- [ ] `empath` An offensive building that copies status effects of buildings it kills
- [ ] `pocket` A building that can allow buildings to "fast travel"

# Ongoing
- [ ] Make `impression` functional
	- [x] Add `infected` status effect
- [ ] Entities get respective buffs while on a resource tile
	- [x] Vit: Passive Healing
- [ ] Add settings menu 
	- [x] with configurable keybinds
	- [ ] and configurable UI scales

# Complete
- [x] `scout` should physically turn to face its target when attacking
- [x] Remove power from the game. It's too complicated.
- [x] Make `phony` functional
- [x] Split `server/router`
- [x] Make `taunt` functional
	- [x] Range should be extendable by proxy
- [x] Building cards in expanded view should expand horizontally when hovered