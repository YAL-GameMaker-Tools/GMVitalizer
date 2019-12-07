package yy;

/**
 * ...
 * @author YellowAfterlife
 */
typedef YySprite = {
	var id:String;
	var modelName:String;
	var mvc:String;
	var name:String;
	var For3D:Bool;
	var HTile:Bool;
	var VTile:Bool;
	var bbox_bottom:Int;
	var bbox_left:Int;
	var bbox_right:Int;
	var bbox_top:Int;
	var bboxmode:Int;
	var colkind:Int;
	var coltolerance:Int;
	var edgeFiltering:Bool;
	var frames:Array<{
		var id:String;
		var modelName:String;
		var mvc:String;
		var SpriteId:String;
		var compositeImage:{
			var id:String;
			var modelName:String;
			var mvc:String;
			var FrameId:String;
			var LayerId:String;
		};
		var images:Array<{
			var id:String;
			var modelName:String;
			var mvc:String;
			var FrameId:String;
			var LayerId:String;
		}>;
	}>;
	var gridX:Int;
	var gridY:Int;
	var height:Int;
	var layers:Array<{
		var id:String;
		var modelName:String;
		var mvc:String;
		var SpriteId:String;
		var blendMode:Int;
		var isLocked:Bool;
		var name:String;
		var opacity:Int;
		var visible:Bool;
	}>;
	var origin:Int;
	var originLocked:Bool;
	var playbackSpeed:Int;
	var playbackSpeedType:Int;
	var premultiplyAlpha:Bool;
	var sepmasks:Bool;
	var swatchColours:Any;
	var swfPrecision:Float;
	var textureGroupId:String;
	var type:Int;
	var width:Int;
	var xorig:Int;
	var yorig:Int;
};