resource "aws_iam_policy" "policy" {
  name        = "${var.env}-credstash-access"
  description = "Credstash access policy (for ${var.env})"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": "${var.credentials_table}",
            "Effect": "Allow"
        },
        {
            "Action": "kms:Decrypt",
            "Resource": "${var.encryption_key}",
            "Effect": "Allow"
        }
    ]
}
EOF
}
