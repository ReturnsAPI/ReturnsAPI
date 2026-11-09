-- MonsterCard



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE           0
IDENTIFIER          1
SPAWN_TYPE          2
SPAWN_COST          3
OBJECT_ID           4
IS_BOSS             5
IS_NEW_ENEMY        6
ELITE_LIST          7
CAN_BE_BLIGHTED     8
]]


--@enum
MonsterCard.SpawnType = {
    CLASSIC = 0,
    NEARBY = 1,
    OFFSCREEN = 2,
    ORIGIN = 3
}


--@enum
MonsterCard.DissonanceType = {
    BASIC = 1,
    STRONG = 2,
    BOSS = 3,
    NONE = 4
}




-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The monster card ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                     | string    | The namespace the monster card is in.
`identifier`                    | string    | The identifier for the monster card within the namespace.
`spawn_type`                    | number    | 
`spawn_cost`                    | number    | 
`object_id`                     | number    | 
`is_boss`                       | bool      | 
`is_new_enemy`                  | bool      | 
`elite_list`                    |           | 
`can_be_blighted`               | bool      | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   MonsterCard
--@param    identifier  | string    | The identifier for the card.
--[[
Creates a new card with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
MonsterCard.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started("MonsterCard.new")
    if not identifier then log.error("MonsterCard.new: No identifier provided", 2) end

    -- Return existing card if found
    local card = MonsterCard.find(identifier, NAMESPACE, true)
    if card then return card end

    -- Create new
    card = MonsterCard.wrap(gm.monster_card_create(
        NAMESPACE,
        identifier
    ))

    return card
end


--@static
--@name         find
--@return       MonsterCard or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified monster card and returns it.

--@findinfo
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`MonsterCard.Property.NAMESPACE` | MonsterCard#Property} by default.
--[[
Returns a table of monster cards matching the specified filter and property.

**Note on namespace filter:**
--@findinfo

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       MonsterCard
--@param        id          | number    | The monster card ID to wrap.
--[[
Returns an MonsterCard wrapper containing the provided monster card ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_content_class["MonsterCard"], {

    --@instance
    --@name         print
    --[[
    Prints the monster card's properties.
    ]]


    --@instance
    --@return       Instance
    --@param        object      | Object    | The object to set.
    --[[
    Assigns a monster to the card, accounting for boss monsters.
    ]]
    set_object = function(self, object)
        if not object then log.error("set_object: object is not provided", 2) end

        object = Wrap.unwrap(object)
        self.object_id = object
    
        -- Set is_boss if object_id is a boss type
        local is_boss = gm.actor_is_boss(object)
        self.is_boss = is_boss

        -- Set default dissonance type
        local dissonance_list = is_boss and Global._dissonance_monster_card_list_boss or Global._dissonance_monster_card_list_basic
        if not dissonance_list:contains(self.value) and not hotloaded then
            dissonance_list:add(self.value)
        end
    end,


    --@instance
    --@param    dissonance_type | number    | The `MonsterCard.DissonanceType` to set the card to.
    --[[
    Adds the monster card to the corresponding dissonance list.
    ]]
    set_dissonance_type = function(self, dissonance_type)
        if not dissonance_type then log.error("set_dissonance: dissonance type is not provided", 2) 
        elseif type(dissonance_type) ~= "number"
        or dissonance_type > 4 or dissonance_type < 1 then
            log.error("set_dissonance: dissonance type is invalid", 2) 
        end
        
        local dissonance_lists = {
            Global._dissonance_monster_card_list_basic,
            Global._dissonance_monster_card_list_strong,
            Global._dissonance_monster_card_list_boss
        }
        for dissonance_index, dissonance_list in ipairs(dissonance_lists) do
            if dissonance_index ~= dissonance_type then
                if dissonance_list:contains(self.value) then
                    dissonance_list:delete_value(self.value)
                end
            elseif not dissonance_list:contains(self.value) then
                dissonance_list:add(self.value)
            end
        end
    end,

})
