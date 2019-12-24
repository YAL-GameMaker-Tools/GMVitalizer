package vit;
import yy.*;
import haxe.io.Path;
import sys.io.File;
import tools.Alias;
import tools.PNGTools;
import tools.SfGmx;

/**
 * ...
 * @author YellowAfterlife
 */
class VitTileset {
	/** prefix for tileset backgrounds */
	public static inline var prefix:String = "gmv_tsb_";
	//
	public static inline var maskMax = 1 << 31;
	public static inline var maskRotate = 1 << 30;
	public static inline var maskFlip = 1 << 29;
	public static inline var maskMirror = 1 << 28;
	public static inline var maskIndex = (1 << 19) - 1;
	//
	public var name:Ident;
	public var tileset:YyTileset;
	public var background:Ident;
	public var tileCount:Int;
	public var tileCols:Int;
	public var tileWidth:Int;
	public var tileHeight:Int;
	public var tilePadX:Int;
	public var tilePadY:Int;
	public var tileMulX:Int;
	public var tileMulY:Int;
	public function new() {
		
	}
	//
	public static function pre(name:String, q:YyTileset) {
		Sys.println('Preparing $name...');
		var t = new VitTileset();
		t.name = name;
		t.background = prefix + name;
		t.tileWidth = q.tilewidth;
		t.tileHeight = q.tileheight;
		t.tilePadX = q.out_tilehborder;
		t.tilePadY = q.out_tilevborder;
		t.tileMulX = t.tilePadX * 2 + t.tileWidth;
		t.tileMulY = t.tilePadY * 2 + t.tileHeight;
		t.tileCount = q.tile_count;
		t.tileCols = q.out_columns;
		//
		var pj = VitProject.current;
		pj.tilesets[q.id] = t;
		//
		if (q.sprite_no_export) {
			pj.noExport[q.spriteId] = true;
		}
		//
	}
	public static function proc(name:String, t:VitTileset, inPath:FullPath, outPath:FullPath) {
		Sys.println('Converting $name...');
		var q = t.tileset;
		var q0 = new SfGmx("background");
		var q1:SfGmx;
		q0.addBoolChild("istileset", true);
		q0.addIntChild("tilewidth", t.tileWidth);
		q0.addIntChild("tileheight", t.tileHeight);
		q0.addIntChild("tilexoff", t.tilePadX);
		q0.addIntChild("tileyoff", t.tilePadY);
		q0.addIntChild("tilehsep", t.tilePadX * 2);
		q0.addIntChild("tilevsep", t.tilePadY * 2);
		q0.addIntChild("HTile", 0);
		q0.addIntChild("VTile", 0);
		q1 = q0.addEmptyChild("TextureGroups");
		q1.addIntChild("TextureGroup0", 0);
		q0.addIntChild("For3D", 0);
		//
		var inTilesPath = Path.directory(inPath) + '/output_tileset.png';
		var inf = PNGTools.getInfo(inTilesPath);
		//
		q0.addIntChild("width", inf.width);
		q0.addIntChild("height", inf.height);
		q0.addTextChild("data", 'images\\$name.png');
		File.copy(inTilesPath, Path.directory(outPath) + '/images/$name.png');
		File.saveContent(outPath + '.background.gmx', q0.toGmxString());
		//
		var pj = VitProject.current;
		var rb = pj.tilesetInit;
		var ts = t.name;
		rb.addFormat("globalvar %s; ", ts);
		rb.addFormat("%s = tileset_create(%s, %d,%d, %d,%d, %d,%d);\r\n",
			ts, t.background,
			t.tileCount, t.tileCols,
			t.tileWidth, t.tileHeight,
			t.tilePadX, t.tilePadY);
	}
}