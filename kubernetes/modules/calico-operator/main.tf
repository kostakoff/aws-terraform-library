resource "kubectl_manifest" "calico-operator" {
  for_each  = data.kubectl_file_documents.calico-operator.manifests
  yaml_body = each.value
  
  wait_for_rollout = false
  force_new = true
  server_side_apply = true
  force_conflicts = true
}

resource "kubectl_manifest" "calico-installation" {
  yaml_body = <<YAML
    kind: Installation
    apiVersion: operator.tigera.io/v1
    metadata:
      name: default
    spec:
      kubernetesProvider: EKS
      cni:
        type: Calico
      calicoNetwork:
        bgp: Disabled
  YAML

  wait_for_rollout = false
  force_new = true

  depends_on = [ 
    kubectl_manifest.calico-operator 
  ]
}