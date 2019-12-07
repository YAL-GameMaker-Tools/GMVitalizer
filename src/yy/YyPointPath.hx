package yy;

/**
 * ...
 * @author json2typedef
 */
typedef YyPointPath = {
	var id:String;
	var modelName:String;
	var mvc:String;
	var name:String;
	var closed:Bool;
	var hsnap:Int;
	var kind:Int;
	var points:Array<{
		var id:String;
		var modelName:String;
		var mvc:String;
		var x:Int;
		var y:Int;
		var speed:Int;
	}>;
	var precision:Int;
	var vsnap:Int;
};