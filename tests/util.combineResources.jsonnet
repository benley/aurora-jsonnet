local util = import "../lib/util.jsonnet";

std.assertEqual(
  util.combineResources(
    {cpu: 1, ram: 2, disk: 3},
    {cpu: 4, ram: 5, disk: 6}),
  {cpu: 5, ram: 7, disk: 9}
)
