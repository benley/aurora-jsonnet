# demoproxy: Complete aurproxy frontend service
#
# This file evaluates to an Aurora job object.
# Fill in its cluster, role, and environment fields and it's ready to launch.

local AurproxyAurora = import "aurproxy_aurorajobs.jsonnet";
local cfg = import "aurproxy_config.jsonnet";
local src = import "aurproxy_sources.jsonnet";

local portmap_overrides = {
  ### If you want the http port to be statically assigned, do it here.
  ### Leave it commented out for a normal dynamic port.
  # http: 9998
  ### If you do set a static port in the portmap, Aurora will only let you run
  ### on dedicated machines, so make sure to add a constraint to the Job, e.g.
  ### Job {constraints: {dedicated: "foo/bar"}}
};

# Backend job definitions
local sources = {
  asdf: src.AuroraSource {
    cluster: "us-east-1",
    role: "vagrant",
    environment: "test",
    job: "asdf"
  },

  AuroraScheduler: src.ServerSetSource {
    path: "/aurora/scheduler",
    cluster: "us-east-1",
    zk_member_prefix: "member",
  },

  MesosMaster: src.MesosMasterSource { cluster: "us-east-1" },
};

# This just tells thermos to look up the port named http, whether it is chosen
# statically or assigned by mesos:
local ProxyServer = cfg.ProxyServer { ports: [9998, "{{thermos.ports[http]}}"] };
local ProxyRoute = cfg.ProxyRoute;

# ProxyServer definitions (vhosts, basically)
local frontends = [

  # Default frontend, for requests that don't match any vhosts:
  ProxyServer {
    hosts: ["default"],
    context: { default_server: true },
    # Configure nginx to always respond 200 OK on /health:
    healthcheck_route: "/health",
    # todo: implement null source or something?
    routes: [ ProxyRoute{locations: ["/"], sources: [sources.asdf]} ],
  },

  # Aurora scheduler
  ProxyServer {
    hosts: ["aurora.us-east-1.prod.example.com",
            "aurora.us-east-1.prod",
            "aurora.us-east-1.prod"],
    routes: [ ProxyRoute{locations: ["/"], sources: [sources.AuroraScheduler]} ],
  },

  # Mesos master
  ProxyServer {
    hosts: ["mesos.us-east-1.prod.example.com",
            "mesos.us-east-1.prod",
            "mesos.us-east-1"],
    routes: [ ProxyRoute{locations: ["/"], sources: [sources.MesosMaster]} ]
  },
];

# Load the aurora config with our frontends
AurproxyAurora {
  params+: {
    elb_names: "example-elb",
    registration_source: src.AuroraSource {
      # These could probably just be $.cluster $.role etc but this is
      # technically more correct, and will not break even if you do something
      # strange like overriding some of those fields for only the "run" job
      cluster: $.jobmap.run.cluster,
      role: $.jobmap.run.role,
      environment: $.jobmap.run.environment,
      job: $.jobmap.run.name,
    },

    # FIXME(bstaffin): Get this out of here.
    access_key: "FAKEFAKEFAKEFAKEFAKE",
    secret_key: "Fakefakefakefakefakefakefakefakefakefake",
  },

  aurproxy_config: cfg.AurproxyConfig {
    servers: frontends
  },

  extra_args:
    ["--registration-class=tellapart.aurproxy.register.elb.ElbSelfRegisterer"]
    + ["--registration-arg=" + std.escapeStringBash(x) for x in
         [ "region=us-east-1"
         , "elb_names=" + $.params.elb_names
         , "access_key=" + $.params.access_key
         , "secret_key=" + $.params.secret_key
         ]
      ],

  # plumb the portmap overrides down into the right place
  jobmap+: {run+: {announce+: {portmap+: portmap_overrides}}}
}
