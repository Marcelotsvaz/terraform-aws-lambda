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
# Functions
#-------------------------------------------------------------------------------
variable defaults {
	description = "Default values for all Lambda functions."
	type = object( {
		memory = optional( number, 128 )
		storage = optional( number, 512 )
		timeout = optional( number, 60 )
		async_retry_count = optional( number, 0 )
		create_url = optional( bool, false )
		publish = optional( bool, false )
		provisioned_concurrency = optional( number )
		edge_function = optional( bool, false )
		enable_tracing = optional( bool, true )
		
		archive_config = optional(
			object( {
				runtime = optional( string )
				filename = optional( string )
				handler = optional( string )
			} ),
		)
		
		image_config = optional(
			object( {
				image_uri = optional( string )
				working_directory = optional( string )
				entry_point = optional( list( string ) )
				command = optional( list( string ) )
			} ),
		)
		
		environment = optional( map( string ), {} )
		
		policy = optional(
			list(
				object( {
					sid = optional( string )
					actions = set( string )
					resources = set( string )
				} )
			),
			[],
		)
	} )
	default = {}
}

variable functions {
	description = "Definitions for multiple Lambda functions sharing the same code."
	type = map(
		object( {
			memory = optional( number )
			storage = optional( number )
			timeout = optional( number )
			async_retry_count = optional( number )
			create_url = optional( bool )
			publish = optional( bool )
			provisioned_concurrency = optional( number )
			edge_function = optional( bool )
			enable_tracing = optional( bool )
			
			archive_config = optional(
				object( {
					runtime = optional( string )
					filename = optional( string )
					handler = optional( string )
				} ),
			)
			
			image_config = optional(
				object( {
					image_uri = optional( string )
					working_directory = optional( string )
					entry_point = optional( list( string ) )
					command = optional( list( string ) )
				} ),
			)
			
			environment = optional( map( string ) )
			
			policy = optional(
				list(
					object( {
						sid = optional( string )
						actions = set( string )
						resources = set( string )
					} ),
				),
				[],
			)
		} )
	)
}



# 
# Locals
#-------------------------------------------------------------------------------
locals {
	merged_functions = {
		# Merge `function` and `var.defaults` while ignoring null values.
		# Merge nested maps and objects.
		# Concatenate policies.
		for name, function in var.functions:
		name => merge(
			var.defaults,
			{
				for key, value in function:
				key => try(
					merge( var.defaults[key], { for key2, value2 in value: key2 => value2 if value2 != null } ),
					value,
				)
				if value != null
			},
			{
				policy = concat( var.defaults.policy, function.policy )
			},
		)
	}
}


check merged_functions {
	assert {
		condition = alltrue( [
			for function in local.merged_functions:
			function.archive_config == null || function.image_config == null
		] )
		error_message = "Only one of `archive_config` or `image_config` can be defined."
	}
	
	assert {
		condition = alltrue( [
			for function in local.merged_functions:
			(
				function.archive_config.runtime != null &&
				function.archive_config.filename != null &&
				function.archive_config.handler != null
			)
		] )
		error_message = "`runtime`, `filename`, and `handler` must be defined when using `archive_config`."
	}
}