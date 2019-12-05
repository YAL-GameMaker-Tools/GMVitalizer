package tools;
using StringTools;
using tools.StringToolsEx;
import tools.Alias;

/**
 * ...
 * @author YellowAfterlife
 */
class StringToolsEx {
	/**
	 * Compare without spaces
	 * @return -1 if not matched, 
	 */
	public static function compareNs(source:String, pos:StringPos, against:String):StringPos {
		inline function isSpace(c:Int):Bool {
			return (c > 8 && c < 14) || c == 32;
		}
		var sp = pos;
		var sl = source.length;
		var ap = 0;
		var al = against.length;
		while (ap < al) {
			var ac = against.fastCodeAt(ap++);
			if (isSpace(ac)) continue;
			var sc:Int = -1;
			while (sp < sl) {
				sc = source.fastCodeAt(sp++);
				if (!isSpace(sc)) break;
			}
			//trace('sp=$sp/$sl, ap=$ap/$al, $sc<->$ac');
			if (sc != ac) return -1;
		}
		return sp;
	}
	
	public static function skipString1(src:String, pos:StringPos, end:CharCode):StringPos {
		var len = src.length;
		while (pos < len) {
			if (src.fastCodeAt(pos++) == end) break;
		}
		return pos;
	}
	
	/** `a = ¦"and I said \"hi\".";` -> `a = "and I said \"hi\"."¦;` */
	public static function skipString2(src:String, pos:StringPos):StringPos {
		var len = src.length;
		while (pos < len) {
			var c = src.fastCodeAt(pos++);
			switch (c) {
				case '"'.code: break;
				case "\\".code: {
					switch (src.fastCodeAt(pos)) {
						case "x".code: pos += 2;
						case "u".code: pos += 4;
						default: pos += 1;
					}
				};
			}
		}
		return pos;
	}
	
	/** Skips until EOL (not skipping EOL itself) */
	public static function skipLine(src:String, pos:StringPos):StringPos {
		var len = src.length;
		while (pos < len) {
			var c = src.fastCodeAt(pos);
			if (c == "\r".code || c == "\n".code) break;
			pos++;
		}
		return pos;
	}
	
	/** Skips until a multiline comment block end */
	public static function skipComment(src:String, pos:StringPos):StringPos {
		var len = src.length;
		while (pos < len) {
			var c = src.fastCodeAt(pos++);
			if (c == "*".code && src.fastCodeAt(pos) == "/".code) {
				pos++;
				break;
			}
		}
		return pos;
	}
	
	/**
	 * 
	 * @return	new position
	 */
	public static function skipExpr(src:String, pos:StringPos):StringPos {
		var len = src.length;
		var depth = 0;
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
				case "(".code, "[".code, "{".code: depth += 1;
				case ")".code, "]".code, "}".code: {
					// closing brackets
					if (--depth < 0) return at;
				};
				case ",".code: if (depth <= 0) return at;
				case ";".code: return at;
				case "@".code: {
					c = src.fastCodeAt(pos++);
					if (c == '"'.code || c == "'".code) pos = src.skipString1(pos, c);
				};
				case '"'.code: pos = src.skipString2(pos);
			}
		}
		return pos;
	}
	
	public static function isIdent0(c:Int):Bool {
		return c == "_".code
			|| c >= "a".code && c <= "z".code
			|| c >= "A".code && c <= "Z".code;
	}
	public static function isIdent1(c:Int):Bool {
		return c == "_".code
			|| c >= "0".code && c <= "9".code
			|| c >= "a".code && c <= "z".code
			|| c >= "A".code && c <= "Z".code;
	}
}
