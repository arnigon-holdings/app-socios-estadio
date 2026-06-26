terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

module "s3" {
  source = "./modules/s3"

  bucket_name      = var.s3_bucket_name
  force_destroy    = var.s3_force_destroy
  enable_lifecycle = true
}

module "rekognition" {
  source = "./modules/rekognition"

  collection_id = var.rekognition_collection_id
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  role_name   = coalesce(var.iam_role_name, "${var.project}-${var.environment}-face-indexing")
  policy_name = coalesce(var.iam_policy_name, "${var.project}-${var.environment}-face-indexing-policy")

  collection_arn = module.rekognition.collection_arn
  bucket_arn     = module.s3.bucket_arn
}

resource "aws_iam_policy" "face_indexing" {
  name        = local.policy_name
  description = "Least-privilege policy for face indexing (Rails FaceIndexer) and face search (Go service)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3FaceBucketRW"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          local.bucket_arn,
          "${local.bucket_arn}/*",
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "RekognitionCollectionAccess"
        Effect = "Allow"
        Action = [
          "rekognition:IndexFaces",
          "rekognition:SearchFacesByImage",
          "rekognition:ListFaces",
          "rekognition:DescribeCollection",
        ]
        Resource = local.collection_arn
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
    ]
  })
}

resource "aws_iam_role" "face_indexing" {
  name        = local.role_name
  description = "Assumed by Rails + Go service for face indexing and search"

  # Assume policy covers two runtime scenarios:
  #   1. AWS-side compute (EC2, ECS tasks, Lambda) — straightforward sts:AssumeRole.
  #   2. GCP Cloud Run → AWS via Workload Identity Federation.
  #
  # For (2) the audience value MUST match the GCP Workload Identity Pool resource ID
  # (format: projects/<gcp_project_number>/locations/global/workloadIdentityPools/<pool>/providers/<provider>).
  # If you do not use GCP Cloud Run for the Rails/Go service, this statement is inert and harmless.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "ecs-tasks.amazonaws.com",
            "lambda.amazonaws.com",
          ]
        }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          Federated = "accounts.google.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "accounts.google.com:aud" = "${data.aws_caller_identity.current.account_id}.svc.id.goog"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "face_indexing" {
  role       = aws_iam_role.face_indexing.name
  policy_arn = aws_iam_policy.face_indexing.arn
}
