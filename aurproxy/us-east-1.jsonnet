# aurproxy and helper jobs for one cluster

local demoproxy = import "templates/demoproxy.jsonnet";

demoproxy {
  cluster: "us-east-1",
  environment: "devel",
  role: "vagrant",
  instances: 2
}
