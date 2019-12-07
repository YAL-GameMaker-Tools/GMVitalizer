package vit;
import yy.YyFont;
import haxe.io.Path;
import sys.io.File;
import tools.SfGmx;

/**
 * ...
 * @author YellowAfterlife
 */
class VitFont {
	public static function proc(name:String, q:YyFont, inPath:String, outPath:String) {
		Sys.println('Converting $name...');
		var q0 = new SfGmx("font");
		var q1:SfGmx;
		q0.addTextChild("name", q.fontName);
		q0.addIntChild("size", q.size);
		q0.addBoolChild("bold", q.bold);
		q0.addBoolChild("italic", q.italic);
		q0.addIntChild("charset", q.charset);
		q0.addIntChild("aa", q.AntiAlias);
		q0.addBoolChild("includeTTF", q.includeTTF);
		q0.addTextChild("TTFName", q.TTFName);
		//
		q1 = q0.addEmptyChild("texgroups");
		q1.addIntChild("texgroup0", 0);
		//
		q1 = q0.addEmptyChild("ranges");
		var rangeIndex = 0;
		for (r in q.ranges) {
			q1.addTextChild("range" + rangeIndex++, r.x + ',' + r.y);
		}
		//
		q1 = q0.addEmptyChild("glyphs");
		for (gp in q.glyphs) {
			var g = gp.Value;
			var q2 = q1.addEmptyChild("glyph");
			q2.setInt("character", g.character);
			q2.setInt("x", g.x);
			q2.setInt("y", g.y);
			q2.setInt("w", g.w);
			q2.setInt("h", g.h);
			q2.setInt("shift", g.shift);
			q2.setInt("offset", g.offset);
		}
		q0.addEmptyChild("kerningPairs");
		q0.addTextChild("image", '$name.png');
		File.copy(Path.withExtension(inPath, 'png'), outPath + '.png');
		File.saveContent(outPath + '.font.gmx', q0.toGmxString());
	}
}