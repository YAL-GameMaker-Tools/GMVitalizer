package;
import haxe.ds.Map;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import tools.Alias;
import tools.SfGmx;
using StringTools;
using tools.StringToolsEx;
using tools.ERegTools;

/**
 * ...
 * @author YellowAfterlife
 */
class Ruleset {
	public static var mainPath:String = null;
	public static var remapList:Array<RemapRule> = [];
	
	/**
	 * Potential remaps that can be triggered by referencing an identifier.
	 * So if you had
	 * remap view_camera[$1] = $2 -> view_set_camera($1, $2)
	 * remap view_camera[$1] -> ($1)
	 * remaps["view_camera"] would contain those two RemapRules
	 */
	public static var remaps:Map<Ident, Array<RemapRule>> = new Map();
	
	/**
	 * Imports included when a given identifier (e.g. function name) appears.
	 * This includes referencing them directly or rulesets (import X if Y)
	 */
	public static var importsByIdent:Map<Ident, Array<ImportRule>> = new Map();
	
	/**  */
	public static var importMap:Map<Ident, ImportRule> = new Map();
	/** Imports that we're going to add to project */
	public static var importList:Array<ImportRule> = [];
	
	/** All of imports */
	static var fullImportList:Array<ImportRule> = [];
	static var identIncluded:Map<Ident, Bool> = new Map();
	public static function includeIdent(id:Ident) {
		if (identIncluded.exists(id)) return;
		identIncluded[id] = true;
		var arr = importsByIdent[id];
		if (arr == null) return;
		for (imp in arr) if (!imp.isIncluded) imp.include();
	}
	public static function init() {
		var rawPath = mainPath;
		if (rawPath == null) rawPath = GMVitalizer.dir + "/rules.gml";
		var raw = File.getContent(rawPath);
		raw = raw.replace("\r\n", "\n");
		var rxWord = ~/\w+/g;
		//
		~/^remap(?:\(([\w, ]+)\))?\s+(?:\$(\d).)?(\w+)(.*?)->\s*(.+)/gm
		.each(raw, function(rx:EReg) {
			var ind = 0;
			var all   = rx.matched(0);
			var flags = rx.matched(++ind);
			var dotk  = rx.matched(++ind);
			var start = rx.matched(++ind);
			var from  = rx.matched(++ind).rtrim();
			var to    = rx.matched(++ind).rtrim();
			//
			var rule = new RemapRule(from, to);
			if (dotk != null) rule.dotIndex = Std.parseInt(dotk);
			if (flags != null) rxWord.each(flags, function(rx:EReg) {
				var f = rx.matched(0);
				switch (f) {
					case "expr": rule.exprOnly = true;
					case "stat": rule.statOnly = true;
					case "self": rule.selfOnly = true;
					default: throw 'Unknown flag `$f` in `$all`';
				}
			});
			//
			var arr = remaps[start];
			if (arr == null) {
				arr = [];
				remaps[start] = arr;
			}
			arr.push(rule);
			remapList.push(rule);
		});
		//
		for (dir in [
			"compatibility",
			"compatibility.gmx/scripts",
			"compatibility.gmx/objects",
		]) for (rel in FileSystem.readDirectory(dir)) {
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
			fullImportList.push(imp);
		}
		for (imp in fullImportList) imp.index();
		//
		~/^import\s([\w,\t ]+?)(?:\s*\bif[ \t]+([\w,\|\t ]+))?$/gm.each(raw, function(rx:EReg) {
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
		for (rule in remapList) {
			rule.index();
		}
	}
}
class RemapRule {
	public var inputString:String;
	public var outputString:String;
	public var inputs:Array<RemapRuleItem> = [];
	public var outputs:Array<RemapRuleItem> = [];
	public var dependants:Array<ImportRule> = [];
	public var isUsed:Bool = false;
	//
	public var dotIndex:Int = -1;
	public var statOnly:Bool = false;
	public var exprOnly:Bool = false;
	public var selfOnly:Bool = false;
	//
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
				ImportRule.indexCode(src, dependants, found);
			};
			case Capture(_), CaptureBinOp(_), CaptureSetOp(_), SkipSet: {};
		}
	}
	static var parse_rxPair:EReg = ~/^(\d):(.+)$/;
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
				if (c == "{".code) {
					var end = src.indexOf("}", pos);
					var text = src.substring(pos, end);
					var ind:Int = 0;
					if (parse_rxPair.match(text)) {
						ind = Std.parseInt(parse_rxPair.matched(1));
						text = parse_rxPair.matched(2);
					}
					flush(pos - 2);
					switch (text) {
						case "op": out.push(CaptureBinOp(ind));
						case "aop": out.push(CaptureSetOp(ind));
						case "set": out.push(SkipSet);
						default: throw 'Uknown capture type `$text` in `$src`';
					}
					pos = end + 1;
					start = pos;
				} else if (c >= "0".code && c <= "9".code) {
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
	SkipSet; // `=`, no `==`
	CaptureSetOp(ind:Int); // `+=`
	CaptureBinOp(ind:Int); // `+`
}
class ImportRule {
	public var dependants:Array<ImportRule> = [];
	public var name:Ident;
	public var path:FullPath;
	public var kind:String;
	public var data:String = null;
	public var isIncluded:Bool = false;
	public function new(name:Ident, path:FullPath, kind:String):Void {
		this.name = name;
		this.path = path;
		this.kind = kind;
	}
	
	public function include() {
		if (isIncluded) return;
		isIncluded = true;
		for (dep in dependants) if (!dep.isIncluded) dep.include();
		Ruleset.importList.push(this);
	}
	
	public function index():Void {
		switch (kind) {
			case "script": {
				data = File.getContent(path);
				indexCode(data, dependants);
			};
			case "object": {
				data = File.getContent(path);
				var obj:SfGmx = SfGmx.parse(data);
				var found = new Map<String, Bool>();
				var parentName = obj.findText("parentName");
				if (parentName != "<undefined>") {
					found[parentName] = true;
					var arr = Ruleset.importsByIdent[parentName];
					if (arr != null) for (imp in arr) {
						if (dependants.indexOf(imp) < 0) dependants.push(imp);
					}
				}
				//
				for (events in obj.findAll("events"))
				for (event in events.findAll("event")) {
					for (action in event.findAll("action")) {
						if (action.findInt("libid") != 1) continue;
						if (action.findInt("id") != 603) continue;
						var code = action.find("arguments").find("argument").find("string").text;
						indexCode(code, dependants, found);
					}
				}
			};
		}
	}
	
	public function toString():String {
		return 'ImportRule($name,deps=$dependants)';
	}
	
	public static function indexCode(src:String, deps:Array<ImportRule>, ?found:Map<String, Bool>) {
		if (found == null) found = new Map();
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
						if (arr != null) for (imp in arr) {
							if (deps.indexOf(imp) < 0) deps.push(imp);
						}
					}
				};
				default: {};
			}
		}
	}
}