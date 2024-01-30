# 
# Name
#-------------------------------------------------------------------------------
variable tag_prefix {
	description = "Pretty name for resource tags."
	type = string
}

variable prefix {
	description = "Prefix for resources that require an unique name."
	type = string
}


# 
# Function
#-------------------------------------------------------------------------------
variable memory {
	description = "Amount of memory in MiB."
	type = number
	default = 128
}

variable storage {
	description = "Amount of ephemeral storage in MiB."
	type = number
	default = 512
}

variable timeout {
	description = "Function timeout."
	type = number
	default = 60
}

variable create_url {
	description = "Create URL for calling the function."
	type = bool
	default = false
}


# 
# Images
#-------------------------------------------------------------------------------
variable image_uri {
	description = "ECR image URI."
	type = string
}

variable command {
	description = "Override command passed to image's entry point."
	type = list( string )
	default = null
}

variable entry_point {
	description = "Override image's entry point."
	type = list( string )
	default = null
}

variable working_directory {
	description = "Override image's working directory."
	type = string
	default = null
}


# 
# Environment
#-------------------------------------------------------------------------------
variable environment {
	description = "Environment variables for the container."
	type = map( string )
	default = {}
}


# 
# Permissions
#-------------------------------------------------------------------------------
variable policies {
	description = "Set of policies for the function's IAM role."
	type = set(
		object( {
			json = string
		} )
	)
	default = []
}



# 
# Locals
#-------------------------------------------------------------------------------
locals {
	lambda_function_name = var.prefix	# Avoid cyclic dependency.
}