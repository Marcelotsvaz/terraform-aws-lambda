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
		
		archive_config = optional(
			object( {
				runtime = optional( string )
				filename = optional( string )
				handler = optional( string )
			} )
		)
		
		image_config = optional(
			object( {
				image_uri = optional( string )
				working_directory = optional( string )
				entry_point = optional( list( string ) )
				command = optional( list( string ) )
			} )
		)
		
		environment = optional( map( string ), {} )
		
		policy = optional(
			set(
				object( {
					sid = optional( string )
					actions = set( string )
					resources = set( string )
				} )
			),
			[]
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
			
			archive_config = optional(
				object( {
					runtime = optional( string )
					filename = optional( string )
					handler = optional( string )
				} )
			)
			
			image_config = optional(
				object( {
					image_uri = optional( string )
					working_directory = optional( string )
					entry_point = optional( list( string ) )
					command = optional( list( string ) )
				} )
			)
			
			environment = optional( map( string ) )
			
			policy = optional(
				set(
					object( {
						sid = optional( string )
						actions = set( string )
						resources = set( string )
					} )
				)
			)
		} )
	)
}