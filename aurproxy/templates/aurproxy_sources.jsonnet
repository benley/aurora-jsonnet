# aurproxy source classes

local proxySource = {
  source_class: error "source_class is required",
  #share_adjusters: [],
};

local zkProxySource = proxySource {
  cluster:: null,
  # you'll probably want to tweak this for your own site:
  zk_servers: if self.cluster == null
              then error "either cluster or zk_server is required"
              else "zk.%(cluster)s.prod.example.com:2181" % self,
};

{
  AuroraSource: zkProxySource {
    source_class: "tellapart.aurproxy.source.AuroraProxySource",
    announcer_serverset_path: "/aurora",  # zk path prefix
    endpoint: "http",

    role: error "role is required",
    environment: error "environment is required",
    job: error "job is required",
  },

  ServerSetSource: zkProxySource {
    cluster:: null,
    source_class: "tellapart.aurproxy.source.ServerSetSource",
    path: error "path is required",

    # endpoint: null,  # optional: named endpoint
    zk_member_prefix: null,  # optional: filter member names by a prefix
  },

  MesosMasterSource: zkProxySource {
    source_class: "tellapart.aurproxy.source.MesosMasterProxySource",
    mesos_master_path: "/mesos-" + self.cluster,
  },

  StaticSource: proxySource {
    source_class: "tellapart.aurproxy.source.StaticSource",
    name: error "name is required",
    host: error "host is required",
    port: error "port is required",
  },

  ApiSource: proxySource {
    source_class: "tellapart.aurproxy.source.ApiSource",
    name: error "name is required",
    source_whitelist: [],
  },
}
