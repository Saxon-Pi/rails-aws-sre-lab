# Kiro Web が 既存 AWS 環境を調査する際に利用する IAM Role の Trust Policy
# -> "kiro_discovery" Roleを「誰が / 何が AssumeRole できるか（借りられるか）」を決める
data "aws_iam_policy_document" "kiro_discovery_assume_role" {
  statement {
    effect = "Allow"

    # q.amazonaws.com かつ SourceIdentity = 自分のKiro User ID
    # という条件で Kiro Web が Role を Assume できる
    principals {
      type        = "Service"
      identifiers = ["q.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:SetSourceIdentity",
    ]

    condition {
      test     = "StringEquals"
      variable = "sts:SourceIdentity"
      values   = [var.kiro_user_id]
    }
  }

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["q.amazonaws.com"]
    }

    actions = [
      "sts:TagSession",
    ]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "aws:TagKeys"

      values = [
        "GroupIds",
        "KiroSessionId",
      ]
    }
  }
}

resource "aws_iam_role" "kiro_discovery" {
  name = "rails-aws-sre-lab-kiro-discovery-role"

  description = "Read-only role used by Kiro Web for Brownfield AWS infrastructure discovery"

  assume_role_policy = data.aws_iam_policy_document.kiro_discovery_assume_role.json
}

# AWS Resource の構成・基本メタデータのみ参照可能にする
resource "aws_iam_role_policy_attachment" "kiro_discovery_view_only" {
  role       = aws_iam_role.kiro_discovery.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

// Kiro 調査用の補足 Policy
data "aws_iam_policy_document" "kiro_discovery_supplemental" {
  statement {
    sid    = "InspectEcsExecutionRole"
    effect = "Allow"

    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListRoleTags",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/rails-aws-sre-lab-ecs-task-execution-role"
    ]
  }

  statement {
    sid    = "InspectManagedPolicy"
    effect = "Allow"

    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
    ]

    resources = [
      "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    ]
  }

  statement {
    sid    = "InspectInfrastructureDetails"
    effect = "Allow"

    actions = [
      "acm:DescribeCertificate",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "ecr:DescribeImages",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "InspectApplicationAutoScaling"
    effect = "Allow"

    actions = [
      "application-autoscaling:DescribeScalableTargets",
      "application-autoscaling:DescribeScalingPolicies",
      "application-autoscaling:DescribeScheduledActions",
      "application-autoscaling:DescribeScalingActivities",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "kiro_discovery_supplemental" {
  name   = "rails-aws-sre-lab-kiro-discovery-supplemental"
  policy = data.aws_iam_policy_document.kiro_discovery_supplemental.json
}

resource "aws_iam_role_policy_attachment" "kiro_discovery_supplemental" {
  role       = aws_iam_role.kiro_discovery.name
  policy_arn = aws_iam_policy.kiro_discovery_supplemental.arn
}