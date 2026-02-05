### v0.1.44
- Add Timer class
- AttackFlag : Add `new` and `find`
- AttackInfo : Add support for custom attack flags
- Callback : Add `add_SO`
- Instance
    - Add `nearest`
    - Add `INVALID` constant; maps to the invalid instance with value `nil` and id `-4`
- ItemLog.`new_from_equipment` : Correctly add +1 to group if achievement-locked
- Particle : Remove `get_identifer` (why did this exist?)
- Survivor
    - Add `add_skin`
    - Add `Class` enum
- Sound : Add `play_synced`
- Sprite : Add `.width`, `.height`, and `.subimages` getters to wrapper
- Util : Add `table_print`
- Vector : Fix `.direction` throwing error

### v0.1.43
- Survivor : Set `pHmax_base` to `2.8` on init

### v0.1.42
- Actor : Add `buff_time`
- Util
    - Add `set`
    - Add `enum`
- Player:`control`
    - Fix not working for vanilla verbs
    - Fix incorrect description for release (should be `-1`)
- ActorSkill : Add wrapper methods around struct methods
    - Use `:` instead of `.`
    - Add argument checking
    - Add default args to `add_stock` and `remove_stock`
    - Reimplement `override_cooldown` to always work

### v0.1.41
- Restore Sniper spotter crit damage number fix
- Restore better RecalculateStats API from in-dev RAPI

### v0.1.40
- Callback
    - `Callback.ON_HEAL`
        - Fix not being called for effects that use `lifesteal` (e.g., Leeching Seed)
        - Fix not being called for effects that use `oEfHeal2Nosync` (e.g., Monster Tooth)
    - Add `has_any`

### v0.1.39
- Util : Replace `get_namespace` with `get_mod_info`
- Prevent using the same namespace as another mod

### v0.1.38
- Script : Add `.script_name` as an alias for `.name`
- Stage : Add safety checking to \*Card-related methods + error for invalid string identifiers
- TOML.`new` : Add optional `directory` argument
- Util : Add `get_namespace`

### v0.1.37
- Internal changes
    - Instance : Remove cached wrappers on room change
    - Net : Cache net status when entering a run
    - Item, Buff : Remove client from `get_holding_actors` on disconnect
- Item, Buff : Make `get_holding_actors` return `{}` while paused in a singleplayer run

### v0.1.36
- Instance : Revert change from previous patch

### v0.1.35
- Prevent Commando and Huntress auto-unlocked achievements from appearing as popups
- Instance : Fix strange issue where getting variables sometimes returned an incorrect value
    - This happens because CInstances stored in a variable sometimes return different values when accessing a variable via `cinst.var` vs `gm.variable_instance_get(cinst, var)` (?)
- Display version number under RoM's on the title screen

### v0.1.34
- EffectDisplay.`DrawPriority` : `PAST` -> `POST`
- Callback
    - Add `Callback.ON_SHIELD_BREAK`
    - Add `Callback.ON_SKILL_ACTIVATE`
    - Add `Callback.ON_EQUIPMENT_SWAP`

### v0.1.33
- Actor : Fix `fire_*` methods not accepting Sprite wrappers
- Hook : Add `actor_heal_raw` to banlist for potential lag
- Callback : Add support for custom callbacks
    - Add `Callback.ON_HEAL`

### v0.1.32
- Actor : Fix `heal` crashing for host in multiplayer

### v0.1.31
- Script : Wrap args before passing to binded functions
    - This affects EffectDisplay
- Add Commando and Huntress auto-unlocked achievements for organization
    - `"unlock_commando"` and `"unlock_huntress"` (`"ror"` namespace)

### v0.1.30
- Util.`print` : Remove random extra `nil` that was tacked on

### v0.1.29
- ItemLog.`new_from_item` : Add +1 to group if item is achievement-locked
- Util
    - Table-related methods : Add `t` `nil` check
    - `print` : Display as called from calling mod instead of `ReturnsAPI-ReturnsAPI`

### v0.1.28
- Stage
    - Make `set_title_screen_properties` `objs_*` args actually optional
    - Automatically call `remove_all_rooms` on hotload

### v0.1.27
- Callback : Allow modifying `result` via return value
- SurvivorLog : Fix "Max Health" not displaying correctly when calling `new_from_survivor`
- Instance : Allow calling object functions with `:`

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