resource "aws_sns_topic" "default" {
  name_prefix = "claims-sns"
}

resource "aws_sns_topic_policy" "default" {
  arn    = "${aws_sns_topic.default.arn}"
  policy = "${data.aws_iam_policy_document.sns_topic_policy.json}"
}

locals {
  claims = "${distinct(concat(list("default"), var.claims))}"
  all_claims = ["default", "rds", "cloudwatch"]
  all_statements = [
    {
      sid = "__default_statement_ID"

      actions = [
	"SNS:Subscribe",
	"SNS:SetTopicAttributes",
	"SNS:RemovePermission",
	"SNS:Receive",
	"SNS:Publish",
	"SNS:ListSubscriptionsByTopic",
	"SNS:GetTopicAttributes",
	"SNS:DeleteTopic",
	"SNS:AddPermission",
      ]

      effect    = "Allow"
      resources = ["${aws_sns_topic.default.arn}"]

      principals = [{
	type        = "AWS"
	identifiers = ["*"]
      }]

      condition = [{
	test     = "StringEquals"
	variable = "AWS:SourceOwner"

	values = [
	  "${data.aws_caller_identity.default.account_id}",
	]
      }]
    },
    {
      sid       = "rds"
      actions   = ["sns:Publish"]
      resources = ["${aws_sns_topic.default.arn}"]

      principals = [{
	type        = "Service"
	identifiers = ["rds.amazonaws.com"]
      }]
    },
    {
      statement {
	sid       = "cwe"
	actions   = ["sns:Publish"]
	resources = ["${aws_sns_topic.default.arn}"]

	principals = [{
	  type        = "Service"
	  identifiers = ["events.amazonaws.com"]
	}]
      }
    }
  ]

  statements = "${matchkeys(local.all_statements, local.all_claims, local.claims)}" 
}

data "aws_caller_identity" "default" {}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"
  statement = ["${local.statements}"]
}
