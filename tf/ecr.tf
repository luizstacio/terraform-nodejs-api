/*
 * ecr.tf
 * Creates a Amazon Elastic Container Registry (ECR) for the application
 * https://aws.amazon.com/ecr/
 */

# The tag mutability setting for the repository (defaults to IMMUTABLE)
variable "image_tag_mutability" {
  type        = string
  default     = "IMMUTABLE"
  description = "The tag mutability setting for the repository (defaults to IMMUTABLE)"
}

resource "random_uuid" "ecr_identifier" {
}

# create an ECR repo at the app/image level
resource "aws_ecr_repository" "app" {
  name                 = "${var.app}-${var.environment}-${random_uuid.ecr_identifier.result}"
  image_tag_mutability = var.image_tag_mutability
  tags                 = var.tags
}

data "aws_caller_identity" "current" {
}

# grant access to saml users
resource "aws_ecr_repository_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy     = <<EOF
    {
      "Version": "2008-10-17",
      "Statement": [
        {
          "Sid": "new policy",
          "Effect": "Allow",
          "Principal": "*",
          "Action": [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:DescribeRepositories",
            "ecr:GetRepositoryPolicy",
            "ecr:ListImages",
            "ecr:DeleteRepository",
            "ecr:BatchDeleteImage",
            "ecr:SetRepositoryPolicy",
            "ecr:DeleteRepositoryPolicy"
          ]
        }
      ]
    }
  EOF
}
