### v0.1.27
- Callback : Allow modifying `result`

### v0.1.26
- Survivor : Fix error thrown on death for custom survivors
- Instance : Add error messages if arg is `nil` for `find`, `find_all`, and `count`
- Object : Fix sometimes returning `nil` when passing in `"ror"` namespace

### v0.1.25
- Instance
    - Getter/setter will now return `nil` for invalid instances (with `value` of `nil`)
        - This is only really relevant to the weird case of a CInstance having an id of 0; <br>otherwise you should still be checking `Instance.exists()`
    - Make `is_colliding` work with specific instances

### v0.1.24
- Achievement
    - Add `Kind` and `Group` enums
    - Add `set_unlock_skill`

### v0.1.23
- (Internal) Item, Buff : Fix error that may be thrown by `actor_transform` hooks
- ModOptionsKeybind : Add controller support (also fixes a crash)

### v0.1.22
- Map : Add `print`
- Language : Fix some files not being loaded

### v0.1.21
- Actor
    - Add `apply_dot`
    - Add `heal_barrier`
    - Remove `heal_networked` and moved functionality to `heal`

### v0.1.20
- Hook, Callback : `add` methods now return wrappers instead of IDs
    - Can call `remove`, `is_enabled`, and `toggle(bool)` through them
- Hook : Disable internal script_hook if no hook functions of that type exist

### v0.1.19
- Artifact : Rename `loadout_sprite_id` and `pickup_sprite_id` to `sprite_loadout_id` and `sprite_pickup_id` to match consistency with everything else
- Packet : Fix packet syncing throwing an error

### v0.1.18
- Initial build uploaded to Thunderstore
- ModOptionsKeybind : Add alternating background styling
- Initialize : Add `add_hotloadable`
- Remove garbage data from `class_artifact`
- Artifact : Add `new`
- Fix `new_from_*` methods not working when using the same identifier as existing content
- Instance : Add `get_collisions_rectangle` and `get_collisions_circle`

### v0.1.17
- ModOptionsKeybind : Fix `press` and `release` not working in menus

### v0.1.16
- Instance : Make `wrap` and `.id` slightly more efficient
- Add ActorSkill struct wrapper, and related skill-getting methods to Actor
- Add ModOptionsKeybind
    - Still some stuff to tidy up but it's functional for keyboard
- Player : Add `control`

### v0.1.15
- Actor : Fix `fire_direct` throwing an error as a result of last build

### v0.1.14
- Instance.wrap : Wrap CInstance as `value` instead of id
- Buffer : Add `write/read_bool`

### v0.1.13
- Alarm : Add `add_nopause`
- Add HUD draw callback fix
- Fix something related to packet syncing
    - `packet` in `ON_NET_MESSAGE_RECEIVE` will now be `nil` if the packet ID is not in use

### v0.1.12
- Packet : Sync packet IDs based on identifiers; `new` now requires an identifier
- Add Achievement stuff; content classes now have `get_achievement`, returning an Achievement

### v0.1.11
- Packet : Add support for clients calling `send_to_all`
- List, Map : Fix construction from table not working
- Packet : Log which mod added which packet in console

### v0.1.10
- Hook : Add ban on certain functions
- Add toggle to disable online button block
- Object : Fix object serialization
- Some documentation updates

### v0.1.9
- Rename File to TOML for less ambiguity 
- Hook : Add support for `code_execute` hooks

### v0.1.8
- Player : Fix `get_local` throwing an error instead of returning an invalid instance when there's no player
- (Internal) CallbackCache : Fix `remove` throwing an error in some cases
- Add File helper class

### v0.1.7
- Item, Equipment : Add `is_loot`, `toggle_loot`, `get_loot_pools`, `get_available_loot_pools`
- Sprite, Sound, Particle : Add gettable `namespace` and `identifier` properties
- LootPool : Add ability to modify command crate spawn info
- Some documentation additions

### v0.1.6
- Add ModOptionsDropdown
- Sprite, Sound, Particle : Fix `find_all`
- Fix `new` not working when using the same identifier as existing vanilla content

### v0.1.5
- Actor, Player : Add `_eq` metamethod
- Hook : Fix `args` modification related error in pre-hook
- Hook : Fix hooks being added twice until RAPI is hotloaded
- Make online mp mod compatibility check display in all languages

### v0.1.4
- Util : Fixed some incorrectly displayed values in `log_hook`

### v0.1.3
- Hook : Change `args[i]` to `args[i].value` to maintain consistency with gm script hooks
- Util : Make `log_hook` work with Hook class

### v0.1.2
- Math : Add `lerp`
- Add Hook

### v0.1.1
- Stage : Prevent `add_` methods from adding duplicate cards
- InteractableCard, MonsterCard : Add `new`

### v0.1.0
- Initial build uploaded to server