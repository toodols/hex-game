No one is ever going to read this but I'm going to keep it for my sanity.

# April 29, 2025
I wasted more hours of my life tracking down an obscure bug where an entity instance was not getting destroyed. It turned out it was a combination of 3 innocuous factors:
1. Updates aren't fully processed instantly. In a previous update I added death animations, and to stagger these death animations I sprinkled a bunch of waits (cause it was convenient for me)
2. At the end of each update, all entities that are marked as is_destroyed gets "detached" from world.entities, world.entity_instance_map. However, it does not physically destroy the instance (I forgot to or thought I wouldn't need to).
3. After each action phase, two update "batches" are sent to the client, and these run in parallel because of how remotes work.

So what ends up happening is, if I shoot down a building (say scout) + its underlying vertex, at the end of each action phase, the server tells the client that these two buildings died, and in a separate update batch tells them the timer has reset.
1. The client processes the first update batch, it reaches the update instances step, calls on_destroy for the scout, and it plays the animation.
2. This animation, which takes 0.1 seconds, yields the thread, and the vertex is not immediately destroyed 
3. At the same time, the client starts to process the second update batch, which is just updating the timer.
4. Second update batch happens instantly, but it still calls purge_destroyed_entities at the very end.
5. The vertex, whose destroy animation hasn't been played yet, gets its instance detached from the world. 
6. The first thread resumes after 0.1 seconds, and now tries to play destroy animation on vertex.
7. Uh oh! It already detached the vertex instance from the second thread, and now it can't find the instance to play the animation on.
8. Since it can't find the instance, it skips the destroy animation, and the instance is just left there

Alas, the infamous race condition has shown itself in my roblox game.

Why am I writing a blog instead of fixing it? After all, I have to deal with stupid bugs like these on a daily basis. I realize that there's not many easy options for me to patch this. Currently I have 3 changes I would need to make.

1. purge_destroyed_entities should just destroy the instance if it wasn't destroyed as a fail-safe. **done**
2. Updates strictly happen in sequence, no more parallelism. **This will be a bit of a pain to do**
3. handle_updates runs instantly, and animations run in a separate thread. **This sounds like a giant pain to do and I don't want to do it**

Any one of these changes would fix these bugs but for full correctness I would need to do all of them. I think the moral of the story here is if you ever get lazy for one moment and dare to add wait()s even for prototyping, you are staring down the barrel of a host of ridiculous bugs like these.

# April 15, 2025
I've had a lot of issues with dependencies since Roblox won't allow cross requiring.
For example, damage_mod depends on entity_mod (nigh everything depends on entity_mod) which depends on every entity's implementation, which in turn depends on effect_mod, which depends on every effect's implementation, and something like poison would depend on damage_mod. Thus, a cycle.

Thinking about it, this does make sense, very often I need one part of code to trigger another, but this is a nightmare to organize. 
Previously I had a submodule called "methods" and "registry" under entity which other modules could directly require.
All the entity implementations would append themselves onto the registry. No dependency issues!
I thought it was a smart idea, for a time, but it becomes really hard to keep track of which module depends on which.
Ideally, all dependencies form a directed acyclic graph, and all modules either depend on their siblings or their parents.

Today, after messing around, I came up with what I think is a reasonable solution.
I separate all the base methods (new_entity, remove_entity) into a separate module "entity" from all the implementations (vertex, extractor, stockpile) "entities". 

It's sometimes worrying if I'm just rearranging my files around with no progress being made.
Work on this project is ultimately a learning experience, and I guess I still need to get the hang on my code structure.
Thus, I want to formalize the guidelines for how I write code so I can do it consistenly without these sorts of problems popping up.
1. Modules may only depend on siblings, children, or modules at the top level (client, server, shared)
2. Modules must always return an immutable dictionary
3. For all implementation files, code must be organized into
	1. Service imports
	2. Dependencies from shared
	3. Dependencies from server
	4. Dependencies from client
	5. Dependencies from siblings
	6. Dependencies from children
	7. Module item aliases
	8. Type dependencies
		1. Shared types
		2. Server types
		3. Client types
	9. Constant/immutable declarations
	10. Functions
	11. Export
4. `local method = require(...).method` may only be used if the module has exactly one export.
All other requires must follow the format `local module = require(...)`
5. All functions must have type annotations in the parameters and the return type, unless it returns nil.
6. Any time `func(...)` can be rewritten as `func ...`, it must.
7. A check against a nil must always use == or ~=.

	Example: let `foo: T?`
	- Do: `if foo == nil then ... end`
	- Do not: `if not foo then ... end`
8. Ternaries of the form `a and b or c` are illegal in favor of `if a then b else c`
9. Variable Cases
	- All user variables use snake_case
		- Unless it is a react component, then it will use PascalCase
	- All user types use PascalCase
	- All user table keys use snake_case
	- Unless they correspond directly to an api/library item, then it will copy that item's name.
		- Ex: Players, React, LayoutOrder
10. No OOP allowed.

These rules are only being followed like 70% so it will take a while to clean up my code.