package;
import sys.io.File;
using StringTools;
using tools.StringToolsEx;
using tools.ERegTools;

/**
 * ...
 * @author YellowAfterlife
 */
class Ruleset {
	public static var remaps:Map<String, Array<RemapRule>> = new Map();
	public static function init() {
		var raw = File.getContent("rules.gml");
		raw = raw.replace("\r\n", "\n");
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
		});
	}
}
class RemapRule {
	public var inputs:Array<RemapRuleItem> = [];
	public var outputs:Array<RemapRuleItem> = [];
	public function new(input:String, output:String) {
		inputs = parse(input, true);
		outputs = parse(output, false);
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
}
enum RemapRuleItem {
	Text(s:String);
	Capture(ind:Int);
}
