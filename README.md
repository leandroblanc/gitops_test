# gitops_test

## argocd.tf file

```
module "argocd" {
  source = "../../../modules/argo"
}

# Perform the ArgoCD bootstrapping by creating the Root App ("App of Apps"): https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/
# This application will use the "default" ArgoCD project: https://argo-cd.readthedocs.io/en/stable/user-guide/projects/#the-default-project
# We'll create the ArgoCD Application CRD using the Terraform k8s manifest resource: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest#example-create-a-kubernetes-custom-resource-definition

locals {
  environments = ["dev", "stage", "prod"]
  argocd_namespace = "argocd"
  argocd_repo_url = "https://github.com/leandroblanc/gitops_test"
}

resource "kubectl_manifest" "environments" {
  # This terraform resource creates one Kubernetes CRD (Custom Resource Definition) for each clusterset (not per cluster, since the clusterset apps are defined in the same directory argocd/<clusterset>/apps/values.yaml
  # The CRD is an ArgoCD application (argoproj.io/v1alpha1) that acts like the "root application" for that cluster (the "App of Apps" pattern)
  # In this way we can reuse settings that are common to all the applications defined by this "root app" (like the cluster name and the cluster URL)
  count = length(local.environments)

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      # app names will be "<clusterset>-apps"
      name      = "${local.environments[count.index]}-apps"
      namespace = local.argocd_namespace
    }

    # All the App of Apps applications should be deployed on the local cluster (in the cluster where ArgoCD is running) even if its sub-apps will point to remote clusters
    spec = {
      destination = {
        namespace = "${local.argocd_namespace}"
        server    = "https://kubernetes.default.svc"
      }

      # We create the App of Apps manifest in the default project
      project = "default"

      # Configure automatic synchronization
      syncPolicy = {
        automated = {}
      }

      source = {
        repoURL        = "${local.argocd_repo_url}"
        targetRevision = "HEAD"
        # Path points to the environment name
        # Examples: dev/apps, stage/apps, prod/apps
        path = "${local.environments[count.index]}/apps"
        helm = {
          # This single values.yaml file (located in the apps directory) will define all the apps to deploy on this clusterset
          valueFiles = ["values.yaml"]
        }
      }
    }
  })

  depends_on = [module.argocd]
}
```
