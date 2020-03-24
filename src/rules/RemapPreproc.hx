package rules;
import haxe.ds.GenericStack;
import hscript.*;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class RemapPreproc {
	static var rxPre = ~/^\s*#(if|else|end)\b\s*(.*)$/;
	static var parser:Parser;
	static var interp:Interp;
	static var interpRow:Int = 0;
	static function evalCondition(condition:String, ctx:RemapPreprocLine):Bool {
		try {
			interpRow = ctx.row;
			var result:Dynamic = interp.execute(parser.parseString(condition, ctx.toString()));
			return RemapPreprocInterp.toBool(result);
		} catch (x:Dynamic) {
			throw 'Error evaluating $ctx: $x';
		}
	}
	static function procIf(input:RemapPreprocInput, output:Array<String>, condition:String, ctx:RemapPreprocLine) {
		var show = evalCondition(condition, ctx);
		var isElse = false;
		while (!input.isEmpty()) {
			var line = input.pop();
			if (rxPre.match(line.text)) switch (rxPre.matched(1)) {
				case "if": procIf(input, output, rxPre.matched(2), line);
				case "else": {
					if (isElse) throw 'Unexpected $ctx';
					isElse = true;
					show = !show;
				};
				case "end": return;
			} else if (show) output.push(line.text);
		}
		throw 'Unclosed #if after $ctx';
	}
	public static function run(src:String):String {
		parser = new Parser();
		interp = new Interp();
		//
		var g = new Map<String, Dynamic>();
		g["String"] = String;
		g["StringTools"] = StringTools;
		g["Std"] = Std;
		g["Math"] = Math;
		g["defs"] = Params.defs;
		g["gml"] = VitProject.current != null ? VitProject.current.apiUses : new Map();
		g["trace"] = Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			var r = new StringBuf();
			var z = false;
			for (arg in args) {
				if (z) r.add(" "); else z = true;
				r.add(arg);
			}
			Sys.println("[L" + interpRow + "] " + r.toString());
		});
		interp.variables = g;
		//
		src = src.replace("\r\n", "\n");
		var input:RemapPreprocInput = new GenericStack();
		var lines = src.split("\n");
		var row = lines.length;
		while (--row >= 0) {
			input.add(new RemapPreprocLine(row + 1, lines[row]));
		}
		//
		var output:Array<String> = [];
		while (!input.isEmpty()) {
			var line = input.pop();
			if (rxPre.match(line.text)) {
				if (rxPre.matched(1) == "if") {
					procIf(input, output, rxPre.matched(2), line);
				} else throw 'Unexpected $line';
			} else output.push(line.text);
		}
		return output.join("\n");
	}
}
private class RemapPreprocLine {
	public var row(default, null):Int;
	public var text(default, null):String;
	public function new(row:Int, text:String) {
		this.row = row;
		this.text = text;
	}
	public function toString() {
		return '[L$row] $text';
	}
}
private typedef RemapPreprocInput = GenericStack<RemapPreprocLine>;
private class RemapPreprocInterp extends Interp {
	public static function toBool(v:Dynamic):Bool {
		if (Std.is(v, Bool)) {
			return v;
		} else if (Std.is(v, Float)) {
			return v != 0;
		} else if (Std.is(v, String)) {
			return v != null && v != "";
		} else return v != null;
	}
	inline function boolExpr(e):Bool {
		return toBool(expr(e));
	}
	override public function expr(e:Expr):Dynamic {
		switch (e) {
			case EUnop("!", _, e1): {
				return !boolExpr(e1);
			};
			case EIf(econd,e1,e2): {
				if ( boolExpr(econd)) {
					return expr(e1);
				} else if ( e2 != null ) {
					return expr(e2);
				} else return null;
			};
			default: return super.expr(e);
		}
	}
	public function new() {
		super();
		//
		var me = this;
		binops.set("||",function(e1,e2) return me.boolExpr(e1) == true || me.boolExpr(e2) == true);
		binops.set("&&",function(e1,e2) return me.boolExpr(e1) == true && me.boolExpr(e2) == true);
	}
}