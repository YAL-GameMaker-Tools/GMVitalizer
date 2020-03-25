package;
import haxe.Json;
import haxe.ds.Map;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import tools.Alias;
import tools.SfGmx;
import rules.*;
import yy.YyExtension;
import yy.YyProject;
import yy.YyResource;
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
	 * remap $1[?$2] -> ...
	 * would mean remapsByAccessor["?".code] == [RemapRule]
	 */
	public static var remapsByAccessor:Map<Int, Array<RemapRule>> = new Map();
	public static var hasRemapsByAccessor:Bool = false;
	
	/**
	 * Imports included when a given identifier (e.g. function name) appears.
	 * This includes referencing them directly or rulesets (import X if Y)
	 */
	public static var importsByIdent:Map<Ident, Array<ImportRule>> = new Map();
	
	/**  */
	public static var importMap:Map<Ident, ImportRule> = new Map();
	/** Imports that we're going to add to project */
	public static var importList:Array<ImportRule> = [];
	
	/** compfix only, maps resources for (usually conditional) replacement */
	public static var replaceBy:Map<Ident, ImportRule> = new Map();
	
	/** that is, as soon as we're done reading the file */
	static var importImmediately:Array<ImportRule> = [];
	
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
	
	//
	static var rxWord = ~/\w+/g;
	public static function initFile(path:String) {
		var raw = File.getContent(path);
		raw = RemapPreproc.run(raw);
		//
		new EReg("^remap\\b\\s*"
			+ "(?:\\(([\\w, ]+)\\)\\s*)?" // `(flag1, flag2)`
			+ "(?:"
				+ "\\$(\\d+)\\[([?#|@])" // `$1[?` (accessor capture)
			+ "|"
				+ "(?:\\$(\\d+)\\.)?" // `$1.` (context capture)
				+ "(\\w+)" // function/variable name
			+ ")"
			+ "(.*?)" // rest of input
			+ "->\\s*"
			+ "(.+)" // output
		+ "", "gm").each(raw, function(rx:EReg) {
			var ind = 0;
			var all   = rx.matched(0);
			var flags = rx.matched(++ind);
			var acck  = rx.matched(++ind);
			var accCh = rx.matched(++ind);
			var dotk  = rx.matched(++ind);
			var start = rx.matched(++ind);
			var from  = rx.matched(++ind).rtrim();
			var to    = rx.matched(++ind).rtrim();
			//
			var rule = new RemapRule(from, to);
			if (acck != null) {
				rule.accIndex = Std.parseInt(acck);
				rule.accChar = accCh.fastCodeAt(0);
			} else if (dotk != null) {
				rule.dotIndex = Std.parseInt(dotk);
			}
			//
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
			var arr:Array<RemapRule>;
			if (acck != null) {
				arr = remapsByAccessor[rule.accChar];
				if (arr == null) {
					arr = [];
					remapsByAccessor[rule.accChar] = arr;
					hasRemapsByAccessor = true;
				}
			} else {
				arr = remaps[start];
				if (arr == null) {
					arr = [];
					remaps[start] = arr;
				}
			}
			arr.push(rule);
			remapList.push(rule);
		});
		
		//
		new EReg("^import\\b\\s*"
			+ "([\\w,\\t ]+?)" // `a` or `a, b`
			+ "(?:\\s*\\bas[ \\t]+(\\w+))?" // `as ident`
			+ "(?:\\s*\\bif[ \\t]+([\\w,\\|\\t ]+))?" // `if a`, `if a||b`, `if a or b`
		+ "$", "gm").each(raw, function(rx:EReg) {
			var names = [];
			rxWord.each(rx.matched(1), function(r1:EReg):Void {
				names.push(r1.matched(0));
			});
			//
			var importAs = rx.matched(2);
			if (names.length > 1 && importAs != null) {
				throw "Cannot use import-as with multiple names in " + rx.matched(0);
			}
			var condData = rx.matched(3);
			var condList = null;
			if (condData != null) {
				condList = [];
				rxWord.each(condData, function(r1:EReg):Void {
					var s = r1.matched(0);
					if (s != "or") condList.push(s);
				});
			}
			//
			for (name in names) {
				var imp = importMap[name];
				if (imp != null) {
					if (importAs != null) {
						imp.name = importAs;
						replaceBy[importAs] = imp;
					}
					if (condList == null) {
						importImmediately.push(imp);
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
		
		new EReg("^replace\\b\\s*"
			+ "(\\w+)\\s+with\\s+(\\w+)\\s*"
		+ "$", "gm").each(raw, function(rx:EReg) {
			var target = rx.matched(1);
			var name = rx.matched(2);
			var imp = importMap[name];
			if (imp != null) {
				replaceBy[target] = imp;
			} else {
				throw ('Couldn\'t find `$name` referenced in `${rx.matched(0)}`');
			}
		});
	}
	public static function initGMS1(projectDir:String):Void {
		for (dir in [
			'$projectDir/scripts',
			'$projectDir/objects',
			'$projectDir/extensions',
		]) for (rel in FileSystem.readDirectory(dir)) {
			var full = Path.join([dir, rel]);
			if (FileSystem.isDirectory(full)) continue;
			var name = Path.withoutExtension(rel);
			var kind:ImportRuleKind;
			switch (Path.extension(rel).toLowerCase()) {
				case "gml": kind = Script;
				case "gmx": {
					kind = ImportRuleKind.parse(Path.extension(name));
					name = Path.withoutExtension(name);
				};
				default: kind = IncludedFile;
			};
			var imp = new ImportRule(name, full, kind);
			importMap[name] = imp;
			fullImportList.push(imp);
			if (kind != Extension) {
				importsByIdent[name] = [imp];
			} else {
				imp.data = File.getContent(full);
				imp.gmxData = SfGmx.parse(imp.data);
				for (extFile in imp.gmxData.find("files").findAll("file")) {
					for (fn in extFile.find("functions").findAll("function")) {
						importsByIdent[fn.findText("name")] = [imp];
					}
				}
			}
		}
	}
	public static function initGMS2(projectDir:String):Void {
		var dir:String;
		for (kindStr in ["script", "object", "extension"])
		if (FileSystem.exists(dir = '$projectDir/${kindStr}s'))
		for (rel in FileSystem.readDirectory(dir)) {
			var kind:ImportRuleKind = ImportRuleKind.parse(kindStr);
			var fdir = Path.join([dir, rel]);
			var full = Path.join([fdir, rel + ".yy"]);
			if (!FileSystem.exists(full)) continue;
			var name = rel;
			var impPath = full;
			if (kind == Script) impPath = Path.withExtension(impPath, "gml");
			var imp = new ImportRule(name, impPath, kind);
			importMap[name] = imp;
			fullImportList.push(imp);
			if (kind != Extension) {
				importsByIdent[name] = [imp];
			} else {
				imp.data = File.getContent(full);
				imp.yyData = Json.parse(imp.data);
				var extension:YyExtension = imp.yyData;
				for (extFile in extension.files) {
					for (fn in extFile.functions) {
						importsByIdent[fn.name] = [imp];
					}
				}
			}
		}
	}
	static function initFinish() {
		for (imp in fullImportList) imp.index();
		for (rule in remapList) rule.index();
		for (imp in importImmediately) imp.include();
		//trace(fullImportList.join("\n"));
		//trace(remapList.join("\n"));
	}
	public static function init() {
		#if gmv_compfix
		initGMS2("compfix");
		initFile(mainPath != null ? mainPath : Path.directory(Sys.programPath()) + "/compfix.gml");
		#else
		initGMS1("compatibility.gmx");
		initFile(mainPath != null ? mainPath : Path.directory(Sys.programPath()) + "/rules.gml");
		#end
		initFinish();
	}
}
