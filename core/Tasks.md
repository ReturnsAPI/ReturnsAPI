v Make all class tables and metatable stuff not reinitialize on hotload; instead just append new changes via Util.table_append
    - Better for hotloading imo
- Fix Hook class breaking hotloading
- Damage modification method; either midhook `damager_calculate_damage` or add some "preHit" construct
- Remaining Actor instance methods
- Custom object net serialization
    - Custom interactables(?); not sure if it still needs to be its own thing
- Classes
    - Equipment
    - Achievement

    - Stage
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