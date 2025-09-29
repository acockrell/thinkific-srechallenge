# Kubernetes Manifests for DumbKV

This directory contains Kubernetes manifests for deploying the DumbKV application with a SQLite backend.

## Manifests Overview

### deployment.yaml
- Single replica with `Recreate` strategy to prevent SQLite conflicts
- Health checks (liveness/readiness probes) on port 8000
- Environment variables for SQLite backend pointing to `/data/dumbkvstore/dumbkv.db`
- Resource limits and persistent volume mount

### service.yaml
- ClusterIP service exposing port 80 → 8000
- Routes traffic to deployment pods

### pvc.yaml
- PersistentVolumeClaim with `efs` storage class
- 1Gi storage for SQLite database
- ReadWriteOnce access mode for single replica

### ingress.yaml
- Exposes service at `dumbkv.example.com` on root path
- TLS with `letsencrypt` cluster issuer for automatic certificates
- NGINX ingress controller annotations

## Deployment

The manifests follow Kubernetes best practices and meet all specified requirements for running DumbKV with SQLite backend in a single-replica configuration.

To deploy:
```bash
kubectl apply -f manifests/
```

## Notes

- The deployment uses a single replica to prevent multiple instances from accessing the SQLite database simultaneously
- Persistent storage ensures data survives pod restarts
- Health checks ensure the application is ready to serve traffic
- TLS certificates are automatically managed by cert-manager
