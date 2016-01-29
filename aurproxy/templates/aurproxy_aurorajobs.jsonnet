# Aurora job(s) template for aurproxy
#
# For an example of how to use this, look in demoproxy.jsonnet

local aurora = import "../../lib/aurora.jsonnet";
local units = import "../../lib/units.jsonnet";
local util = import "../../lib/util.jsonnet";

{
  cluster:: error "cluster is required",
  role:: error "role is required",
  environment:: error "environment is required",
  instances:: 1,  # number of nginx/aurproxy tasks

  params:: {
    elb_names: error "elb_names is required",
    registration_source: error "registration_source is required",
    access_key: error "access_key is required",
    secret_key: error "secret_key is required",
  },

  aurproxy_config:: error "aurproxy_config: expected AurproxyConfig",
  nginx_template:: importstr "nginx.conf.template",

  container:: aurora.DockerContainer("docker.example.com/library/aurproxy:1"),

  aurproxy_flags:: {
    config: std.escapeStringBash($.aurproxy_config),
    "management-port": "{{thermos.ports[admin]}}"
  },
  extra_args:: [],

  procs:: {
    writefiles: aurora.Process {
      name: "writefiles",
      cmdline: std.lines([
        "base64 -d > nginx.conf.template <<__EOF__",
        std.base64($.nginx_template),
        "__EOF__",
      ])
    },

    aurproxy_run: aurora.Process {
      name: "aurproxy",
      cmdline: "exec aurproxy run "
               + util.genFlags($.aurproxy_flags)
               + " " + std.join(" ", $.extra_args),
    },

    aurproxy_sync_elb: aurora.Process {
      name: "aurproxy_sync",
      cmdline: "exec aurproxy synchronize"
               + " --registration-source=" + std.escapeStringBash($.params.registration_source)
               + " --registration-class=tellapart.aurproxy.register.elb.ElbJobRegisterer"
               + " --registration-arg=region=" + $.cluster
               + " --registration-arg=elb_names=" + $.params.elb_names
               + " --registration-arg=remove_other_instances=true"
               + " --registration-arg=access_key=" + $.params.access_key
               + " --registration-arg=secret_key=" + $.params.secret_key
               + " --write"
    },

    aurproxy_setup: self.aurproxy_run {
      name: "aurproxy_setup",
      cmdline+: " --setup"
    },

    nginx: aurora.Process {
      name: "nginx",
      cmdline: "exec nginx -c $PWD/nginx.conf",
    },
  },

  tasks:: {
    aurproxy_run: aurora.Task {
      local procs = $.procs,
      name: "aurproxy",
      resources: { cpu: 0.5, ram: 256*units.MB, disk: 1*units.GB },
      processes: [procs.writefiles, procs.aurproxy_setup, procs.aurproxy_run,
                  procs.nginx],
      constraints: aurora.Orders([[ procs.writefiles, procs.aurproxy_setup ],
                                  [ procs.aurproxy_setup, procs.aurproxy_run ],
                                  [ procs.aurproxy_setup, procs.nginx ]]),
    },

    aurproxy_sync_elb: aurora.Task {
      name: "aurproxy_sync",
      resources: { cpu: 0.1, ram: 128*units.MB, disk: 1*units.GB },
      processes: [$.procs.aurproxy_sync_elb],
    }
  },

  jobmap:: {
    local Service = aurora.Service {
      cluster: $.cluster,
      environment: $.environment,
      role: $.role,
      container: $.container
    },

    run: Service {
      name: "aurproxy",

      task: $.tasks.aurproxy_run,
      announce: aurora.Announcer {
        # the aurproxy API port also has the /health endpoint we want.
        # For ELB checks there is a /health on the nginx http port as well.
        portmap: { health: "admin" }
      },
      constraints: { host: "limit:1" },
      health_check_config: aurora.HealthCheckConfig {initial_interval_secs: 30},
      instances: $.instances,
    },

    sync: Service {
      service: false,
      name: "aurproxy-sync",
      task: $.tasks.aurproxy_sync_elb,
    }
  },

  jobs: util.objectValues(self.jobmap),
}
