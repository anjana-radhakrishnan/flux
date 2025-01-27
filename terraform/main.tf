module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "flux-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true


  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "test" 
  }
}


 # module "eks" for creating cluster using terraform registry 
  module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"
  cluster_name    = "flux-cluster" #EKS cluster name
  cluster_version = "1.24" #EKS cluster version
  cluster_endpoint_private_access = false #Enabling cluster endpoint private access
  cluster_endpoint_public_access  = true  #disabling endpoint public access
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets
  create_iam_role = true #Creating cluster role
  iam_role_name = "flux-eks-role" #name for cluster role
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  cluster_service_cidr = "10.100.0.0/16"

# aws-auth configmap to add role-based access control (RBAC) access to IAM users and roles
  create_aws_auth_configmap = false
  manage_aws_auth_configmap = false


#Creating additional security group for cluster
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
    ingress_nodes_ports_tcp = {
      description                = "Allow the pods to communicate with the cluster API Server"
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "egress"
      source_node_security_group = true
    }
    egress_all = {
      description      = "Cluster all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ingress_with_source_security_group_id = {
      description                  = "Allow communication to the cluster API Server"
      protocol                     = "tcp"
      from_port                    = 443
      to_port                      = 443
      type                         = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  }
  }


#Creating Node Group
module "eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  name            = "flux-nodegroup"
  cluster_name    = module.eks.cluster_name 
  cluster_version = "1.24"

  subnet_ids = module.vpc.public_subnets
  vpc_security_group_ids = [module.eks.node_security_group_id]
  min_size     = 2
  max_size     = 2
  desired_size = 2
  instance_types = ["t3a.medium"]
  capacity_type  = "ON_DEMAND"
  use_custom_launch_template = false

  # To Encrypt the root volume
  block_device_mappings = {
    xvda = {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 8
        volume_type           = "gp3"
        iops                  = 3000
        encrypted             = false
        delete_on_termination = true
      }
    }
  }
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
}


