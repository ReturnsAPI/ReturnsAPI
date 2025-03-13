#### Wrapper Metatables
- All wrapper metatables must have cases for the `__index` key being `value` or `RAPI`.
    - `value`   Return the value stored in the wrapper.
    - `RAPI`    Return `getmetatable(t):sub(14, -1)`.
- `__metatable` should be `RAPI.Wrapper.<name>`.
    - If the metatable is for the class table itself, it should be `RAPI.Class.<name>`.

#### Namespace Binding
- If a method has `namespace` as its first argument, the user *cannot* change it.
- If a method has `namespace` as a later argument, the user *can* pass in one optionally.
    - `namespace` *must* be the second-last argument, followed by `default_namespace` last.

#### Public Reference Population
- All public classes should add themselves to `_CLASS` in their file.
    - If the class table itself has a metatable, that should be added to `_CLASS_MT`.

#### Private Methods (for internal use)
- `new_class()` (found in `Internal.lua`) simply returns a table with a subtable called `internal`.
    - Place internal methods (i.e., that may be used by other files) within `internal`; these will *not* get exported in `envy.lua`.
    - This is just to give these methods clearer names when used elsewhere.

#### Class Array Setters
- Only add a setter if it does multiple things, otherwise the user should just set properties directly.

#### gmf
- Even though `GM` exists now, it is only around ~3x faster than `gm`.
    - Basically it's only for users.
- Internally, you should still be creating RValue holders and calling `gmf` directly, which is a *lot* faster.