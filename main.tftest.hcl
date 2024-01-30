provider aws {
	region = "sa-east-1"
}


variables {
	tag_prefix = "Test Lambda Module"
	prefix = "test_lambda_module"
	
	image_uri = "alpine:3.18.4"
}


run test_environment_without_defaults {
	command = plan
	
	variables {
		functions = {
			main = {
				environment = {
					foo = "bar"
				}
			}
		}
	}
	
	assert {
		condition = aws_lambda_function.main["main"].environment[0].variables["foo"] == "bar"
		error_message = "Environment variable must be present."
	}
}


run test_environment_with_defaults {
	command = plan
	
	variables {
		defaults = {
			environment = {
				only_default = "a"
				both = "b"
			}
		}
		
		functions = {
			main = {
				environment = {
					only_function = "c"
					both = "d"
				}
			}
		}
	}
	
	assert {
		condition = aws_lambda_function.main["main"].environment[0].variables["only_default"] == "a"
		error_message = "Environment variable must be present."
	}
	
	assert {
		condition = aws_lambda_function.main["main"].environment[0].variables["only_function"] == "c"
		error_message = "Environment variable must be present with overridden value."
	}
	
	assert {
		condition = aws_lambda_function.main["main"].environment[0].variables["both"] == "d"
		error_message = "Environment variable must be present."
	}
}