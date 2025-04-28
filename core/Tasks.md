v Make all class tables and metatable stuff not reinitialize on hotload; instead just append new changes via Util.table_append
    - Better for hotloading imo
v Fix Hook class breaking hotloading
v Damage modification method; either midhook `damager_calculate_damage` or add some "preHit" construct
- Remaining Actor instance methods
- Custom object net serialization
    - Custom interactables(?); not sure if it still needs to be its own thing
~ Make __ref_map gc not happen all at once; right now there is a lag spike for 1 frame
    - Spreading out __ref_map removal doesn't actually help since the main bottleneck seems to not be there
v Make Instance find_all, is_colliding, and get_collisions work with custom objects
    ~ Make Instance.find_all faster(?) by midhooking `_mod_instance_findAll` and redirecting outputs to a table instead of nowhere (i.e., "`mod_push_value`")
        - This is actually way slower nvm
~ Colon syntax for Script; figure out a method to support self/other-less calling too? idk
    ~ Can still keep Script wrappers as separate objects, but "bind" some as closures
    v Solution: On getting method from struct, auto"bind" the struct to self/other of the wrapper
- Change Hook to take in gm.constants instead of strings (maybe)
- Figure out every Callback arg, and also write if it runs for host-only, etc.
- In docs, also write list of general variables for instances, etc.
    - Also list useful GM functions
- Hook : disable dynamic hooks that are not actually in use anymore (i.e., all callbacks removed)
- Classes
    v Equipment
    - Achievement

    ~ Stage
    - EnvironmentLog
    
    - InteractableCard
    - MonsterCard

    - MonsterLog
    - Elite
    
    - Artifact
    - Difficulty
    - GameMode

    - Ending

    - Skill
    - State
    - Survivor
    - SurvivorLog
    - ActorSkin