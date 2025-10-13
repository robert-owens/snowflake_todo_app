-- Snowpark Container Services Deployment Script
-- Run this in your Snowflake SQL console

-- 1. Create image repository (if not exists)
CREATE IMAGE REPOSITORY IF NOT EXISTS MDP_PHARMACY_WS_PROD.DEV.todo_app_repo;

-- 2. Show repository URL for docker push
SHOW IMAGE REPOSITORIES IN SCHEMA MDP_PHARMACY_WS_PROD.DEV;

-- 3. Create compute pool (if not exists)
CREATE COMPUTE POOL IF NOT EXISTS todo_app_pool
  MIN_NODES = 1
  MAX_NODES = 1
  INSTANCE_FAMILY = CPU_X64_XS;

-- 4. Check compute pool status
DESCRIBE COMPUTE POOL todo_app_pool;

-- 5. Create service (run after docker push)
CREATE SERVICE MDP_PHARMACY_WS_PROD.DEV.todo_app_service
  IN COMPUTE POOL todo_app_pool
  FROM SPECIFICATION $$
spec:
  containers:
  - name: todo-app
    image: /mdp_pharmacy_ws_prod/dev/todo_app_repo/todo-app:latest
    env:
      SNOWFLAKE_ACCOUNT: advocate-mdp
      SNOWFLAKE_USER: ROBERT.L.OWENS@ADVOCATEHEALTH.ORG
      SNOWFLAKE_DATABASE: MDP_PHARMACY_WS_PROD
      SNOWFLAKE_SCHEMA: DEV
      SNOWFLAKE_WAREHOUSE: MDP_PHARMACY_WH
      PORT: "8080"
    resources:
      requests:
        memory: 128Mi
        cpu: 0.5
      limits:
        memory: 256Mi
        cpu: 1.0
  endpoints:
  - name: todo-app-endpoint
    port: 8080
    public: true
$$;

-- 6. Check service status
SHOW SERVICES IN SCHEMA MDP_PHARMACY_WS_PROD.DEV;

-- 7. Get service details and endpoint URL
DESCRIBE SERVICE MDP_PHARMACY_WS_PROD.DEV.todo_app_service;

-- 8. Check service logs (if needed for troubleshooting)
-- CALL SYSTEM$GET_SERVICE_LOGS('MDP_PHARMACY_WS_PROD.DEV.todo_app_service', '0', 'todo-app');

-- 9. To update the service (after pushing new image)
-- ALTER SERVICE MDP_PHARMACY_WS_PROD.DEV.todo_app_service FROM SPECIFICATION $$

-- 10. To drop service (if needed)
-- DROP SERVICE MDP_PHARMACY_WS_PROD.DEV.todo_app_service;
-- DROP COMPUTE POOL todo_app_pool;