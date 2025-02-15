#### Wrapper Metatables
- All wrapper metatables must have cases for the `__index` key being `value` or `RAPI`.
    - `value`   Return the value stored in the wrapper.
    - `RAPI`    Return `true`.

#### Namespace Binding
- If a method has `namespace` as its first argument, the user *cannot* change it.
- If a method has `namespace` as a later argument, the user *can* pass in one optionally.
    - `namespace` *must* be the second-last argument, followed by `default_namespace` last.

#### Public Reference Population
- All classes should add themselves to `_CLASS` in their file.
    - If the class table itself has a metatable, that should be added to `_CLASS_MT`.