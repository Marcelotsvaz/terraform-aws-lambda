terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = ">= 4.48"
		}
		
		archive = {
			source = "hashicorp/archive"
			version = ">= 2.2"
		}
	}
	
	required_version = ">= 1.3.6"
}