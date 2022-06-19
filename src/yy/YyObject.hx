package yy;

/**
 * ...
 * @author ...
 */
typedef YyObject = {
	var id:YyGUID;
	var modelName:String;
	var mvc:String;
	var name:String;
	var eventList:Array<YyObjectEvent>;
	var maskSpriteId:YyGUID;
	var overriddenProperties:Any;
	var parentObjectId:YyGUID;
	var persistent:Bool;
	var physicsAngularDamping:Float;
	var physicsDensity:Float;
	var physicsFriction:Float;
	var physicsGroup:Int;
	var physicsKinematic:Bool;
	var physicsLinearDamping:Float;
	var physicsObject:Bool;
	var physicsRestitution:Float;
	var physicsSensor:Bool;
	var physicsShape:Int;
	var physicsShapePoints:Array<{
		var id:String;
		var modelName:String;
		var mvc:String;
		var x:Float;
		var y:Float;
	}>;
	var physicsStartAwake:Bool;
	var properties:Any;
	var solid:Bool;
	var spriteId:YyGUID;
	var visible:Bool;
};
abstract YyObjectEvent(Dynamic)
from YyObjectEvent22
from YyObjectEvent23 {
	public var v22(get, never):YyObjectEvent22;
	private inline function get_v22():YyObjectEvent22 return this;
	
	public var v23(get, never):YyObjectEvent23;
	private inline function get_v23():YyObjectEvent23 return this;
	
	public var isV23(get, never):Bool;
	private inline function get_isV23() return this.resourceVersion != null;
}
typedef YyObjectEvent22 = {
	var id:String;
	var modelName:String;
	var mvc:String;
	var IsDnD:Bool;
	var collisionObjectId:YyGUID;
	var enumb:Int;
	var eventtype:Int;
	var m_owner:String;
};
typedef YyObjectEvent23 = {
	var isDnD:Bool;
	var eventNum:Int;
	var eventType:Int;
	var collisionObjectId:Null<{name:String,path:String}>;
}