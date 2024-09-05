locals {
	merged_functions = {
		# Merge `function` and `var.defaults` while ignoring null values.
		# Merge nested maps and objects.
		for name, function in var.functions:
		name => {
			for key, value in function:
			key => value == null ?
			var.defaults[key] :
			key == "policy" ?
			setunion( var.defaults[key], value ) :
			try( merge( var.defaults[key], value ), value )
		}
	}
}


check merged_functions {
	assert {
		condition = alltrue( [
			for function in local.merged_functions:
			function.archive_config == null || function.image_config == null
		] )
		error_message = "Only one of `archive_config` or `image_config` can be defined."
	}
}



# 
# Lambda Function
#-------------------------------------------------------------------------------
resource aws_lambda_function main {
	for_each = local.merged_functions
	
	function_name = "${var.prefix}-${each.key}"
	publish = each.value.publish || each.value.provisioned_concurrency != null
	
	memory_size = each.value.memory
	ephemeral_storage { size = each.value.storage }
	timeout = each.value.timeout
	
	package_type = each.value.archive_config != null ? "Zip" : "Image"
	
	runtime = try( each.value.archive_config.runtime, null )
	filename = try( each.value.archive_config.filename, null )
	source_code_hash = try( filebase64sha256( each.value.archive_config.filename ), null )
	handler = try( each.value.archive_config.handler, null )
	
	image_uri = try( each.value.image_config.image_uri, null )
	dynamic image_config {
		for_each = each.value.image_config != null ? [ true ] : []
		
		content {
			working_directory = each.value.image_config.working_directory
			entry_point = each.value.image_config.entry_point
			command = each.value.image_config.command
		}
	}
	
	dynamic environment {
		for_each = length( each.value.environment ) > 0 ? [ true ] : []
		
		content {
			variables = each.value.environment
		}
	}
	
	role = aws_iam_role.main[each.key].arn
	
	logging_config {
		log_group = aws_cloudwatch_log_group.main[each.key].name
		log_format = "JSON"
		system_log_level = "INFO"
		application_log_level = "INFO"
	}
	
	tags = {
		Name = "${var.tag_prefix} Lambda"
	}
}


resource aws_lambda_function_event_invoke_config main {
	for_each = local.merged_functions
	
	function_name = aws_lambda_function.main[each.key].function_name
	maximum_retry_attempts = each.value.async_retry_count
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


resource aws_lambda_provisioned_concurrency_config main {
	for_each = {
		for name, function in local.merged_functions:
		name => function
		if function.provisioned_concurrency != null
	}
	
	function_name = aws_lambda_function.main[each.key].function_name
	qualifier = aws_lambda_alias.main[each.key].name
	provisioned_concurrent_executions = each.value.provisioned_concurrency
}


resource aws_lambda_alias main {
	for_each = local.merged_functions
	
	function_name = aws_lambda_function.main[each.key].function_name
	function_version = aws_lambda_function.main[each.key].version
	name = "latest"
}



# 
# CloudWatch
#-------------------------------------------------------------------------------
resource aws_cloudwatch_log_group main {
	for_each = local.merged_functions
	
	name = "/aws/lambda/${each.value.edge_function ? "us-east-1." : "" }${var.prefix}-${each.key}"
	
	tags = {
		Name = "${var.tag_prefix} Lambda Log Group"
	}
}



# 
# IAM Role
#-------------------------------------------------------------------------------
resource aws_iam_role main {
	for_each = local.merged_functions
	
	name = "${var.prefix}-${each.key}-lambda"
	assume_role_policy = data.aws_iam_policy_document.assume_role.json
	managed_policy_arns = []
	
	inline_policy {
		name = "cloudwatch"
		policy = data.aws_iam_policy_document.cloudwatch[each.key].json
	}
	
	dynamic inline_policy {
		for_each = length( each.value.policy ) > 0 ? [ true ] : []
		
		content {
			name = "main"
			policy = data.aws_iam_policy_document.main[each.key].json
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
			identifiers = [
				"lambda.amazonaws.com",
				"edgelambda.amazonaws.com",
			]
		}
	}
}


data aws_iam_policy_document cloudwatch {
	for_each = local.merged_functions
	
	statement {
		sid = "putCloudwatchLogs"
		actions = [
			"logs:CreateLogStream",
			"logs:PutLogEvents",
		]
		resources = [ "${aws_cloudwatch_log_group.main[each.key].arn}:*" ]
	}
	
	statement {
		sid = "putXrayTraces"
		actions = [
			"xray:GetSamplingRules",
			"xray:GetSamplingTargets",
			"xray:PutTraceSegments",
			"xray:PutTelemetryRecords",
		]
		resources = [ "*" ]
	}
}


data aws_iam_policy_document main {
	for_each = local.merged_functions
	
	dynamic statement {
		for_each = each.value.policy
		
		content {
			sid = statement.value.sid
			actions = statement.value.actions
			resources = statement.value.resources
		}
	}
}