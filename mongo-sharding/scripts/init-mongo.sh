#!/bin/bash

echo "Initializing config server..."
docker exec -i configSrv mongosh --port 27017 <<EOF
rs.initiate({
  _id: "config_server",
  configsvr: true,
  members: [
    { _id: 0, host: "configSrv:27017" }
  ]
});
rs.status();
EOF

echo "Waiting 5 seconds before initializing shard1..."
sleep 5

echo "Initializing shard1..."
docker exec -i shard1 mongosh --port 27018 <<EOF
rs.initiate({
  _id: "shard1",
  members: [
    { _id: 0, host: "shard1:27018" }
  ]
});
rs.status();
EOF

echo "Waiting 5 seconds before initializing shard2..."
sleep 5

echo "Initializing shard2..."
docker exec -i shard2 mongosh --port 27019 <<EOF
rs.initiate({
  _id: "shard2",
  members: [
    { _id: 0, host: "shard2:27019" }
  ]
});
rs.status();
EOF

echo "Waiting 5 seconds before initializing mongos router..."
sleep 5

echo "Initializing mongos router..."
docker exec -i mongos_router mongosh --port 27020 <<EOF
sh.addShard("shard1/shard1:27018");
sh.addShard("shard2/shard2:27019");
sh.status();

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", {age: "hashed"});

use somedb
for (var i = 0; i < 1000; i++) {
  db.helloDoc.insertOne({age: i, name: "ly" + i});
}
db.helloDoc.getShardDistribution();
EOF

echo "MongoDB initialization complete!"