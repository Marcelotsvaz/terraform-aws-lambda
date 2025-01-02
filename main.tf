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
	
	role = module.role[each.key].arn
	
	logging_config {
		log_group = aws_cloudwatch_log_group.main[each.key].name
		log_format = "JSON"
		system_log_level = "INFO"
		application_log_level = "INFO"
	}
	
	tracing_config {
		mode = each.value.enable_tracing ? "Active" : "PassThrough"
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
module role {
	for_each = local.merged_functions
	
	source = "gitlab.com/vaz-projects/iam-role/aws"
	version = "0.2.0"
	
	tag_prefix = "${var.tag_prefix} Lambda"
	prefix = "${var.prefix}-${each.key}"
	
	assumed_by = {
		( each.value.edge_function ? "lambda_at_edge" : "lambda" ) = {}
	}
	
	policy = concat( each.value.policy, [
		each.value.edge_function ? {
			actions = [
				"logs:CreateLogGroup",
				"logs:CreateLogStream",
				"logs:PutLogEvents",
			]
			resources = [ "*" ]
		} : {
			actions = [
				"logs:CreateLogStream",
				"logs:PutLogEvents",
			]
			resources = [ "${aws_cloudwatch_log_group.main[each.key].arn}:*" ]
		},
		{
			actions = [
				"xray:GetSamplingRules",
				"xray:GetSamplingTargets",
				"xray:PutTraceSegments",
				"xray:PutTelemetryRecords",
			]
			resources = [ "*" ]
		},
	] )
}