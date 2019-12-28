package yy;

/**
 * @author YellowAfterlife
 */
typedef YyTileset = {
	id:YyGUID,
	modelName:String,
	mvc:String,
	name:String,
	auto_tile_sets:Array<Any>,
	macroPageTiles:{
		SerialiseData:Any,
		SerialiseHeight:Int,
		SerialiseWidth:Int,
		TileSerialiseData:Array<Int>
	},
	out_columns:Int,
	out_tilehborder:Int,
	out_tilevborder:Int,
	spriteId:YyGUID,
	sprite_no_export:Bool,
	textureGroupId:YyGUID,
	tile_animation:{
		AnimationCreationOrder:Any,
		FrameData:Array<Int>,
		SerialiseFrameCount:Int
	},
	tile_animation_frames:Array<{
		id:YyGUID,
		modelName:String,
		mvc:String,
		frames:Array<Int>,
		name:String
	}>,
	tile_animation_speed:Float,
	tile_count:Int,
	tileheight:Int,
	tilehsep:Int,
	tilevsep:Int,
	tilewidth:Int,
	tilexoff:Int,
	tileyoff:Int
};