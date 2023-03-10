# 
# Terraform AWS Lambda Module
# 
# 
# Author: Marcelo Tellier Sartori Vaz <marcelotsvaz@gmail.com>



terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = "~> 4.48"
		}
	}
	
	required_version = ">= 1.3.6"
}