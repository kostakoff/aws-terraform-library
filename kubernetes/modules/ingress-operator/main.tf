resource "kubectl_manifest" "ingress-operator" {
  for_each = toset(data.kubectl_path_documents.docs.documents)
  yaml_body = each.value
  
  wait_for_rollout = false
  force_new = true
  server_side_apply = true
  force_conflicts = true
}
