output functions {
	description = "Outputs for each Lambda function."
	value = {
		for name, function in aws_lambda_function.main:
		name => {
			environment = try( aws_lambda_function.main[name].environment[0].variables, {} )
			version = aws_lambda_function.main[name].version
			full_name = aws_lambda_function.main[name].function_name
			
			arn = aws_lambda_function.main[name].arn
			qualified_arn = aws_lambda_function.main[name].qualified_arn
			invoke_arn = aws_lambda_function.main[name].invoke_arn
			
			alias_name = try( aws_lambda_alias.main[name].name, null )
			alias_arn = try( aws_lambda_alias.main[name].arn, null )
			alias_invoke_arn = try( aws_lambda_alias.main[name].invoke_arn, null )
			
			url = try( aws_lambda_function_url.main[name].function_url, null )
		}
	}
}