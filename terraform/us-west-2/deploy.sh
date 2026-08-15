#!/bin/bash
# Two-phase deployment script for EKS with Karpenter
# Phase 1: Deploy VPC, EKS, OIDC, Karpenter IRSA (everything except helm/kubectl resources)
# Phase 2: Deploy Karpenter Helm release and NodePool CRDs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration - matches variables.tf defaults
CLUSTER_NAME="gitops-poc"
AWS_REGION="us-west-2"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  init        - Initialize Terraform"
    echo "  plan        - Plan Phase 1 only (VPC, EKS, OIDC, IRSA)"
    echo "  plan-all    - Plan everything (only works if cluster already exists)"
    echo "  apply       - Apply all resources (Phase 1 then Phase 2 automatically)"
    echo "  destroy     - Destroy all resources (reverse order)"
    echo "  phase1      - Apply only Phase 1 (VPC, EKS, OIDC, IRSA)"
    echo "  phase2      - Apply only Phase 2 (Karpenter Helm + NodePool)"
    echo "  plan-phase1 - Plan Phase 1 only"
    echo "  plan-phase2 - Plan Phase 2 only (requires existing cluster)"
    echo "  status      - Check cluster status"
    echo ""
    echo "Note: Phase 2 planning/apply requires the EKS cluster to exist first."
    echo "      The kubectl/helm providers need to connect to a real cluster."
    echo ""
    exit 1
}

get_cluster_status() {
    aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'cluster.status' --output text 2>/dev/null || echo "NOT_FOUND"
}

check_cluster_exists() {
    local status
    status=$(get_cluster_status)
    [ "$status" = "ACTIVE" ]
}

wait_for_cluster() {
    echo_info "Waiting for EKS cluster '$CLUSTER_NAME' to be ACTIVE..."
    
    local max_attempts=60  # 30 minutes max (30 sec intervals)
    local attempt=0
    local status
    
    while [ $attempt -lt $max_attempts ]; do
        status=$(get_cluster_status)
        
        case "$status" in
            ACTIVE)
                echo_info "Cluster is ACTIVE!"
                return 0
                ;;
            CREATING)
                echo_info "Cluster status: CREATING (attempt $((attempt + 1))/$max_attempts)..."
                sleep 30
                ;;
            NOT_FOUND)
                echo_error "Cluster not found. Phase 1 may not have completed successfully."
                echo_error "Check terraform apply output and try again."
                return 1
                ;;
            *)
                echo_error "Unexpected cluster status: $status"
                return 1
                ;;
        esac
        
        attempt=$((attempt + 1))
    done
    
    echo_error "Timeout waiting for cluster to become ACTIVE."
    return 1
}

phase1_targets() {
    # Everything except karpenter_helm and karpenter_nodepool
    echo "-target=module.vpc -target=module.eks -target=module.oidc -target=module.karpenter_irsa"
}

phase2_targets() {
    echo "-target=module.karpenter_helm -target=module.karpenter_nodepool -target=module.argocd"
}

do_init() {
    echo_info "Initializing Terraform..."
    terraform init -upgrade
}

do_plan_phase1() {
    echo_info "Planning Phase 1: VPC, EKS, OIDC, Karpenter IRSA..."
    terraform plan $(phase1_targets)
}

do_plan_phase2() {
    if ! check_cluster_exists; then
        echo_error "EKS cluster does not exist. Cannot plan Phase 2 without a running cluster."
        echo_error "Run './deploy.sh phase1' first to create the cluster."
        exit 1
    fi
    echo_info "Planning Phase 2: Karpenter Helm + NodePool..."
    terraform plan $(phase2_targets)
}

do_plan_all() {
    if ! check_cluster_exists; then
        echo_error "EKS cluster does not exist. Cannot plan all resources."
        echo_error "Use 'plan' to plan Phase 1, or 'apply' to deploy everything."
        exit 1
    fi
    echo_info "Planning all resources (cluster exists)..."
    terraform plan
}

do_apply_phase1() {
    echo_info "Applying Phase 1: VPC, EKS, OIDC, Karpenter IRSA..."
    terraform apply $(phase1_targets)
    
    # Wait for cluster using our robust wait function
    if ! wait_for_cluster; then
        echo_error "Failed waiting for cluster. Aborting."
        exit 1
    fi
    
    # Update kubeconfig
    echo_info "Updating kubeconfig..."
    aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"
}

do_apply_phase2() {
    if ! check_cluster_exists; then
        echo_error "EKS cluster does not exist. Run phase1 first."
        exit 1
    fi
    
    echo_info "Applying Phase 2: Karpenter Helm + NodePool..."
    terraform apply $(phase2_targets)
    
    echo_info "Verifying Karpenter deployment..."
    kubectl get pods -n karpenter
}

do_plan() {
    do_plan_phase1
    echo ""
    echo_warn "Phase 2 cannot be planned until the cluster exists."
    echo_warn "Run './deploy.sh apply' for full deployment, or './deploy.sh phase1' first."
}

do_apply() {
    do_apply_phase1
    echo ""
    do_apply_phase2
    
    echo ""
    echo_info "=== Deployment Complete ==="
    echo_info "Cluster: $CLUSTER_NAME"
    echo_info "Region: $AWS_REGION"
    echo ""
    echo_info "Verify Karpenter:"
    echo "  kubectl get pods -n karpenter"
    echo "  kubectl get nodepools"
    echo "  kubectl get ec2nodeclasses"
}

do_status() {
    local status
    status=$(get_cluster_status)
    echo_info "Cluster: $CLUSTER_NAME"
    echo_info "Region: $AWS_REGION"
    echo_info "Status: $status"
    
    if [ "$status" = "ACTIVE" ]; then
        echo ""
        echo_info "Terraform state:"
        terraform state list 2>/dev/null | wc -l | xargs -I {} echo "  {} resources in state"
    fi
}

do_destroy() {
    echo_warn "This will destroy all resources!"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo_info "Aborted."
        exit 0
    fi
    
    # Destroy in reverse order - Karpenter first, then infra
    echo_info "Destroying Phase 2 (Karpenter)..."
    terraform destroy $(phase2_targets) || true
    
    echo_info "Destroying Phase 1 (VPC, EKS, OIDC, IRSA)..."
    terraform destroy $(phase1_targets)
    
    echo_info "Destroy complete."
}

# Main
case "${1:-}" in
    init)
        do_init
        ;;
    plan)
        do_plan
        ;;
    plan-all)
        do_plan_all
        ;;
    plan-phase1)
        do_plan_phase1
        ;;
    plan-phase2)
        do_plan_phase2
        ;;
    apply)
        do_apply
        ;;
    destroy)
        do_destroy
        ;;
    phase1)
        do_apply_phase1
        ;;
    phase2)
        do_apply_phase2
        ;;
    status)
        do_status
        ;;
    -h|--help|-\?|\?)
        usage
        ;;
    *)
        usage
        ;;
esac
