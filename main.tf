resource "aws_iam_role" "role" {
  name = "${var.env}-${var.component}-role"

   assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

   tags = merge(
    local.common_tags,
    { Name = "${var.env}-${var.component}-role" }
  )
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.env}-${var.component}-role"
  role = aws_iam_role.role.name
}


resource "aws_security_group" "main" {
  name        = "${var.env}-${var.component}-security-group"
  description = "${var.env}-${var.component}-security-group"
  vpc_id      = var.vpc_id

  ingress {
    description      = "HTTP"
    from_port        = var.app_port
    to_port          = var.app_port
    protocol         = "tcp"
    cidr_blocks      = var.allow_cidr
  }
  
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.bastion_cidr
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

   tags = merge(
    local.common_tags,
    { Name = "${var.env}-${var.component}-security-group" }
  )
  
  }
  resource "aws_iam_policy" "policy" {
  name        = "${var.env}-${var.component}-parameter-store-policy"
  path        = "/"
  description = "${var.env}-${var.component}-parameter-store-policy"

  policy = jsonencode({
  
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameterHistory",
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": [
            "arn:aws:ssm:us-east-1:998626143474:parameter/${var.env}.${var.component}*"
              ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ssm:DescribeParameters",
            "Resource": "*"
        }
    ]
})
   
} 
  
  resource "aws_iam_role_policy_attachment" "role-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
resource "aws_security_group" "rabbitmq" {
  name        = "${var.env}-rabbitmq-security-group"
  description = "${var.env}-rabbitmq-security-group"
  vpc_id      = var.vpc_id

  ingress {
    description      = "rabbitmq"
    from_port        = 5672
    to_port          = 5672
    protocol         = "tcp"
    cidr_blocks      = var.allow_cidr
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.bastion_cidr
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

   tags = merge(
    local.common_tags,
    { Name = "${var.env}-rabbitmq-security-group" }
  )
  
  }
  
#   resource "aws_mq_configuration" "rabbitmq" {
#   description    = "${var.env}-rabbitmq-configuration" 
#   name           ="${var.env}-rabbitmq-configuration" 
#   engine_type    = var.engine_type
#   engine_version = var.engine_version
#   data = ""

# }
  
  
  #we moved to service to ec2 because rabbitmq not support
  
# resource "aws_mq_broker" "rabbitmq" {
#   broker_name = "${var.env}-rabbitmq" 
#   deployment_mode = var.deployment_mode
#   engine_type    = var.engine_type
#   engine_version = var.engine_version
#   host_instance_type = var.host_instance_type
#   security_groups    = [aws_security_group.rabbitmq.id]
#   subnet_ids        =  var.deployment_mode == "SINGLE_INSTANCE" ? [var.subnet_ids[0]] : var.subnet_ids
#   //subnet_ids         = var.deployment_mode == "SINGLE_INSTANCE" ? [var.subnet_ids[0]] : var.subnet_ids


#   # configuration {
#   #   id       = aws_mq_configuration.rabbitmq.id
#   #   revision = aws_mq_configuration.rabbitmq.latest_revision
#   # }
  
#   encryption_options {
#     use_aws_owned_key = false
#     kms_key_id        = data.aws_kms_key.key.arn
#   }
  
#   user {
#     username = data.aws_ssm_parameter.USER.value
#     password = data.aws_ssm_parameter.PASS.value
#   }
# }

//resource "aws_mq_broker" "rabbitmq" {
//  broker_name        = "${var.env}-rabbitmq"
//  deployment_mode    = var.deployment_mode
//  engine_type        = var.engine_type
//  engine_version     = var.engine_version
//  host_instance_type = var.host_instance_type
//  security_groups    = [aws_security_group.rabbitmq.id]
//  subnet_ids         = var.deployment_mode == "SINGLE_INSTANCE" ? [var.subnet_ids[0]] : var.subnet_ids
//
//  //  configuration {
//  //    id       = aws_mq_configuration.rabbitmq.id
//  //    revision = aws_mq_configuration.rabbitmq.latest_revision
//  //  }
//
//  encryption_options {
//    use_aws_owned_key = false
//    kms_key_id        = data.aws_kms_key.key.arn
//  }
//
//  user {
//    username = data.aws_ssm_parameter.USER.value
//    password = data.aws_ssm_parameter.PASS.value
//  }
//
//}


# resource "aws_ssm_parameter" "rabbitmq_ENDPOINT" {
#   name  = "${var.env}.rabbitmq.ENDPOINT"
#   type  = "String"
#   value = replace(replace(aws_mq_broker.rabbitmq.instances.0.endpoints.0,"amqps://" , ""),":5671" , "")
# }

# Request a spot instance at $0.03
resource "aws_spot_instance_request" "raabbitmq" {
  ami           = data.aws_ami.centos8.image_id
  instance_type = "t3.small"
  subnet_id = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.rabbitmq.id]
  wait_for_fulfillment = true
    
  user_data = base64encode(templatefile("${path.module}/user-data.sh", { component = "rabbitmq", env = var.env }))
  iam_instance_profile = aws_iam_instance_profile.name
  tags = merge(
    local.common_tags,
    { Name = "${var.env}-rabbitmq" }
  )
}

resource "aws_route53_record" "rabbitmq" {
  zone_id = "Z040551911633GDXPWZA8"
  name    =  "rabbitmq.${var.env}.devopsg70.online"
  type    = "A"
  ttl     = 30
  records = [aws_spot_instance_request.raabbitmq.private_ip]
}