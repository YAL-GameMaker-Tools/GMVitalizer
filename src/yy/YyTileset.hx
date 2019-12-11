package yy;

/**
 * @author YellowAfterlife
 */
typedef YyTileset = {
	id:GUID,
	modelName:String,
	mvc:String,
	name:String,
	auto_tile_sets:Array<Any>,
	macroPageTiles:{
		SerialiseData:Any,
		SerialiseHeight:Int,
		SerialiseWidth:Int,
		TileSerialiseData:Array<Any>
	},
	out_columns:Int,
	out_tilehborder:Int,
	out_tilevborder:Int,
	spriteId:GUID,
	sprite_no_export:Bool,
	textureGroupId:GUID,
	tile_animation:{
		AnimationCreationOrder:Any,
		FrameData:Array<Int>,
		SerialiseFrameCount:Int
	},
	tile_animation_frames:Array<Any>,
	tile_animation_speed:Int,
	tile_count:Int,
	tileheight:Int,
	tilehsep:Int,
	tilevsep:Int,
	tilewidth:Int,
	tilexoff:Int,
	tileyoff:Int
};