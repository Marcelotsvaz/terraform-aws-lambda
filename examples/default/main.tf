module test_functions {
	source = "../../"
	
	tag_prefix = "Test Functions"
	prefix = "test_functions"
	
	defaults = {
		environment = {
			environment = "staging"
		}
	}
	
	functions = {
		test = {
			memory = 1024
			timeout = 60
			
			archive_config = {
				runtime = "python3.12"
				filename = data.archive_file.test_functions.output_path
				handler = "main.handler"
			}
			
			policy = [
				{
					actions = [ "ec2:DescribeInstances" ]
					resources = [ "*" ]
				}
			]
		}
	}
}


data archive_file test_functions {
	type = "zip"
	source_dir = "${path.module}/src/"
	output_path = "${path.module}/../../.staging/test_functions.zip"
}