# Example that produces a single aurora job

local aurora = import "../lib/aurora.jsonnet";
local units = import "../lib/units.jsonnet";

# some shorthand:
local myproc(name, cmd) = aurora.Process { name: name, cmdline: cmd };

aurora.Job {
  name: "example",
  role: "vagrant",
  cluster: "us-east-1",
  environment: "devel",

  task: aurora.Task {
    name: "example",
    resources: {ram: 64*units.MB, cpu: 0.2, disk: 1*units.GB},
    processes: [
      myproc("demo", "python -m SimpleHTTPServer {{thermos.ports[http]}}")
    ]
  }
}
