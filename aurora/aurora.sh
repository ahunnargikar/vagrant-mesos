#!/usr/bin/env bash
# An example scheduler launch script that works with the included Vagrantfile.
 
AURORA_SCHEDULER_HOME=/usr/local/aurora-scheduler
 
# Flags that control the behavior of the JVM.
JAVA_OPTS=(
  -server
  -Xmx1g
  -Xms1g
 
  # Location of libmesos-0.15.0.so / libmesos-0.15.0.dylib
  -Djava.library.path=/usr/local/lib
)
 
# Flags control the behavior of the Aurora scheduler.
# For a full list of available flags, run bin/aurora-scheduler -help
AURORA_FLAGS=(
  -cluster_name=example
 
  # Ports to listen on.
  -http_port=9001
  -thrift_port=9002
  -native_log_quorum_size=1
  -zk_endpoints=zookeeper1:2181,zookeeper2:2181,zookeeper3:2181
  -mesos_master_address=zk://zookeeper1:2181,zookeeper2:2181,zookeeper3:2181/mesos
  -serverset_path=/aurora/scheduler
  -native_log_zk_group_path=/aurora/replicated-log
  -native_log_file_path="$AURORA_SCHEDULER_HOME/db"
  -backup_dir="$AURORA_SCHEDULER_HOME/backups"
 
  -thermos_executor_path=/usr/local/bin/thermos_executor
 
  -gc_executor_path=/usr/local/bin/gc_executor
 
  -vlog=INFO
  -logtostderr
)
 
# Environment variables control the behavior of the Mesos scheduler driver (libmesos).
export GLOG_v=99
export LIBPROCESS_PORT=8083
export LIBPROCESS_IP=192.168.56.101
 
(
  while true
  do
    JAVA_OPTS="${JAVA_OPTS[*]}" exec "$AURORA_SCHEDULER_HOME/bin/aurora-scheduler" "${AURORA_FLAGS[@]}"
  done
) &