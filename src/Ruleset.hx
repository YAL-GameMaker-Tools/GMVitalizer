package;
import haxe.ds.Map;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import tools.Alias;
using StringTools;
using tools.StringToolsEx;
using tools.ERegTools;

/**
 * ...
 * @author YellowAfterlife
 */
class Ruleset {
	public static var remapList:Array<RemapRule> = [];
	public static var remaps:Map<Ident, Array<RemapRule>> = new Map();
	public static var importsByIdent:Map<Ident, Array<ImportRule>> = new Map();
	public static var importMap:Map<Ident, ImportRule> = new Map();
	public static var importList:Array<ImportRule> = [];
	public static function init() {
		var raw = File.getContent("rules.gml");
		raw = raw.replace("\r\n", "\n");
		var rxWord = ~/w+/g;
		//
		~/^remap\s+(\w+)(.*?)->\s*(.+)/gm.each(raw, function(rx:EReg) {
			var all = rx.matched(0);
			var start = rx.matched(1);
			var from = rx.matched(2).rtrim();
			var to = rx.matched(3).rtrim();
			var arr = remaps[start];
			if (arr == null) {
				arr = [];
				remaps[start] = arr;
			}
			var rule = new RemapRule(from, to);
			arr.push(rule);
			remapList.push(rule);
		});
		//
		var dir = "compatibility";
		for (rel in FileSystem.readDirectory(dir)) {
			var full = Path.join([dir, rel]);
			if (FileSystem.isDirectory(full)) continue;
			var name = Path.withoutExtension(rel);
			var kind:String;
			switch (Path.extension(rel).toLowerCase()) {
				case "gml": kind = "script";
				case "gmx": {
					kind = Path.extension(name);
					name = Path.withoutExtension(name);
				};
				default: kind = "datafile";
			};
			var imp = new ImportRule(name, full, kind);
			importMap[name] = imp;
			importsByIdent[name] = [imp];
		}
		//
		~/^import\s([\w,\t ]+)(?:\s*\bif[ \t]+([\w,\|\t ]+))?/gm.each(raw, function(rx:EReg) {
			var names = [];
			rxWord.each(rx.matched(1), function(r1:EReg):Void {
				names.push(r1.matched(0));
			});
			var condData = rx.matched(2);
			var condList = null;
			if (condData != null) {
				condList = [];
				rxWord.each(rx.matched(1), function(r1:EReg):Void {
					var s = r1.matched(0);
					if (s != "or") condList.push(s);
				});
			}
			//
			for (name in names) {
				var imp = importMap[name];
				if (imp != null) {
					if (condList == null) {
						imp.include();
					} else for (cond in condList) {
						var imp2 = importMap[cond];
						if (imp2 != null) {
							imp.dependants.push(imp2);
						} else {
							var arr = importsByIdent[cond];
							if (arr == null) {
								arr = [];
								importsByIdent[name] = arr;
							}
							arr.push(imp);
						}
					}
				} else {
					Sys.println('Couldn\'t find `$name` referenced in `${rx.matched(0)}`');
				}
			}
		}); // import
		//
		for (rule in remapList) rule.index();
	}
}
class RemapRule {
	public var inputString:String;
	public var outputString:String;
	public var inputs:Array<RemapRuleItem> = [];
	public var outputs:Array<RemapRuleItem> = [];
	public var dependants:Array<ImportRule> = [];
	public var isUsed:Bool = false;
	public function new(input:String, output:String) {
		inputs = parse(input, true);
		inputString = input;
		outputs = parse(output, false);
		outputString = output;
	}
	public function index() {
		var found = new Map();
		for (item in outputs) switch (item) {
			case Text(src): {
				var len = src.length;
				var pos = 0;
				while (pos < len) {
					var at = pos;
					var c = src.fastCodeAt(pos++);
					switch (c) {
						case "/".code: { // comments
							if (pos < len) switch (src.fastCodeAt(pos)) {
								case "/".code: pos = src.skipLine(pos + 1);
								case "*".code: pos = src.skipComment(pos + 1);
							}
						};
						case "@".code: {
							c = src.fastCodeAt(pos++);
							if (c == '"'.code || c == "'".code) pos = src.skipString1(pos, c);
						};
						case '"'.code: pos = src.skipString2(pos);
						case _ if (c.isIdent0()): {
							pos = src.skipIdent1(pos);
							var id = src.substring(at, pos);
							if (!found.exists(id)) {
								found[id] = true;
								var arr = Ruleset.importsByIdent[id];
								if (arr != null) for (imp in arr) dependants.push(imp);
							}
						};
						default: {};
					}
				}
			};
			case Capture(_): {};
		}
	}
	static function parse(src:String, isInput:Bool):Array<RemapRuleItem> {
		var out:Array<RemapRuleItem> = [];
		var pos = 0;
		var len = src.length;
		var start = 0;
		inline function flush(till:Int):Void {
			if (till > start) out.push(Text(src.substring(start, till)));
		}
		while (pos < len) {
			var c = src.fastCodeAt(pos++);
			if (c == "$".code) {
				c = src.fastCodeAt(pos++);
				if (c >= "0".code && c <= "9".code) {
					flush(pos - 2);
					out.push(Capture(c - "0".code));
					start = pos;
				}
			}
		}
		flush(pos);
		// validate input:
		if (isInput) for (i in 1 ... out.length) {
			switch (out[i - 1]) {
				case Capture(k): {
					switch (out[i]) {
						case Text(_): {};
						default: throw 'Expected a delimiter after capture $k in $src: $out';
					}
				};
				default:
			}
		}
		//
		return out;
	}
	public function toString() {
		return 'RemapRule(input=`$inputString`,output=`$outputString`,deps=$dependants)';
	}
}
enum RemapRuleItem {
	Text(s:String);
	Capture(ind:Int);
}
class ImportRule {
	public var dependants:Array<ImportRule> = [];
	public var name:Ident;
	public var path:FullPath;
	public var kind:String;
	public var isIncluded:Bool = false;
	public function new(name:Ident, path:FullPath, kind:String):Void {
		this.name = name;
		this.path = path;
		this.kind = kind;
	}
	public function include() {
		if (isIncluded) return;
		for (dep in dependants) if (!dep.isIncluded) dep.include();
		Ruleset.importList.push(this);
		isIncluded = true;
	}
	public function toString():String {
		return 'ImportRule($name,deps=$dependants)';
	}
}