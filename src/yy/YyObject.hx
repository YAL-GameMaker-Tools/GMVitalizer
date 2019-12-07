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
	var eventList:Array<{
		var id:String;
		var modelName:String;
		var mvc:String;
		var IsDnD:Bool;
		var collisionObjectId:YyGUID;
		var enumb:Int;
		var eventtype:Int;
		var m_owner:String;
	}>;
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
