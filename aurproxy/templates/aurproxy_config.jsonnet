# Templates for building aurproxy configs
# for Source types see aurproxy_sources.jsonnet
{
  # Top-level aurproxy configuration
  AurproxyConfig:: {
    backend: "nginx",
    # top-level template context variables:
    context: { sandbox: "/mnt/mesos/sandbox/sandbox" },
    configuration_file: self.context.sandbox + "/nginx.conf",
    nginx_pid_path: self.context.sandbox + "/nginx.pid",
    template_file: self.context.sandbox + "/nginx.conf.template",

    servers: error "servers: expected a list of ProxyServers",
  },

  NginxServerContext:: {
    default_server: false,
    location_blacklist: ["/health", "/quitquitquit", "/abortabortabort"]
  },

  ProxyServer:: {
    routes: [],                    # List of ProxyRoutes
    streams: [],                   # List of ProxyStreams
    ports: [],                     # List of TCP port numbers:
    healthcheck_route: null,       # Optional route that always returns 200 (e.g. "/healthz")
    context: $.NginxServerContext, # variables passed to the nginx template
  },

  ProxyRoute:: {
    locations: error "locations: expected list of HTTP routes (e.g. \"/\")",
    sources: error "sources: expected list of ProxySources",
    empty_endpoint_status_code: 503, # 503 Service Unavailable
    overflow_sources: [],            # Optional list of ProxySources
    overflow_threshold_pct: null,    # Optional int between 1 and 100
  },

  ProxyStream:: {
    sources: error "sources: expected list of ProxySources",
    overflow_sources: [],         # Optional list of ProxySources
    overflow_threshold_pct: null, # Optional int between 1 and 100
  },

  local ShareAdjuster = {
    share_adjuster_class: error "share_adjuster_class is required",
  },

  RampingShareAdjuster:: ShareAdjuster {
    share_adjuster_class: "tellapart.aurproxy.share.adjusters.RampingShareAdjuster",
    ramp_delay: error "ramp_delay is required",
    ramp_seconds: error "ramp_seconds is required",
    update_frequency: error "update_frequency is required",
    curve: null  # Optional string, e.g. "linear"
  },

  HttpHealthCheckShareAdjuster:: ShareAdjuster {
    share_adjuster_class: "tellapart.aurproxy.share.adjusters.HttpHealthCheckShareAdjuster",
    route: "/health",
    interval: 5,
    timeout: 2,
    unhealthy_threshold: 3,
    healthy_threshold: 2,
    http_method: "HEAD"  # HEAD or GET
  },

}
