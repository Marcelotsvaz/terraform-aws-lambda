# 
# Lambda Function
#-------------------------------------------------------------------------------
resource aws_lambda_function main {
	function_name = local.lambda_function_name
	
	memory_size = var.memory
	ephemeral_storage { size = var.storage }
	timeout = var.timeout
	
	package_type = "Image"
	image_uri = var.image_uri
	role = aws_iam_role.main.arn
	
	image_config {
		command = var.command
		entry_point = var.entry_point
		working_directory = var.working_directory
	}
	
	environment {
		variables = var.environment
	}
	
	logging_config {
		log_group = aws_cloudwatch_log_group.main.name
		log_format = "JSON"
	}
	
	tags = {
		Name = "${var.tag_prefix} Lambda"
	}
}


resource aws_lambda_function_url main {
	count = var.create_url ? 1 : 0
	
	function_name = aws_lambda_function.main.function_name
	authorization_type = "NONE"
}



# 
# CloudWatch
#-------------------------------------------------------------------------------
resource aws_cloudwatch_log_group main {
	name = "/aws/lambda/${local.lambda_function_name}"
	
	tags = {
		Name = "${var.tag_prefix} Lambda Log Group"
	}
}



# 
# IAM Role
#-------------------------------------------------------------------------------
resource aws_iam_role main {
	name = var.prefix
	assume_role_policy = data.aws_iam_policy_document.assume_role.json
	managed_policy_arns = []
	
	inline_policy {
		name = "${var.prefix}-logs"
		
		policy = data.aws_iam_policy_document.logs.json
	}
	
	dynamic inline_policy {
		for_each = var.policies
		
		content {
			name = "${var.prefix}-policy"
			
			policy = inline_policy.value.json
		}
	}
	
	tags = {
		Name = "${var.tag_prefix} Lambda Role"
	}
}


data aws_iam_policy_document assume_role {
	statement {
		sid = "lambdaAssumeRole"
		actions = [ "sts:AssumeRole" ]
		principals {
			type = "Service"
			identifiers = [ "lambda.amazonaws.com" ]
		}
	}
}


data aws_iam_policy_document logs {
	statement {
		sid = "putCloudwatchLogs"
		actions = [
			"logs:CreateLogStream",
			"logs:PutLogEvents",
		]
		resources = [ "${aws_cloudwatch_log_group.main.arn}:*" ]
	}
}