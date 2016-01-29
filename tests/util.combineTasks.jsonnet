local aurora = import "../lib/aurora.jsonnet";
local util = import "../lib/util.jsonnet";

local proc1 = aurora.Process {name: "process1", cmdline: "foo"};
local proc2 = aurora.Process {name: "process2", cmdline: "bar"};
local proc3 = aurora.Process {name: "process3", cmdline: "bar"};

local taskA = aurora.Task {
  name: "taskA",
  processes: [ proc1 ],
  resources: { cpu: 0.1, ram: 111, disk: 222 }
};

local taskB = aurora.Task {
  name: "taskB",
  processes: [ proc2, proc3 ],
  resources: { cpu: 0.3, ram: 222, disk: 333 },
  constraints: [ aurora.Order([proc2, proc3]) ],
};

local expected = aurora.Task {
  name: "taskA",
  processes: [ proc1, proc2, proc3 ],
  resources: { cpu: 0.4, ram: 333, disk: 555 },
  constraints: [ aurora.Order([proc2, proc3]) ]
};

std.assertEqual(util.combineTasks(taskA, taskB), expected)
