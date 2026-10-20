locals {
  create_backend       = var.backend_repository != null
  create_frontend      = var.frontend_repository != null
  backend_role_name    = "iam-${var.product}-${var.backend_service_name}-deploy-${var.environment}"
  frontend_role_name   = "iam-${var.product}-static-site-deploy-${var.environment}"
  token_audience_claim = "token.actions.githubusercontent.com:aud"
  token_subject_claim  = "token.actions.githubusercontent.com:sub"
  immutable_subject    = var.github_owner_id != null
  owner_subject        = local.immutable_subject ? "${var.github_owner}@${var.github_owner_id}" : var.github_owner
  backend_subject = local.create_backend ? format(
    "repo:%s/%s:environment:%s",
    local.owner_subject,
    local.immutable_subject ? "${var.backend_repository}@${var.backend_repository_id}" : var.backend_repository,
    var.github_environment,
  ) : null
  frontend_subject = local.create_frontend ? format(
    "repo:%s/%s:environment:%s",
    local.owner_subject,
    local.immutable_subject ? "${var.frontend_repository}@${var.frontend_repository_id}" : var.frontend_repository,
    var.github_environment,
  ) : null
}

data "aws_iam_policy_document" "backend_trust" {
  count = local.create_backend ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = local.token_audience_claim
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = local.token_subject_claim
      values   = [local.backend_subject]
    }
  }
}

data "aws_iam_policy_document" "backend_deploy" {
  count = local.create_backend ? 1 : 0

  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "EcrPushAndRead"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
    ]
    resources = [var.ecr_repository_arn]
  }

  statement {
    sid = "TaskDefinitions"
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
    ]
    resources = ["*"]
  }

  statement {
    sid = "UpdateService"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
    ]
    resources = [var.ecs_service_arn]
  }

  statement {
    sid       = "PassTaskRoles"
    actions   = ["iam:PassRole"]
    resources = var.ecs_pass_role_arns

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backend" {
  count = local.create_backend ? 1 : 0

  name               = local.backend_role_name
  assume_role_policy = data.aws_iam_policy_document.backend_trust[0].json
}

resource "aws_iam_role_policy" "backend" {
  count = local.create_backend ? 1 : 0

  name   = "deploy-backend"
  role   = aws_iam_role.backend[0].id
  policy = data.aws_iam_policy_document.backend_deploy[0].json
}

data "aws_iam_policy_document" "frontend_trust" {
  count = local.create_frontend ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = local.token_audience_claim
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = local.token_subject_claim
      values   = [local.frontend_subject]
    }
  }
}

data "aws_iam_policy_document" "frontend_deploy" {
  count = local.create_frontend ? 1 : 0

  statement {
    sid       = "ListSiteBucket"
    actions   = ["s3:ListBucket"]
    resources = [var.site_bucket_arn]
  }

  statement {
    sid = "WriteSiteObjects"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = ["${var.site_bucket_arn}/*"]
  }

  statement {
    sid = "InvalidateDistribution"
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
    ]
    resources = [var.site_distribution_arn]
  }
}

resource "aws_iam_role" "frontend" {
  count = local.create_frontend ? 1 : 0

  name               = local.frontend_role_name
  assume_role_policy = data.aws_iam_policy_document.frontend_trust[0].json
}

resource "aws_iam_role_policy" "frontend" {
  count = local.create_frontend ? 1 : 0

  name   = "deploy-frontend"
  role   = aws_iam_role.frontend[0].id
  policy = data.aws_iam_policy_document.frontend_deploy[0].json
}
