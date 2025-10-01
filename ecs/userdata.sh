#!/bin/bash

cat <<'EOF' >> /etc/ecs/ecs.config
ECS_CLUSTER=ecs-cluster
ECS_LOGLEVEL=debug
ECS_CONTAINER_INSTANCE_TAGS={"department":"IT","environment":"test","project_name":"ecs-cluster"}
ECS_ENABLE_TASK_IAM_ROLE=true
EOF
