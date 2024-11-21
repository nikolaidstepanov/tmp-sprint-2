#!/bin/bash

echo "Initializing config server..."
docker exec -i configSrv-1 mongosh --port 27017 <<EOF
rs.initiate({
  _id: "config_server",
  configsvr: true,
  members: [
    { _id: 0, host: "configSrv-1:27017" },
    { _id: 1, host: "configSrv-2:27018" },
  ]
});
rs.status();
EOF

echo "Waiting 2 seconds before initializing shards with replicas..."
sleep 2

echo "Initializing shard1 with replicas..."
docker exec -i shard1-1 mongosh --port 27021 <<EOF
rs.initiate({
  _id: "rs-shard1",
  members: [
    { _id: 0, host: "shard1-1:27021" },
    { _id: 1, host: "shard1-2:27022" },
    { _id: 2, host: "shard1-3:27023" },
  ]
});
rs.status();
EOF

echo "Initializing shard2 with replicas..."
docker exec -i shard2-1 mongosh --port 27024 <<EOF
rs.initiate({
  _id: "rs-shard2",
  members: [
    { _id: 0, host: "shard2-1:27024" },
    { _id: 1, host: "shard2-2:27025" },
    { _id: 2, host: "shard2-3:27026" },
  ]
});
rs.status();
EOF

echo "Waiting 10 seconds before initializing mongos router..."
sleep 10

echo "Initializing mongos router..."
docker exec -i mongos-router-1 mongosh --port 27019 <<EOF
sh.addShard("rs-shard1/shard1-1:27021");
sh.addShard("rs-shard2/shard2-1:27024");
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