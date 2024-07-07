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
		image_uri = optional( string )
		memory = optional( number, 128 )
		storage = optional( number, 512 )
		timeout = optional( number, 60 )
		create_url = optional( bool, false )
		provisioned_concurrency = optional( number )
		
		command = optional( list( string ) )
		entry_point = optional( list( string ) )
		working_directory = optional( string )
		
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
			image_uri = optional( string )
			memory = optional( number )
			storage = optional( number )
			timeout = optional( number, null )
			create_url = optional( bool )
			provisioned_concurrency = optional( number )
			
			command = optional( list( string ) )
			entry_point = optional( list( string ) )
			working_directory = optional( string )
			
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