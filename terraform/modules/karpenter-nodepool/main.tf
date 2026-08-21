###############################################################################
# Karpenter NodePool + EC2NodeClass — defines what Karpenter can provision
###############################################################################

resource "kubectl_manifest" "ec2_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      role: ${var.node_role_name}
      amiSelectorTerms:
        - alias: al2023@latest
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      tags:
        karpenter.sh/discovery: ${var.cluster_name}
  YAML
}

resource "kubectl_manifest" "node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
          requirements:
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand", "spot"]
            - key: node.kubernetes.io/instance-type
              operator: In
              values: ["t3a.medium", "t3a.large", "m5.large", "m5a.large"]
      limits:
        cpu: "20"
        memory: 40Gi
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 30s
  YAML

  depends_on = [kubectl_manifest.ec2_node_class]
}
