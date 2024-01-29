output function_name {
	description = "Lambda Function name."
	value = aws_lambda_function.main.function_name
}

output arn {
	description = "Lambda Function ARN."
	value = aws_lambda_function.main.arn
}

output invoke_arn {
	description = "Lambda Function invoke ARN."
	value = aws_lambda_function.main.invoke_arn
}

output function_url {
	description = "Lambda Function URL."
	value = one( aws_lambda_function_url.main[*].function_url )
}