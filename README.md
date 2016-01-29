# Jsonnet as a config language for Apache Aurora

(better description forthcoming)

What's in here:

| file                                             | description |
| ------------------------------------------------ | ----------- |
| `example/example.jsonnet`                        | example of a single trivial Aurora job definition |
| `aurproxy/`                                      | a much more complex example, involving multiple jobs in multiple clusters. |
| `aurproxy/us-east-1.jsonnet`                     | Job definitions for the aurproxy example in a cluster called us-east-1. |
| `aurproxy/devcluster.jsonnet`                    | Job defs for aurproxy in the "devcluster" cluster. |
| `aurproxy/templates/demoproxy.jsonnet`           | Service template that the above two files invoke. It imports the base aurproxy templates and configures a frontend service with various vhosts and backends, plus a second job keeping a loadbalancer in sync with the running backends. |
| `aurproxy/templates/aurproxy_config.jsonnet`     | structural templates for aurproxy's own configuration (it takes a giant json blob as a commandline argument, and we can generate it using jsonnet!) |
| `aurproxy/templates/aurproxy_sources.jsonnet`    | more aurproxy config templates, specifically for various types of backend sources. |
| `aurproxy/templates/aurproxy_aurorajobs.jsonnet` | Unconfigured template of an aurproxy service. |
| `aurproxy/templates/nginx.conf.template`         | A config file used by aurproxy; it is delivered verbatim into the job sandbox. |

This stuff is still evolving, and the aurproxy example currently needs a patched version of aurora.pex that understands json files with a `{ "jobs": [job1, job2, ...] }` structure.
