package rules;
import haxe.ds.Map;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import tools.Alias;
import tools.SfGmx;
using StringTools;
using tools.StringToolsEx;

/**
 * ...
 * @author YellowAfterlife
 */
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