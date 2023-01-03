locals {
  enabled = false
  istio_label = false

}

resource "helm_release" "kyverno" {
  count = local.enabled ? 1 : 0
  name       = "kyverno"
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  namespace = "kyverno"
  version = "2.6.4"
  set {
    name  = "replicaCount"
    value = "3"
  }
}

resource "helm_release" "kyverno-policyreporter" {
  count = local.enabled ? 1 : 0
  name      = "kyverno-policyreporter"
  repository = "https://kyverno.github.io/policy-reporter"
  chart     = "policy-reporter"
  namespace = "kyverno"
  wait      = true
  set {
    name = "kyvernoPlugin.enabled"
    value = "true" 
  }
  set {
    name = "ui.enabled"
    value = "true" 
  }
  set {
    name = "ui.plugins.kyverno"
    value = "true" 
  }
  depends_on = [helm_release.kyverno]
}

resource "null_resource" "namespace-label" {
  count = local.istio_label ? 1 : 0
  provisioner "local-exec" {
    command = "kubectl --context spantest-rr-aks-cluster-admin apply -f istio-label.yaml"
  }
  depends_on = [helm_release.kyverno]
}


resource "null_resource" "destroy_istio_require_authentication" {
  count = local.istio_label ? 0 : 1

  provisioner "local-exec" {
    command = "kubectl --context spantest-rr-aks-cluster-admin delete -f istio-label.yaml"
  }
  depends_on = [helm_release.kyverno]
}

# resource "kubernetes_manifest" "istio-label" {
#   count = local.enabled ? 1 : 0
#   manifest = yamldecode(file("istio-label.yaml"))
#   depends_on = [helm_release.kyverno]
# }