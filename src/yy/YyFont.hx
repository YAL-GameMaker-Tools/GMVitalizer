package yy;

/**
 * ...
 * @author YellowAfterlife
 */
typedef YyFont = {
	var id:String;
	var modelName:String;
	var mvc:String;
	var name:String;
	var AntiAlias:Int;
	var TTFName:String;
	var ascenderOffset:Int;
	var bold:Bool;
	var charset:Int;
	var first:Int;
	var fontName:String;
	var glyphOperations:Int;
	var glyphs:Array<{
		var Key:Int;
		var Value:{
			var id:String;
			var modelName:String;
			var mvc:String;
			var character:Int;
			var h:Int;
			var offset:Int;
			var shift:Int;
			var w:Int;
			var x:Int;
			var y:Int;
		};
	}>;
	var hinting:Int;
	var includeTTF:Bool;
	var interpreter:Int;
	var italic:Bool;
	var kerningPairs:Array<Any>;
	var last:Int;
	var maintainGms1Font:Bool;
	var pointRounding:Int;
	var ranges:Array<{
		var x:Int;
		var y:Int;
	}>;
	var sampleText:String;
	var size:Int;
	var styleName:String;
	var textureGroupId:String;
};