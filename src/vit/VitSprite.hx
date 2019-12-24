package vit ;
import haxe.io.Path;
import sys.io.File;
import yy.YySprite;
import tools.SfGmx;

/**
 * ...
 * @author YellowAfterlife
 */
class VitSprite {
	public static function proc(name:String, q:YySprite, inPath:String, outPath:String) {
		Sys.println('Converting $name...');
		var q0 = new SfGmx("sprite");
		var q1:SfGmx;
		q0.addIntChild("type", q.type);
		q0.addIntChild("xorig", q.xorig);
		q0.addIntChild("yorigin", q.yorig);
		q0.addIntChild("colkind", q.colkind);
		q0.addIntChild("coltolerance", q.colkind);
		q0.addBoolChild("sepmasks", q.sepmasks);
		q0.addIntChild("bboxmode", q.bboxmode);
		q0.addIntChild("bbox_left", q.bbox_left);
		q0.addIntChild("bbox_right", q.bbox_right);
		q0.addIntChild("bbox_top", q.bbox_top);
		q0.addIntChild("bbox_bottom", q.bbox_bottom);
		q0.addBoolChild("HTile", q.HTile);
		q0.addBoolChild("VTile", q.VTile);
		q1 = q0.addEmptyChild("TextureGroups");
		q1.addIntChild("TextureGroup0", 0);
		q0.addBoolChild("For3D", q.For3D);
		q0.addIntChild("width", q.width);
		q0.addIntChild("height", q.height);
		q1 = q0.addEmptyChild("frames");
		var index = 0;
		var imgDir = Path.join([Path.directory(outPath), "images"]);
		var baseDir = Path.directory(inPath);
		for (qf in q.frames) {
			var q2:SfGmx;
			var rel = '${name}_${index}.png';
			var src = Path.join([baseDir, qf.compositeImage.FrameId + '.png']);
			try {
				File.copy(src, Path.join([imgDir, rel]));
			} catch (x:Dynamic) {
				Sys.println('Failed to copy frame #$index: $x');
			}
			q2 = q1.addTextChild("frame", 'images\\$rel');
			q2.setInt("index", index++);
		}
		File.saveContent('$outPath.sprite.gmx', q0.toGmxString());
	}
}