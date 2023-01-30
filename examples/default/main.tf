# 
# Terraform AWS Lambda Module
# 
# 
# Author: Marcelo Tellier Sartori Vaz <marcelotsvaz@gmail.com>



module webhook_handler {
	source = "./module/lambda"
	
	name = "Webhook Handler"
	identifier = "webhookHandler"
	
	source_dir = "${path.module}/files/src"
	handler = "manager.webhookHandler.main"
	layers = [ aws_lambda_layer_version.python_packages.arn ]
	parameters = { jobMatcherFunctionArn = module.job_matcher.arn }
	
	policies = [ data.aws_iam_policy_document.webhook_handler ]
}


data aws_iam_policy_document webhook_handler {
	statement {
		sid = "invokeJobMatcherFunction"
		actions = [ "lambda:InvokeFunction" ]
		resources = [ module.job_matcher.arn ]
	}
}