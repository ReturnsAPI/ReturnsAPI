- Maybe come up with standardized behavior for `find` and `find_all`
- Should probably move callback/hook priority to be second-last arg
    - More visible

Object serialization
- self:instance_sync() - setup (in on create or whatever)
- self:instance_resync() - resync
- self:projectile_sync(interval) - same as resync but with automatic periodic resync
- self:instance_destroy_sync() - sync destruction

- item on acquired runs for both host and clients
    - write this down in docs desc too
    - i think all content callbacks do actually