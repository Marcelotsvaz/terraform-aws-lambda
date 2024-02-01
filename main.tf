locals {
	merged_functions = {
		# Merge `function` and `var.defaults` while ignoring null values.
		# Merge nested maps and objects.
		for name, function in var.functions:
		name => {
			for key, value in function:
			key => value != null ?
			try( merge( var.defaults[key], value ), value ) :
			var.defaults[key]
		}
	}
}



# 
# Lambda Function
#-------------------------------------------------------------------------------
resource aws_lambda_function main {
	for_each = local.merged_functions
	
	function_name = "${var.prefix}-${each.key}"
	
	memory_size = each.value.memory
	ephemeral_storage { size = each.value.storage }
	timeout = each.value.timeout
	
	package_type = "Image"
	image_uri = var.image_uri
	role = aws_iam_role.main.arn
	
	image_config {
		command = each.value.command
		entry_point = each.value.entry_point
		working_directory = each.value.working_directory
	}
	
	environment {
		variables = each.value.environment
	}
	
	logging_config {
		log_group = aws_cloudwatch_log_group.main.name
		log_format = "JSON"
		system_log_level = "INFO"
		application_log_level = "INFO"
	}
	
	tags = {
		Name = "${var.tag_prefix} Lambda"
	}
}


resource aws_lambda_function_url main {
	for_each = {
		for name, function in local.merged_functions:
		name => function
		if function.create_url
	}
	
	function_name = aws_lambda_function.main[each.key].function_name
	authorization_type = "NONE"
}



# 
# CloudWatch
#-------------------------------------------------------------------------------
resource aws_cloudwatch_log_group main {
	name = "/aws/lambda/${var.prefix}"
	
	tags = {
		Name = "${var.tag_prefix} Lambda Log Group"
	}
}



# 
# IAM Role
#-------------------------------------------------------------------------------
resource aws_iam_role main {
	name = "${var.prefix}-lambda"
	assume_role_policy = data.aws_iam_policy_document.assume_role.json
	managed_policy_arns = []
	
	inline_policy {
		name = "lambda_logs"
		
		policy = data.aws_iam_policy_document.logs.json
	}
	
	dynamic inline_policy {
		for_each = var.policies
		
		content {
			name = inline_policy.key
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