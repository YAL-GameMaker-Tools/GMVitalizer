package;
import haxe.io.Path;
import sys.io.File;

/**
 * ...
 * @author YellowAfterlife
 */
class Main {
	static function proc(from:String, to:String) {
		Ruleset.init();
		var ext = Path.extension(from).toLowerCase();
		switch (ext) {
			case "gml": {
				var gml = File.getContent(from);
				var name = Path.withoutDirectory(Path.withoutExtension(from));
				gml = VitGML.proc(gml, name);
				File.saveContent(to, gml);
			};
			case "yyp": {
				VitProject.proc(from, to);
			};
			default: {
				Sys.println('No idea what to do with .$ext');
			};
		}
	}
	static function main() {
		var args = Sys.args();
		proc(args[0], args[1]);
	}
	
}
