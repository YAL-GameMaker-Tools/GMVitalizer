package yy;
#if js
import js.lib.RegExp;
#end

/**
 * ...
 * @author YellowAfterlife
 */
abstract YyGUID(String) to String {
	public static inline var zero:YyGUID = cast "00000000-0000-0000-0000-000000000000";
	#if js
	public static var test:RegExp = {
		var h = '[0-9a-fA-F]';
		new RegExp('^$h{8}-$h{4}-$h{4}-$h{4}-$h{12}' + "$");
	};
	#end
	static function create() {
		var result = "";
		for (j in 0 ... 32) {
			if (j == 8 || j == 12 || j == 16 || j == 20) {
				result += "-";
			}
			result += "0123456789abcdef".charAt(Math.floor(Math.random() * 16));
		}
		return result;
	}
	public inline function new() {
		this = create();
	}
	public function isBlank():Bool {
		return this == null || this == "" || this == zero;
	}
	public function isValid():Bool {
		return this != null && this != "" && this != zero;
	}
	public inline function toString() {
		return this;
	}
}
