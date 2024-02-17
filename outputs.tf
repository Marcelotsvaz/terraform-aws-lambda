output functions {
	description = "Outputs for each Lambda function."
	value = {
		for name, function in aws_lambda_function.main:
		name => {
			arn = aws_lambda_function.main[name].arn
			environment = try( aws_lambda_function.main[name].environment[0].variables, {} )
			full_name = aws_lambda_function.main[name].function_name
			invoke_arn = aws_lambda_function.main[name].invoke_arn
			qualified_arn = aws_lambda_function.main[name].qualified_arn
			qualified_invoke_arn = aws_lambda_function.main[name].qualified_invoke_arn
			url = try( aws_lambda_function_url.main[name].function_url, null )
			version = aws_lambda_function.main[name].version
		}
	}
}