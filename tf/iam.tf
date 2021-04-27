
resource "random_uuid" "api_user_id" {
}

data "aws_iam_policy_document" "api_user_policy" {
  statement {
    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.bucket}"
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::${var.bucket}",
      "arn:aws:s3:::${var.bucket}/*"
    ]
  }
}

resource "aws_iam_user" "api_user" {
  name = "${var.app}-${var.environment}-${random_uuid.api_user_id.result}"
  tags = var.tags
}

resource "aws_iam_access_key" "api_user" {
  user = aws_iam_user.api_user.name
}

resource "aws_iam_user_policy" "api_user_policy" {
  name = "${var.app}-${var.environment}-${random_uuid.api_user_id.result}-policy"
  user = aws_iam_user.api_user.name
  policy = data.aws_iam_policy_document.api_user_policy.json
}

resource "aws_ssm_parameter" "api_aws_access_key" {
  name        = "/${var.app}/${var.environment}/awsAccessKey"
  type        = "SecureString"
  value       = aws_iam_access_key.api_user.id
  overwrite = true
  tags = var.tags
}

resource "aws_ssm_parameter" "api_aws_access_secret" {
  name        = "/${var.app}/${var.environment}/awsAccessSecret"
  type        = "SecureString"
  value       = aws_iam_access_key.api_user.secret
  overwrite = true
  tags = var.tags
}