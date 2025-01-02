provider aws {
	profile = "tests"
}


variables {
	tag_prefix = "Test Functions"
	prefix = "test_functions"
}


run test_environment_without_defaults {
	command = plan
	
	variables {
		functions = {
			test = {
				archive_config = {
					runtime = "python3.12"
					filename = "foo.zip"
					handler = "main.handler"
				}
				
				environment = {
					foo = "bar"
				}
			}
		}
	}
	
	assert {
		condition = aws_lambda_function.main["test"].environment[0].variables["foo"] == "bar"
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
			test = {
				archive_config = {
					runtime = "python3.12"
					filename = "foo.zip"
					handler = "main.handler"
				}
				
				environment = {
					only_function = "c"
					both = "d"
				}
			}
		}
	}
	
	assert {
		condition = aws_lambda_function.main["test"].environment[0].variables["only_default"] == "a"
		error_message = "Environment variable must be present."
	}
	
	assert {
		condition = aws_lambda_function.main["test"].environment[0].variables["only_function"] == "c"
		error_message = "Environment variable must be present."
	}
	
	assert {
		condition = aws_lambda_function.main["test"].environment[0].variables["both"] == "d"
		error_message = "Environment variable must be present with overridden value."
	}
}


run test_object_merging {
	command = plan
	
	variables {
		defaults = {
			archive_config = {
				runtime = "python3.12"
				filename = "foo.zip"
			}
		}
		
		functions = {
			test = {
				archive_config = {
					handler = "main.handler"
				}
			}
		}
	}
	
	assert {
		condition = aws_lambda_function.main["test"].runtime == "python3.12"
		error_message = "Default value must be present."
	}
	
	assert {
		condition = aws_lambda_function.main["test"].filename == "foo.zip"
		error_message = "Default value must be present."
	}
	
	assert {
		condition = aws_lambda_function.main["test"].handler == "main.handler"
		error_message = "Overridden value must be present."
	}
}