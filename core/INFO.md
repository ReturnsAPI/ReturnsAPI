### Conventions
- Globals should be stored in `G`
- Persistent globals (not be reinitialized on hotload) should be stored in `P`
- Classes are PascalCase; public ones should be added to `C`
    - Should be created using `new_class()`
    - Each class has an `internal` table, which houses functions that are not publicly exported

### Notes

In many files, these will be present:
```lua
local proxy = P.proxy
local metatable
```
This is because local upvalues are faster to access than global table indexes (minor optimization)