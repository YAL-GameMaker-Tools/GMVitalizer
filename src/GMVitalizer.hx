package;
import haxe.io.Path;
import sys.io.File;

/**
 * ...
 * @author YellowAfterlife
 */
class GMVitalizer {
	public static var dir:String;
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
		dir = Path.directory(Sys.programPath());
		var args = Sys.args();
		args = Params.proc(args);
		proc(args[0], args[1]);
	}
	
}
