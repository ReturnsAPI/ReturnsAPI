##### Namespace Binding
- If a method has `namespace` as its first argument, the user *cannot* change it.
- If a method has `namespace` as a later argument, the user *can* pass in one optionally.
    - `namespace` *must* be the second-last argument, followed by `default_namespace` last.