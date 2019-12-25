package vit ;
import haxe.Json;
import haxe.ds.Map;
import haxe.io.Path;
import sys.io.File;
import yy.*;
import tools.StringBuilder;
import yy.YyRoom;
import tools.SfGmx;
import Ruleset;

/**
 * ...
 * @author YellowAfterlife
 */
class VitRoom {
	public static function proc(name:String, q:YyRoom, inPath:String, outPath:String) {
		Sys.println('Converting $name...');
		var inDir = Path.directory(inPath);
		var r = new SfGmx("room");
		var cc = new StringBuilder();
		var pj = VitProject.current;
		//
		var layers = q.layers;
		var backgrounds:Array<YyRoomLayer> = [];
		var bgColorLayer:YyRoomLayer = null;
		{
			var li = layers.length;
			while (--li >= 0) {
				var l = layers[li];
				if (l.modelName != "GMRBackgroundLayer") break;
				if (backgrounds.length == 0 && l.spriteId == YyGUID.zero) {
					bgColorLayer = l;
				}
				backgrounds.unshift(l);
				l.gmvBgIndex = 8 - backgrounds.length;
				if (backgrounds.length >= 8) break;
			}
		};
		//
		r.addTextChild("caption", "");
		r.addIntChild("width", q.roomSettings.Width);
		r.addIntChild("height", q.roomSettings.Height);
		r.addIntChild("vsnap", 32);
		r.addIntChild("hsnap", 32);
		r.addIntChild("isometric", 0);
		r.addIntChild("speed", pj.gameSpeed);
		r.addBoolChild("persistent", q.roomSettings.persistent);
		if (bgColorLayer != null) {
			r.addIntChild("colour", Std.int(bgColorLayer.colour.Value % 0x1000000));
			r.addBoolChild("showcolour", true);
		} else {
			r.addIntChild("colour", 0);
			r.addBoolChild("showcolour", false);
		}
		//
		var rccNode = r.addTextChild("code", "");
		r.addBoolChild("enableViews", q.viewSettings.enableViews);
		r.addBoolChild("clearViewBackground", q.viewSettings.clearViewBackground);
		r.addBoolChild("clearDisplayBuffer", q.viewSettings.clearDisplayBuffer);
		//
		var makerSettings = r.addEmptyChild("makerSettings");
		makerSettings.addIntChild("isSet", 0);
		makerSettings.addIntChild("w", 0);
		makerSettings.addIntChild("h", 0);
		makerSettings.addIntChild("showGrid", 0);
		makerSettings.addIntChild("showObjects", 0);
		makerSettings.addIntChild("showTiles", 0);
		makerSettings.addIntChild("showBackgrounds", 0);
		makerSettings.addIntChild("showForegrounds", 0);
		makerSettings.addIntChild("showViews", 0);
		makerSettings.addIntChild("deleteUnderlyingObj", 0);
		makerSettings.addIntChild("deleteUnderlyingTiles", 0);
		makerSettings.addIntChild("page", 0);
		makerSettings.addIntChild("xoffset", 0);
		makerSettings.addIntChild("yoffset", 0);
		//
		var rBgs = r.addEmptyChild("backgrounds");
		for (i in 0 ... 8) {
			var rBg = rBgs.addEmptyChild("background");
			rBg.setInt("visible", 0);
			rBg.setInt("foreground", 0);
			rBg.set("name", "");
			rBg.setInt("x", 0);
			rBg.setInt("y", 0);
			rBg.setInt("htiled", -1);
			rBg.setInt("vtiled", -1);
			rBg.setInt("hspeed", 0);
			rBg.setInt("vspeed", 0);
			rBg.setInt("stretch", 0);
		}
		//
		var rViews = r.addEmptyChild("views");
		for (view in q.views) {
			var rView = rViews.addEmptyChild("view");
			rView.setInt("visible", view.visible ? -1 : 0);
			var obj = pj.objectNames[view.objId];
			rView.set("objName", obj != null ? obj : "<undefined>");
			rView.setFloat("xview", view.xview);
			rView.setFloat("yview", view.yview);
			rView.setFloat("wview", view.wview);
			rView.setFloat("hview", view.hview);
			rView.setFloat("xport", view.xport);
			rView.setFloat("yport", view.yport);
			rView.setFloat("wport", view.wport);
			rView.setFloat("hport", view.hport);
			rView.setFloat("hborder", view.hborder);
			rView.setFloat("vborder", view.vborder);
			rView.setFloat("hspeed", view.hspeed);
			rView.setFloat("vspeed", view.vspeed);
		}
		//
		var rInsts = r.addEmptyChild("instances");
		var rTiles = r.addEmptyChild("tiles");
		{ // add the "layer init" instance
			Ruleset.includeIdent("obj_gmv_room_init");
			var ri = rInsts.addEmptyChild("instance");
			ri.set("objName", "obj_gmv_room_init");
			ri.set("x", "obj_gmv_room_init");
			ri.setFloat("x", -100);
			ri.setFloat("y", 100);
			ri.set("name", "__gmv_room_init_" + name);
			ri.set("locked", "0");
			ri.set("code", "");
			ri.setFloat("scaleX", 1);
			ri.setFloat("scaleY", 1);
			ri.set("colour", "4294967295");
			ri.setFloat("rotation", 0);
		};
		//
		r.addBoolChild("PhysicsWorld", q.physicsSettings.PhysicsWorld);
		r.addIntChild("PhysicsWorldTop", 0);
		r.addIntChild("PhysicsWorldLeft", 0);
		r.addIntChild("PhysicsWorldRight", q.roomSettings.Width);
		r.addIntChild("PhysicsWorldBottom", q.roomSettings.Height);
		r.addFloatChild("PhysicsWorldGravityX", q.physicsSettings.PhysicsWorldGravityX);
		r.addFloatChild("PhysicsWorldGravityY", q.physicsSettings.PhysicsWorldGravityY);
		r.addFloatChild("PhysicsWorldPixToMeters", q.physicsSettings.PhysicsWorldPixToMeters);
		//
		var instMap = new Map<YyGUID, YyRoomInstance>();
		var instGmx = new Map<YyGUID, SfGmx>();
		var vl:String = null, vb:String = null;
		function printLayerRec(l:YyRoomLayer):Void {
			if (l.modelName == "GMRLayer") {
				for (l1 in l.layers) printLayerRec(l1);
				return;
			}
			var lz = l.depth;
			if (vl == null) {
				vl = "l_layer";
				cc.add("var ");
			}
			cc.addFormat('%s = layer_create(%s, %d);\r\n', vl, Json.stringify(l.name), lz);
			Ruleset.includeIdent("layer_create");
			switch (l.modelName) {
				case "GMRInstanceLayer": {
					Ruleset.includeIdent("obj_gmv_blank");
					if (l.instances.length > 0) Ruleset.includeIdent("gmv_instance_prepare");
					for (o in l.instances) {
						var objName = pj.objectNames[o.objId];
						if (objName == null) continue;
						instMap.set(o.id, o);
						var ri:SfGmx = new SfGmx("instance");
						ri.set("objName", objName);
						if (o.x % 1 != 0) {
							var rx = Math.round(o.x);
							ri.setFloat("x", rx);
							cc.addFormat("%s.x += %f;\r\n", o.name, o.x - rx);
						} else ri.setFloat("x", o.x);
						if (o.y % 1 != 0) {
							var ry = Math.round(o.y);
							ri.setFloat("y", ry);
							cc.addFormat("%s.y += %f;\r\n", o.name, o.y - ry);
						} else ri.setFloat("y", o.y);
						ri.set("name", o.name);
						var occ = "";
						if (o.creationCodeFile != "") try {
							occ = File.getContent(inDir + "/" + o.creationCodeFile);
							if (occ != "") {
								occ = StringTools.replace(occ, "\t", "    ");
							}
						} catch (_:Dynamic) {};
						ri.set("locked", "0");
						ri.set("code", occ);
						ri.setFloat("scaleX", o.scaleX);
						ri.setFloat("scaleY", o.scaleY);
						ri.setInt("colour", o.colour.Value);
						ri.setFloat("rotation", o.rotation);
						instGmx[o.id] = ri;
						//
						cc.addFormat("%s.depth = %d;\r\n", o.name, lz);
					}
				};
				case "GMRBackgroundLayer": {
					Ruleset.includeIdent("obj_gmv_layer_background");
					if (vb == null) {
						vb = "l_background";
						cc.add("var ");
					}
					var spr = pj.spriteNames[l.spriteId];
					if (spr == null) spr = "-1";
					Ruleset.includeIdent("layer_background_create");
					cc.addFormat("%s = layer_background_create(%s, %s", vb, vl, spr);
					if (l.gmvBgIndex >= 0) {
						cc.addFormat(", %d", l.gmvBgIndex);
					}
					cc.addString(");\r\n");
					if (l == bgColorLayer) return;
					if (!l.htiled) {
						Ruleset.includeIdent("layer_background_htiled");
						cc.addFormat("layer_background_htiled(%s, %z);\r\n", vb, l.htiled);
					}
					if (!l.vtiled) {
						Ruleset.includeIdent("layer_background_vtiled");
						cc.addFormat("layer_background_vtiled(%s, %z);\r\n", vb, l.vtiled);
					}
					if (l.stretch) {
						Ruleset.includeIdent("layer_background_stretch");
						cc.addFormat("layer_background_stretch(%s, %z);\r\n", vb, l.stretch);
					}
					//
					var rgba = l.colour.Value;
					var a = Std.int(rgba / 16777216.);
					if (a < 255) {
						Ruleset.includeIdent("layer_background_alpha");
						cc.addFormat("layer_background_alpha(%s, %f);\r\n", vb, a/255.);
					}
					var rgb = Std.int(rgba % 16777216);
					if (rgb != 0xFFFFFF) {
						Ruleset.includeIdent("layer_background_blend");
						cc.addFormat("layer_background_blend(%s, $%s);\r\n", vb,
							StringTools.hex(rgb, 6));
					}
				};
				case "GMRTileLayer": {
					if (l.tilesetId == YyGUID.zero) return;
					var ts = pj.tilesets[l.tilesetId];
					if (ts == null) {
						trace("Missing tileset: " + l.tilesetId);
						return;
					}
					Ruleset.includeIdent("layer_tilemap_create");
					cc.addFormat("layer_tilemap_create(%s, %f, %f, %s, %d, %d);\r\n",
						vl, l.x, l.y, ts.name, l.tiles.SerialiseWidth, l.tiles.SerialiseHeight
					);
					var td = l.tiles.TileSerialiseData;
					var tmod = l.tiles.SerialiseWidth;
					var tileWidth = ts.tileWidth;
					var tileHeight = ts.tileHeight;
					var tileCols = ts.tileCols;
					var tilePadX = ts.tilePadX;
					var tilePadY = ts.tilePadY;
					var tileMulX = ts.tileMulX;
					var tileMulY = ts.tileMulY;
					for (tpos in 0 ... td.length) {
						var tileBits = Std.int(td[tpos] % VitTileset.maskMax);
						var tileIndex = tileBits & VitTileset.maskIndex;
						if (tileIndex == 0) continue;
						var rt = rTiles.addEmptyChild("tile");
						rt.set("bgName", ts.background);
						//
						var tx = l.x + (tpos % tmod) * tileWidth;
						var ty = l.x + Std.int(tpos / tmod) * tileHeight;
						var tileFlip = (tileBits & VitTileset.maskFlip) != 0;
						var tileMirror = (tileBits & VitTileset.maskMirror) != 0;
						if (tileFlip) ty += tileHeight;
						if (tileMirror) tx += tileWidth;
						//
						rt.setFloat("x", tx);
						rt.setFloat("y", ty);
						rt.setInt("w", tileWidth);
						rt.setInt("h", tileHeight);
						rt.setInt("xo", tilePadX + tileMulX * (tileIndex % tileCols));
						rt.setInt("yo", tilePadY + tileMulY * Std.int(tileIndex / tileCols));
						var rtId = pj.nextTileIndex++;
						rt.setInt("id", rtId);
						rt.set("name", "__tile_" + rtId);
						rt.setInt("depth", lz);
						rt.setInt("locked", 0);
						rt.set("colour", "4294967295");
						rt.setInt("scaleX", tileMirror ? -1 : 1);
						rt.setInt("scaleY", tileFlip ? -1 : 1);
					}
				};
				default: trace("Can't convert " + l.modelName);
			}
		}
		for (l in q.layers) printLayerRec(l);
		//
		for (oi in q.instanceCreationOrderIDs) {
			var o = instMap[oi];
			if (o == null) continue;
			rInsts.addChild(instGmx[oi]);
		}
		//
		var rccFinal = try {
			File.getContent('$inDir/RoomCreationCode.gml');
		} catch (_:Dynamic) "";
		rccNode.text = rccFinal;
		//
		var imp = new ImportRule("gmv_room_init_" + name, null, "script");
		imp.data = cc.toString();
		Ruleset.importList.push(imp);
		//
		File.saveContent('$outPath.room.gmx', r.toGmxString());
	}
}