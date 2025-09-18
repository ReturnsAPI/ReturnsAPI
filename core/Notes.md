If you have any questions just ping `@Klehrik`.

##### Static Method Closures
- Static methods that have `NAMESPACE` (all caps) as the first argument will always have the user's namespace passed in.
    - The user cannot change this argument (argument is all caps internally to show this).
- *Otherwise*, if the method has `namespace` (*not* all caps) as any argument will allow the user to pass in an optional namespace.
    - If they do not, their namespace will be passed in.
    - This should always be the second-last argument, followed by `namespace_is_specified`, which is `true` if the user passed in an optional namespace.

##### Class Arrays
- `6_General/Class.lua` already provides base implementations for each "class array", which includes:
    - `Property` (enum)
    - `find` (static method)
    - `find_all` (static method)
    - `wrap` (static method)
    - `print_properties` (instance method)
    - Metatable for `get`/`set`
- You do not need to write bodies for these in their `<class>.lua` files, but should still write the documentation.
    - See `7_Class_Arrays/Item.lua` as an example (and perhaps just copy the file).