output functions {
	description = "Outputs for each Lambda function."
	value = {
		for name, function in aws_lambda_function.main:
		name => {
			full_name = aws_lambda_function.main[name].function_name
			arn = aws_lambda_function.main[name].arn
			invoke_arn = aws_lambda_function.main[name].invoke_arn
			url = try( aws_lambda_function_url.main[name].function_url, null )
		}
	}
}