package tools;
using StringTools;
using tools.StringToolsEx;
import tools.Alias;

/**
 * ...
 * @author YellowAfterlife
 */
class StringToolsEx {
	private static function mapKws(kws:Array<Ident>):Map<Ident, Bool> {
		var result = new Map();
		for (kw in kws) result[kw] = true;
		return result;
	}
	/** `ident ident` breaks expression unless it's `op ident` or `ident op` */
	public static var operatorKeywords:Map<Ident, Bool> = mapKws([
		"not", "and", "or", "xor", "div", "mod"
	]);
	/** These definitely end expressions */
	public static var statementKeywords:Map<Ident, Bool> = mapKws([
		"var", "globalvar",
		"if", "then", "else",
		"for", "while", "do", "until", "repeat", "break", "continue",
		"switch", "case", "default",
		"exit", "return",
		// "try", "catch", "throw", "function", // if you do, you're already in trouble
	]);
	/**
	 * Compare without spaces
	 * @return -1 if not matched, 
	 */
	public static function compareNs(source:String, pos:StringPos, against:String):StringPos {
		var sp = pos;
		var sl = source.length;
		var ap = 0;
		var al = against.length;
		while (ap < al) {
			var ac = against.fastCodeAt(ap++);
			if (inline isSpace1(ac)) continue;
			var sc:Int = -1;
			while (sp < sl) {
				sc = source.fastCodeAt(sp++);
				if (!inline isSpace1(sc)) break;
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
	
	public static inline function skipWhile(src:String, pos:StringPos, fn:StringSkipWhile):StringPos {
		var len = src.length;
		while (pos < len) {
			if (fn(src.fastCodeAt(pos), pos)) {
				pos++;
			} else break;
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
	
	public static function skipIdent1(src:String, pos:StringPos):StringPos {
		return skipWhile(src, pos, (c, _) -> inline c.isIdent1());
	}
	public static function skipSpace0(src:String, pos:StringPos):StringPos {
		return skipWhile(src, pos, (c, _) -> inline c.isSpace0());
	}
	public static function skipSpace1(src:String, pos:StringPos):StringPos {
		return skipWhile(src, pos, (c, _) -> inline c.isSpace1());
	}
	public static function skipHexDigits(src:String, pos:StringPos):StringPos {
		return skipWhile(src, pos, (c, _) -> inline c.isHexDigit());
	}
	
	/** `a  ¦b` -> `a¦  b` */
	public static function skipSpaceBackwards(src:String, pos:StringPos):StringPos {
		while (--pos >= 0) {
			var c = src.fastCodeAt(pos);
			if (!inline isSpace0(c)) return pos;
		}
		return 0;
	}
	
	/** Skips spaces and comments */
	public static function skipBlanks(src:String, pos:StringPos):StringPos {
		var len = src.length;
		while (pos < len) {
			var at = pos;
			var c = src.fastCodeAt(pos++);
			switch (c) {
				case " ".code, "\t".code, "\r".code, "\n".code: {};
				case "/".code: {
					if (pos < len) switch (src.fastCodeAt(pos)) {
						case "/".code: pos = src.skipLine(pos + 1);
						case "*".code: pos = src.skipComment(pos + 1);
						default: return at;
					} else return at;
				};
				default: return at;
			}
		}
		return pos;
	}
	
	public static function skipNumber(src:String, pos:StringPos, canDot:Bool = true):StringPos {
		var c = src.fastCodeAt(pos);
		var len = src.length;
		while (pos < len) {
			if (c == ".".code) {
				if (canDot) {
					canDot = false;
					pos++;
				} else break;
			} else if (c.isDigit()) {
				pos++;
			} else break;
			c = src.fastCodeAt(pos);
		}
		return pos;
	}
	
	/**
	 * `var a =¦ 1 b` -> `var a = 1¦ b`
	 */
	public static function skipExpr(src:String, pos:StringPos):StringPos {
		var start = pos;
		var len = src.length;
		var depth = 0;
		var ternDepth = 0;
		var kind = 0; // 0: not, 1: value, 2: await value, 3: value no trouble
		var result = pos;
		while (pos < len) {
			var at = pos;
			var c = src.fastCodeAt(pos++);
			if (inline isSpace0(c)) continue;
			var oldKind = kind;
			kind = 0;
			switch (c) {
				case "/".code: { // comments
					if (pos < len) switch (src.fastCodeAt(pos)) {
						case "/".code: pos = src.skipLine(pos + 1); kind = -1;
						case "*".code: pos = src.skipComment(pos + 1); kind = -1;
						default: kind = 2;
					} else kind = 2;
				};
				case "(".code, "[".code, "{".code: depth += 1; kind = 2;
				case ")".code, "]".code, "}".code: {
					// closing brackets
					if (--depth < 0) return result;
					// this prevents us from mis-triggering when ']' follows an ident
					kind = 3;
				};
				case ",".code: if (depth <= 0) return result;
				case "?".code: {
					var lp = src.skipSpaceBackwards(at);
					if (src.fastCodeAt(lp) != "[".code) {
						ternDepth++;
					}
				};
				case ":".code: {
					if (ternDepth > 0) {
						ternDepth--;
					} else return result;
				};
				case ";".code: return result;
				case "@".code: {
					c = src.fastCodeAt(pos++);
					if (c == '"'.code || c == "'".code) {
						pos = src.skipString1(pos, c);
						kind = 1;
					}
				};
				case '"'.code: pos = src.skipString2(pos); kind = 1;
				//
				case "+".code, "-".code: {
					if (src.fastCodeAt(pos) == c) {
						pos++;
						if (oldKind == 1) {
							kind = 1;
						} else kind = 2;
					}
				};
				case "*".code, "%".code: kind = 2;
				case "&".code, "|".code, "^".code, "=".code: {
					if (src.fastCodeAt(pos) == c) {
						pos++;
						kind = 2;
					}
				};
				//
				case _ if (inline isIdent0(c)): {
					while (pos < len) {
						if (isIdent1(src.fastCodeAt(pos))) pos++; else break;
					}
					var id = src.substring(at, pos);
					if (statementKeywords[id]) return result;
					kind = operatorKeywords[id] ? 2 : 1;
				};
				case _ if (c >= "0".code && c <= "9".code || c == ".".code): {
					var c1 = src.fastCodeAt(pos);
					if (c == "0".code && c1 == "x".code) {
						pos = src.skipHexDigits(pos + 1);
						kind = 1;
					} else if (c.isDigit()) {
						pos = src.skipNumber(pos, c == ".".code);
						kind = 1;
					} else {
						// not really how this works but
						kind = 2;
					}
				};
			}
			//trace(kind, "`"+src.substring(0, pos)+"`");
			if (kind < 0) {
				kind = oldKind;
			} else {
				if (kind == 3) {
					kind = 1;
				} else if (kind == 1 && oldKind == 1) {
					//trace(src.substring(0, result), pos, result, String.fromCharCode(c));
					return result;
				}
				result = pos;
			}
		}
		//trace("eof", src.substring(start));
		return result;
	}
	
	/**
	 * `var a = b ¦? c : d` -> `var a = ¦b ? c : d`
	 * Can only do inline expressions, no statements
	 */
	public static function skipExprBackwards(src:String, pos:StringPos, tern:Bool = false):StringPos {
		var depth = 0;
		var result = pos;
		while (--pos >= 0) {
			var c = src.fastCodeAt(pos);
			if (inline isSpace0(c)) continue;
			switch (c) {
				case '"'.code: {
					while (--pos >= 0) {
						if (src.fastCodeAt(pos) == '"'.code
						&& src.fastCodeAt(pos - 1) != "\\".code) break;
					}
				};
				case "'".code: {
					while (--pos >= 0) {
						if (src.fastCodeAt(pos) == "'".code) break;
					}
				};
				case ")".code, "]".code: depth++;
				case "(".code, "[".code: {
					if (depth > 0) {
						depth--;
					} else return result;
				};
				case ",".code: {
					if (depth <= 0) return result;
				};
				case "/".code: {
					if (src.fastCodeAt(--pos) == "*".code) { // comment
						pos--;
						while (--pos >= 0) {
							if (src.fastCodeAt(pos) == "*".code
								&& src.fastCodeAt(pos - 1) == "/".code
							) {
								pos--;
							}
						}
					}
				};
				case VitGML.commentEOL: {
					while (--pos >= 0) {
						if (src.fastCodeAt(pos) == "/".code
							&& src.fastCodeAt(pos - 1) == "/".code
						) pos--;
					}
				};
				case "=".code: {
					if (tern) {
						if (isStatementBacktrack(src, pos)) {
							return result;
						}
						if (src.fastCodeAt(pos - 1) == "=".code) pos--;
					} else if (depth <= 0) {
						return result;
					}
				};
				case _ if (c.isIdent1()): {
					var till = pos + 1;
					while (pos > 0) {
						if (src.fastCodeAt(pos - 1).isIdent1()) pos--; else break;
					}
					var id = src.substring(pos, till);
					switch (id) {
						case "if", "while", "until", "repeat", "switch", "case", "return": {
							return result;
						}
						default: {};
					}
				};
			}
			result = pos;
		}
		return result;
	}
	
	/**
	 * `if (_) obj¦.fd = 1;` -> `if (_) ¦obj.fd = 1;`
	 */
	public static function skipDotExprBackwards(src:String, pos:StringPos):StringPos {
		var depth = 0;
		while (--pos >= 0) {
			var till = pos + 1;
			var c = src.fastCodeAt(pos);
			switch (c) {
				case '"'.code: {
					while (--pos >= 0) {
						c = src.fastCodeAt(pos);
						if (c == '"'.code) {
							if (src.fastCodeAt(pos - 1) != "\\".code) break;
						}
					}
				};
				case "(".code, "[".code, "{".code: depth++;
				case ")".code, "]".code, "}".code: depth--;
				case _ if (inline isIdent1(c)): {
					while (pos > 0) {
						c = src.fastCodeAt(pos - 1);
						if (isIdent1(c)) {
							pos--;
						} else break;
					}
					var id = src.substring(pos, till);
					var np = pos;
					while (--np >= 0) {
						if (!src.fastCodeAt(np).isSpace0()) break;
					}
					if (src.fastCodeAt(np) == ".".code) {
						pos = np;
					} else if (depth == 0) {
						return pos;
					}
				}
			}
		}
		return 0;
	}
	
	/**
	 * `if (_) ¦` -> true, `if (a || ¦b)` -> false, etc.
	 */
	public static function isStatementBacktrack(src:String, pos:StringPos):Bool {
		while (--pos >= 0) {
			var c = src.fastCodeAt(pos);
			switch (c) {
				case '"'.code, "'".code: return true;
				case ")".code, "]".code, "{".code, "}".code: return true;
				case "[".code: return false;
				case "(".code: { // only `for (` is OK
					while (--pos >= 0) {
						c = src.fastCodeAt(pos);
						if (isSpace0(c)) continue;
						return pos >= 3 && c == "r".code
							&& src.fastCodeAt(pos - 1) == "o".code
							&& src.fastCodeAt(pos - 2) == "f".code
							&& (pos == 3 || !src.fastCodeAt(pos - 3).isIdent1());
					}
					return true;
				};
				case "+".code, "-".code: {
					if (src.fastCodeAt(--pos) == c) { //++thing?
						// keep going
					} else return false;
				};
				case "/".code: {
					if (src.fastCodeAt(--pos) == "*".code) { // comment
						pos--;
						while (--pos >= 0) {
							if (src.fastCodeAt(pos) == "*".code
								&& src.fastCodeAt(pos - 1) == "/".code
							) {
								pos--;
							}
						}
					} else return false;
				};
				case VitGML.commentEOL: {
					while (--pos >= 0) {
						if (src.fastCodeAt(pos) == "/".code
							&& src.fastCodeAt(pos - 1) == "/".code
						) {
							pos--;
						}
					}
				};
				case"|".code, "^".code, "&".code,
					"*".code, "%".code,
					">".code, "<".code,
				"=".code: return false; // def. operators
				case _ if (c.isIdent1()): {
					var till = pos + 1;
					while (pos > 0) {
						if (src.fastCodeAt(pos - 1).isIdent1()) pos--; else break;
					}
					var id = src.substring(pos, till);
					return switch (id) {
						case "if", "while", "until", "repeat", "switch", "case", "return": false;
						default: !operatorKeywords[id];
					}
				};
			}
		}
		return true;
	}
	
	/** includes spaces, tabs, linebreaks */
	public static function isSpace0(c:CharCode):Bool {
		return (c > 8 && c < 14) || c == 32;
	}
	
	/** includes spaces and tabs */
	public static function isSpace1(c:CharCode):Bool {
		return c == " ".code || c == "\t".code;
	}
	
	/** includes _, a-z, A-Z */
	public static function isIdent0(c:CharCode):Bool {
		return c == "_".code
			|| c >= "a".code && c <= "z".code
			|| c >= "A".code && c <= "Z".code;
	}
	
	/** includes _, a-z, A-Z, 0-9 */
	public static function isIdent1(c:CharCode):Bool {
		return c == "_".code
			|| c >= "0".code && c <= "9".code
			|| c >= "a".code && c <= "z".code
			|| c >= "A".code && c <= "Z".code;
	}
	
	public static function isDigit(c:CharCode):Bool {
		return c >= "0".code && c <= "9".code;
	}
	
	public static function isHexDigit(c:CharCode):Bool {
		return c >= "0".code && c <= "9".code
			|| c >= "a".code && c <= "f".code
			|| c >= "A".code && c <= "F".code;
	}
}

typedef StringSkipWhile = (c:CharCode, p:StringPos)->Bool;