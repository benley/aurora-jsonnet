# Handy helpers and such

local aurora = import "aurora.jsonnet";

{
  local util = self,

  # Generate a cluster.role.env.jobname.job filename for an aurora Job
  jobFilename(job)::
    std.join(".", [job.cluster, job.role, job.environment, job.name, "job"]),

  # Given a list of Jobs, produce a { "jobFilename": <thejob> } mapping
  # suitable for rendering with `jsonnet -m`
  jobsToFiles(jobs)::
    local jtype = std.type(jobs);
    { [util.jobFilename(x)]: x for x in
        if jtype == "array" then jobs
        else if jtype == "object" then util.objectValues(jobs)
        else error "unhandled type"
    },

  # Generate "--foo bar" style commandline flags (argparse, gflags, go, etc)
  genFlags(args)::
    std.join(" ", (["--%s %s" % [x, args[x]] for x in std.objectFields(args)])),

  # Return a list of values from an object
  objectValues(obj)::
    [obj[x] for x in std.objectFields(obj)],

  # Combine two aurora.Task objects, summing their resource requirements.
  combineTasks(a, b)::
    local _new = aurora.Task + b + a;
    _new + {
      processes: a.processes + b.processes,
      resources: util.combineResources(a.resources, b.resources),
      # If neither input has constraints, nor should the combined task.
      [if std.objectHas(_new, "constraints") then "constraints"]:
        (if std.objectHas(a, "constraints") then a.constraints else [])
        + (if std.objectHas(b, "constraints") then b.constraints else []),
    },

  // TODO(bstaffin):
  # concatTasks(a, b):: local _new = aurora.combineTasks(a, b); _new + {
  #   constraints: ...
  # },

  # Combine two Resources objects
  combineResources(a, b):: {
      cpu: a.cpu + b.cpu,
      ram: a.ram + b.ram,
      disk: a.disk + b.disk,
    },

  # Generate a shell cmdline that writes out a file.
  echoToFile(filename, content)::
    "echo %(content)s > %(filename)s\n" % {
      content: std.escapeStringBash(content),
      filename: std.escapeStringBash(filename)
    },

  # Generate a Process definition that writes out a file.
  writeFileProc(filename, content)::
    aurora.Process {
      name: "writefile",
      cmdline: util.echoToFile(filename, content)
    },
}
