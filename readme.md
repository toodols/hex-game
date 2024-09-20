# Hex Game (name subject to change)

A simultaneous turn-based strategy game on a hexagon grid with an emphasis on logistics, symmetry, and determinism in Roblox.

## Buildings

[Current Buildings](./buildings.md)

## System

Vertices (`wires`) on the same team connect with other Vertices on neighbor cells to form a system. A system shares production and inventory.

## Entity Promotion

### Blueprint

Blueprints are created during decision phase and are not visible to enemy teams. They have an associated cost that is absorbed from neighboring systems to be fulfilled. Once it is fulfilled, it is promoted to a scaffold.

### Scaffold

Scaffolds are visible to enemy teams. They are not functional. They have an associated build time, unless the build time is 0, then they are instead immediately promoted to complete.

### Complete

Completed entities are functional.

## Entity Decay

Entities not connected to a Monarch undergoes decay. While undergoing decay, entities cannot be queued for deconstruction. After 3 turns, this entity becomes neutral, and may be captured by any team by building a wire on it.
