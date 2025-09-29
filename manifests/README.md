# Kubernetes Manifests for DumbKV

This directory contains Kubernetes manifests for deploying the DumbKV application with a PostgreSQL backend.

## Manifests Overview

### deployment.yaml
- Single replica with `Recreate` strategy for simple deployments
- Health checks (liveness/readiness probes) on port 8000
- Environment variables for PostgreSQL backend with connection string
- Resource limits (no volume mounts needed for PostgreSQL backend)

### service.yaml
- ClusterIP service exposing port 80 → 8000
- Routes traffic to deployment pods

### pvc.yaml
- PersistentVolumeClaim with `efs` storage class for DumbKV (legacy SQLite)
- 1Gi storage - kept for backward compatibility but not used with PostgreSQL

### postgres-deployment.yaml
- PostgreSQL 15 Alpine deployment with single replica
- Environment variables loaded from ConfigMap and Secret
- Health checks using `pg_isready` command
- Persistent volume mount for database storage
- Resource limits (256Mi-512Mi memory, 250m-500m CPU)

### postgres-service.yaml
- ClusterIP service exposing PostgreSQL on port 5432
- Internal cluster access for DumbKV application

### postgres-config.yaml
- ConfigMap with PostgreSQL database name and user
- Secret with base64-encoded PostgreSQL password

### postgres-pvc.yaml
- PersistentVolumeClaim with `efs` storage class for PostgreSQL
- 5Gi storage for PostgreSQL database
- ReadWriteOnce access mode

### ingress.yaml
- Exposes service at `dumbkv.example.com` on root path
- TLS with `letsencrypt` cluster issuer for automatic certificates
- NGINX ingress controller annotations

## Deployment

The manifests follow Kubernetes best practices and support running DumbKV with PostgreSQL backend in a scalable, high-availability configuration.

To deploy:
```bash
# Deploy PostgreSQL first
kubectl apply -f manifests/postgres-config.yaml
kubectl apply -f manifests/postgres-pvc.yaml
kubectl apply -f manifests/postgres-deployment.yaml
kubectl apply -f manifests/postgres-service.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=available --timeout=300s deployment/postgres

# Deploy DumbKV application
kubectl apply -f manifests/deployment.yaml
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/ingress.yaml
```

Or deploy all at once:
```bash
kubectl apply -f manifests/
```

## Architecture Changes

### PostgreSQL Backend Benefits:
- **Scalability**: PostgreSQL backend ready for future scaling if needed
- **Concurrency**: Handles concurrent database operations safely
- **Performance**: Better performance compared to SQLite for database operations
- **Reliability**: Dedicated database service with persistent storage

### Database Configuration:
- Database: `dumbkv`
- User: `dumbkv_user`
- Password: `dumbkv_password` (stored in Kubernetes Secret)
- Connection: `postgresql://dumbkv_user:dumbkv_password@postgres-service:5432/dumbkv`

## Notes

- PostgreSQL deployment uses a single replica with persistent storage
- DumbKV application uses single replica with PostgreSQL backend
- Health checks ensure both PostgreSQL and DumbKV are ready to serve traffic
- TLS certificates are automatically managed by cert-manager
- Database credentials are securely stored in Kubernetes ConfigMap and Secret
