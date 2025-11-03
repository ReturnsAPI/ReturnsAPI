**Still an active work in progress, although it is mostly done.**

API for modding [*Risk of Rain Returns*](https://store.steampowered.com/app/1337520/Risk_of_Rain_Returns/).  
Documentation can be found on the [wiki](https://github.com/ReturnsAPI/ReturnsAPI/wiki).  

Include `ReturnsAPI-ReturnsAPI-0.1.32` as a dependency in `manifest.json`, and import it with:  
```lua
-- Automatically adds class references directly to your mod,
-- and performs other actions (such as autoregistering for language loading)
mods["ReturnsAPI-ReturnsAPI"].auto()

-- or

-- Stores class references in a variable
local RAPI = mods["ReturnsAPI-ReturnsAPI"].setup()

-- See the Importing page for additional properties you can pass:
-- https://github.com/ReturnsAPI/ReturnsAPI/wiki/Importing
```

Uses [ReturnOfModding](https://thunderstore.io/c/risk-of-rain-returns/p/ReturnOfModding/ReturnOfModding/) as the base mod loader.  
Successor to [RoRR Modding Toolkit](https://thunderstore.io/c/risk-of-rain-returns/p/RoRRModdingToolkit/RoRR_Modding_Toolkit/).  

---

### Installation Instructions
Install through the Thunderstore client or r2modman [(more detailed instructions here if needed)](https://return-of-modding.github.io/ModdingWiki/Playing/Getting-Started/).  
Join the [Return of Modding server](https://discord.gg/VjS57cszMq) for support.  