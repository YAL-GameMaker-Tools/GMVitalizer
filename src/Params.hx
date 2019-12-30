package;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class Params {
	public static var backgroundRegex:Array<EReg> = [];
	public static var ignoreResourceType:Map<String, Bool> = new Map();
	public static var defs:Map<String, Dynamic> = new Map();
	public static function proc(args:Array<String>):Array<String> {
		args = args.copy();
		var i = 0;
		while (i < args.length) {
			switch (args[i]) {
				case "--rules": {
					Ruleset.mainPath = args[i + 1];
					args.splice(i, 2);
				};
				case "--bkrx": {
					backgroundRegex.push(new EReg(args[i + 1], ""));
					args.splice(i, 2);
				};
				case "--nort": {
					for (id in args[i + 1].split(",")) {
						ignoreResourceType[id] = true;
					}
					args.splice(i, 2);
				};
				case "-D", "--define": {
					var raw = args[i + 1];
					var sep = raw.indexOf("=");
					if (sep >= 0) {
						var key = raw.substring(0, sep);
						var val = raw.substring(sep + 1);
						defs[key] = val;
					} else defs[raw] = true;
					args.splice(i, 2);
				};
				default: i++;
			}
		}
		return args;
	}
}