# aurproxy and helper jobs for one cluster

local demoproxy = import "templates/demoproxy.jsonnet";

demoproxy {
  cluster: "devcluster",
  environment: "devel",
  role: "vagrant",
  instances: 1
}
