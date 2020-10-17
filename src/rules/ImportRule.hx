package rules;
import haxe.CallStack;
import haxe.ds.Map;
import haxe.io.Path;
import rules.ImportRuleKind;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import tools.Alias;
import tools.SfGmx;
using StringTools;
using tools.StringToolsEx;

/**
 * ...
 * @author YellowAfterlife
 */
class ImportRule {
	
	/** If we get included, these get included too */
	public var dependants:Array<ImportRule> = [];
	
	/** Determines asset name when adding to project file. Defaults to original name */
	public var name:Ident;
	
	/** .gml for scripts, .gmx/.yy for objects and extensions */
	public var path:FullPath;
	
	
	public var kind:ImportRuleKind;
	public var data:String = null;
	public var gmxData:SfGmx = null;
	public var yyData:Dynamic = null;
	public var isIncluded:Bool = false;
	public function new(name:Ident, path:FullPath, kind:ImportRuleKind):Void {
		this.name = name;
		this.path = path;
		this.kind = kind;
	}
	
	public function include() {
		//trace(this, isIncluded, CallStack.toString(CallStack.callStack()));
		if (isIncluded) return;
		isIncluded = true;
		for (dep in dependants) if (!dep.isIncluded) dep.include();
		Ruleset.importList.push(this);
	}
	
	public function index():Void {
		switch (kind) {
			case Script: {
				data = File.getContent(path);
				indexCode(data, dependants);
				//trace(name, data, dependants);
			};
			case Object: {
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
			default:
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
