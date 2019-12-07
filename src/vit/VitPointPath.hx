package vit;
import yy.*;
import haxe.io.Path;
import sys.io.File;
import tools.SfGmx;

/**
 * ...
 * @author YellowAfterlife
 */
class VitPointPath {
	public static function proc(name:String, q:YyPointPath, inPath:String, outPath:String) {
		Sys.println('Converting $name...');
		var q0 = new SfGmx("path");
		var q1:SfGmx;
		q0.addIntChild("kind", q.kind);
		q0.addBoolChild("closed", q.closed);
		q0.addIntChild("precision", q.precision);
		q0.addIntChild("backroom", -1);
		q0.addIntChild("hsnap", q.hsnap);
		q0.addIntChild("vsnap", q.vsnap);
		q1 = q0.addEmptyChild("points");
		for (p in q.points) {
			q1.addTextChild("point", p.x + "," + p.y + "," + p.speed);
		}
		File.saveContent(outPath + '.path.gmx', q0.toGmxString());
	}
}