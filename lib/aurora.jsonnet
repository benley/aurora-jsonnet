# Aurora job schema templates

local util = import "lib/util.jsonnet";

{
  local aurora = self,

  Process:: {
    name: error "name is required",
    cmdline: error "cmdline is required",
    #max_failures: 1,
    #daemon: false,
    #ephemeral: false,
    #min_duration: 15,
    #final: false,
  },

  Task:: {
    name: self.processes[0].name,
    processes: error "processes is required",
    #constraints: [],
    resources: aurora.Resource,
    #max_failures: 1,
    #max_concurrency: 0,
    #finalization_wait: 30,

    _combine(other):: util.combineTasks(self, other),
  },

  Constraint:: { order: [] },  # this is silly

  # Generate Constraint orderings from a list of Processes or process names
  Order(procs): aurora.Constraint {
    order: [(if std.type(x) == "string" then x else x.name) for x in procs]
  },

  # Generate Constraint orderings for multiple lists of Processes.
  # e.g. Task { constraints: Orders([[proc1, proc2], [proc3, proc4]]) }
  Orders(orders): std.map(aurora.Order, orders),

  Resource:: {
    cpu: error "cpu is required",
    ram: error "ram is required",
    disk: error  "disk is required",

    _combine(other):: util.combineResources(self, other),
  },

  Job:: {
    task: error "task is required",
    name: error "name is required",
    role: error "role is required",
    cluster: error "cluster is required",
    environment: error "environment is required",
    #contact: null,
    #instances: 1,
    #cron_schedule: null,
    #cron_collision_policy: "KILL_EXISTING",
    #update_config: aurora.UpdateConfig,
    #constraints: null,  # Scheduling constraints, not process orderings
    #service: false,
    #max_task_failures: 1,
    #priority: 0,
    #health_check_config: aurora.HealthCheckConfig,
    #container: null,  # aurora.Container,
    #lifecycle: aurora.LifecycleConfig,
    #tier: null,  # AURORA-1343, AURORA-1443 (revocable resources)

    # Hilariously, these aren't properly documented.
    #announce: null,
    #enable_hooks: false,
  },

  Service:: aurora.Job { service: true },

  UpdateConfig:: {
    batch_size: 1,
    restart_threshold: 60,
    watch_secs: 45,
    max_per_shard_failures: 0,
    max_total_failures: 0,
    rollback_on_failure: true,
    wait_for_batch_completion: false,
    pulse_interval_secs: null,
  },

  HealthCheckConfig:: {
    health_checker: { http: aurora.HttpHealthChecker },
    initial_interval_secs: 15,
    interval_secs: 10,
    max_consecutive_failures: 0,
    timeout_secs: 1,
  },

  HttpHealthChecker:: {
    endpoint: "/health",
    expected_response: "ok",
    expected_response_code: 0,
  },

  ShellHealthChecker:: {
    shell_command: error "shell_command is required"
  },

  Announcer:: {
    local up = self,
    primary_port: "http",
    portmap: { aurora: up.primary_port, },
  },

  Container:: {
    docker: aurora.Docker,
  },

  Docker:: {
    image: error "image is required",
    parameters: [],  # list of DockerParameters
  },

  DockerParameter:: {
    name: error "name is required",
    value: error "value is required",
  },

  DockerContainer(name):: aurora.Container {
    docker: aurora.Docker { image: name }
  },

  LifecycleConfig:: {
    http: aurora.HTTPLifecycleConfig,
  },

  HTTPLifecycleConfig:: {
    port: "health",
    graceful_shutdown_endpoint: "/quitquitquit",
    shutdown_endpoint: "/abortabortabort",
  },
}
