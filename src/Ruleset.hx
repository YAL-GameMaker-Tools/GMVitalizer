package;
import haxe.ds.Map;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import tools.Alias;
import tools.SfGmx;
import rules.*;
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
			"compatibility.gmx/extensions",
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
				rxWord.each(rx.matched(2), function(r1:EReg):Void {
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
								importsByIdent[cond] = arr;
							}
							arr.push(imp);
						}
					}
				} else {
					throw ('Couldn\'t find `$name` referenced in `${rx.matched(0)}`');
				}
			}
		}); // import
		for (k => v in importsByIdent) if (k.indexOf("y_create") >= 0) trace(k, v);
		//
		for (rule in remapList) {
			rule.index();
		}
	}
}
