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