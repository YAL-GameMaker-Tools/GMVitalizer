package yy;

/**
 * ...
 * @author YellowAfterlife
 */
abstract YyProjectResource(Dynamic)
from YyProjectResource22
from YyProjectResource23
{
	public var v22(get, never):YyProjectResource22;
	private inline function get_v22() return this;
	
	public var v23(get, never):YyProjectResource23;
	private inline function get_v23() return this;
}
typedef YyProjectResource23 = {
	id:YyProjectResource23_id,
	order:Int,
}
typedef YyProjectResource23_id = {
	name:String,
	path:String,
}
typedef YyProjectResource22 = {
	?Key:YyGUID,
	?Value:YyProjectResourceValue,
	//
	?name:String,
	?path:String,
};
typedef YyProjectResourceValue = {
	id:YyGUID,
	resourcePath:String,
	resourceType:YyResourceType,
	/** non-standard */
	?resourceName:String,
};
