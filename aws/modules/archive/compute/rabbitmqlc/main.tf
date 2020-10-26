data "aws_iam_policy_document" "policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "template_file" "cloud-init" {
  template = "${file("${path.module}/cloud-init.yaml")}"

  vars {
    sync_node_count = 3
    region          = "${var.aws_region}"
    secret_cookie   = "${var.rabbitmq_secret_cookie}"
    admin_password  = "${var.rabbitmq_admin_password}"
    message_timeout = "${3 * 24 * 60 * 60 * 1000}"    # 3 days
    env             = "${var.env}"
  }
}

resource "aws_iam_role" "role" {
  name               = "rabbitmq-${var.env}"
  assume_role_policy = "${data.aws_iam_policy_document.policy_doc.json}"
}

resource "aws_iam_role_policy" "policy" {
  name = "rabbitmq-${var.env}"
  role = "${aws_iam_role.role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingInstances",
                "ec2:DescribeInstances"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "this" {
  name = "rabbitmq-${var.env}"
  role = "${aws_iam_role.role.name}"
}

resource "aws_launch_configuration" "this" {
  name_prefix = "rabbitmqlc-${var.env}-"
  instance_type = "${var.instance_type}"
  image_id = "${var.image_id}"
  key_name = "${var.key_name}"
  security_groups = ["${var.security_groups}"]
  iam_instance_profile = "${aws_iam_instance_profile.this.id}"
  user_data = "${data.template_file.cloud-init.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}
