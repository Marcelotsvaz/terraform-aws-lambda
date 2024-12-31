terraform {
	required_version = ">= 1.3.6"
	
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = ">= 5.34.0"
		}
	}
}