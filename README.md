# Jsonnet as a config language for Apache Aurora

(better description forthcoming)

What's in here:

`example/example.jsonnet`- example of a single trivial Aurora job definition

`aurproxy/` - a much more complex example, involving multiple jobs in multiple clusters.

This stuff is still evolving, and the aurproxy example currently needs a patched version of aurora.pex that understands json files with a `{ "jobs": [job1, job2, ...] }` structure.
