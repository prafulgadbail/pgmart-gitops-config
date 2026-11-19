<p align="center">
  <img src="docs/pgmart-logo.svg" alt="PGMart" width="360">
</p>

<p align="center">
  Deployment configuration for <a href="https://github.com/prafulgadbail/pgmart-gitops">pgmart-gitops</a>.<br>
  Helm chart and per-service values, deployed to Amazon EKS by Argo CD.
</p>

<p align="center">
  <img alt="Helm" src="https://img.shields.io/badge/Helm-3-0F1689?logo=helm&logoColor=white">
  <img alt="Argo CD" src="https://img.shields.io/badge/GitOps-Argo_CD-EF7B4D?logo=argo&logoColor=white">
  <img alt="Kubernetes" src="https://img.shields.io/badge/Kubernetes-1.29+-326CE5?logo=kubernetes&logoColor=white">
  <img alt="Amazon EKS" src="https://img.shields.io/badge/Amazon_EKS-cluster-FF9900?logo=amazoneks&logoColor=white">
  <img alt="External Secrets" src="https://img.shields.io/badge/Secrets-External_Secrets-4B5563">
</p>

## About

This repository holds what runs in the cluster, not the application code. The application and its CI live in [pgmart-gitops](https://github.com/prafulgadbail/pgmart-gitops). Argo CD watches this repository and makes the cluster match it, so every deployment is a Git commit that can be reviewed, traced and reverted. CI never gets access to the cluster.

## How a release reaches the cluster

| # | Who | What happens |
|---|---|---|
| 1 | GitHub Actions (pgmart-gitops) | Builds, tests and scans a service, pushes the image to Amazon ECR, tagged with the Git commit |
| 2 | GitHub Actions | Commits the new tag to `helm/values/<service>.yaml` in this repository |
| 3 | Argo CD | Sees the commit, renders `helm/pgmart-service` with that values file and rolls out the new version |

## Repository layout

~~~
📦 pgmart-gitops-config
 ┣ 📂 argocd                      Argo CD: what is deployed, and where
 ┃ ┣ 📜 project.yaml              allowed repository, namespace and resource kinds
 ┃ ┗ 📜 applicationset.yaml       one application per service
 ┣ 📂 helm                        Helm: how each service runs
 ┃ ┣ 📂 pgmart-service            one chart for the three services
 ┃ ┃ ┣ 📜 Chart.yaml              name and version of the chart
 ┃ ┃ ┣ 📜 values.yaml             defaults shared by every service
 ┃ ┃ ┣ 📜 values.schema.json      rejects a wrong value before anything is deployed
 ┃ ┃ ┗ 📂 templates
 ┃ ┃   ┣ 📜 _helpers.tpl          labels used by every template
 ┃ ┃   ┣ 📜 deployment.yaml       pods: image, probes, resources, rolling update, non-root
 ┃ ┃   ┣ 📜 service.yaml          stable address inside the cluster
 ┃ ┃   ┣ 📜 serviceaccount.yaml   identity of the pods
 ┃ ┃   ┣ 📜 configmap.yaml        plain settings as environment variables
 ┃ ┃   ┣ 📜 externalsecret.yaml   secrets copied from AWS Secrets Manager
 ┃ ┃   ┣ 📜 ingress.yaml          /api paths on the shared internal ALB
 ┃ ┃   ┣ 📜 hpa.yaml              more pods under load
 ┃ ┃   ┗ 📜 pdb.yaml              keeps a pod running while nodes are replaced
 ┃ ┗ 📂 values                    what is different for each service
 ┃   ┣ 📜 user-service.yaml       image and tag, settings, secret name, ingress paths
 ┃   ┣ 📜 catalog-service.yaml
 ┃   ┗ 📜 order-service.yaml
 ┣ 📂 docs
 ┃ ┗ 🖼️ pgmart-logo.svg
 ┣ 📜 .gitignore
 ┗ 📜 README.md
~~~

## Where each value comes from

Helm merges two files for every service. The service file wins.

| File | Holds | Changed by |
|---|---|---|
| `helm/pgmart-service/values.yaml` | Defaults for every service: CPU and memory, autoscaling limits, the shared ALB group | A person, through a pull request |
| `helm/values/<service>.yaml` | Image repository, settings (ConfigMap), Secrets Manager key, ingress paths | A person, through a pull request |
| `helm/values/<service>.yaml` → `image.tag` | The Git commit of the image to run | The CI pipeline, after every build on main |

## What the chart creates for each service

| Resource | Purpose |
|---|---|
| Deployment | Pods with startup, liveness and readiness probes; a rolling update starts a new pod before stopping an old one; non-root user, read-only filesystem |
| Service | Address used by other services, e.g. `http://catalog-service:8080` |
| ServiceAccount | Identity of the pods |
| ConfigMap | Plain settings as environment variables; a change restarts the pods |
| ExternalSecret | Copies `pgmart-gitops/<service>` from AWS Secrets Manager into a Kubernetes Secret |
| Ingress | The service's `/api/...` paths on the shared internal ALB (AWS Load Balancer Controller) |
| HorizontalPodAutoscaler | Adds pods when CPU stays high |
| PodDisruptionBudget | Keeps at least one pod running while Karpenter replaces nodes |
