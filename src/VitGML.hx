package;
using StringTools;
using tools.StringToolsEx;
import Ruleset;

/**
 * GMS2-GML -> GMS1-GML conversion
 * Supporting ternary operators without rewriting this to be an expression builder might be messy.
 * @author YellowAfterlife
 */
class VitGML {
	public static function proc(src:String, ctx:String):String {
		var out = new StringBuf();
		var pos = 0;
		var len = src.length;
		var start = 0;
		
		#if !debug inline #end
		function flush(till:Int):Void {
			out.addSub(src, start, till - start);
		}
		
		#if !debug inline #end
		function procRemaps(startWord:String, at:Int, remaps:Array<RemapRule>) {
			var debug = false;
			for (remap in remaps) {
				var caps = null;
				var np = pos;
				var item:RemapRuleItem;
				var inputs = remap.inputs;
				var length = inputs.length;
				var iid = -1;
				var debug_eol:Int = -1;
				if (debug) {
					debug_eol = src.indexOf("\n", pos);
					if (debug_eol < 0) debug_eol = len;
					trace("match", inputs);
					trace("against", src.substring(pos, debug_eol));
				}
				while (++iid < length) {
					var item = inputs[iid];
					if (debug) trace(item, "`" + src.substring(np, debug_eol) + "`");
					switch (item) {
						case Text(s): {
							np = src.compareNs(np, s);
							if (np < 0) break;
						};
						case Capture(capi): {
							var depth = 0;
							var after = switch (inputs[iid + 1]) {
								case Text(s): s;
								default: null;
							}
							var np0 = np;
							while (np < len) {
								var c = src.fastCodeAt(np);
								//trace('$np `${src.substring(np, debug_eol)}`');
								switch (c) {
									case "[".code, "(".code, "{".code: depth++;
									case "]".code, ")".code, "}".code: depth--;
									case '"'.code: {
										np = src.skipString2(np + 1);
										continue;
									};
									case '@'.code: {
										c = src.fastCodeAt(np + 1);
										if (c == '"'.code || c == "'".code) {
											np = src.skipString1(np + 2, c);
											continue;
										}
									};
									// todo: strings, comments
									default:
								}
								if (depth <= 0) {
									// match string after the expression:
									var np1 = src.compareNs(np, after);
									//trace('$np1 `$after` `${src.substring(np, debug_eol)}`');
									if (np1 >= 0) {
										if (caps == null) caps = [];
										caps[capi] = src.substring(np0, np);
										iid++;
										np = np1;
										break;
									} else np++;
								} else np++;
							}
						};
					}
				} // while (iid)
				if (debug) trace(np, iid, length);
				if (length > 0 && (np < 0 || iid < length)) continue;
				// process code inside captures (to allow nesting):
				if (caps != null) for (i in 0 ... caps.length) {
					if (caps[i] != null) caps[i] = proc(caps[i].trim(), ctx);
				}
				// flush and print rule output:
				flush(at);
				for (item in remap.outputs) switch (item) {
					case Text(s): out.add(s);
					case Capture(i): out.add(caps[i]);
				}
				pos = np;
				start = np;
				break;
			} // for in remaps
		}
		
		#if !debug inline #end
		function procString2(at:Int) {
			var strBuf:StringBuf = null;
			var strStart = pos;
			var strQuote = true;
			inline function strFlush(till:Int):Void {
				if (strBuf == null) {
					strBuf = new StringBuf();
					strBuf.add('("');
				}
				if (!strQuote) {
					strQuote = true;
					strBuf.add('+"');
				}
				strBuf.addSub(src, strStart, till - strStart);
			}
			while (pos < len) {
				var c = src.fastCodeAt(pos++);
				switch (c) {
					case '"'.code: {
						if (strBuf != null) {
							strFlush(pos - 1);
							flush(at);
							strBuf.add('")');
							out.add(strBuf.toString());
							start = pos;
						}
						break;
					};
					case '\\'.code: {
						if (pos - 1 > strStart) {
							strFlush(pos - 1);
						}
						var esc:Int, note:String = null;
						c = src.fastCodeAt(pos++);
						switch (c) {
							case "r".code: esc = "\r".code; note = "\\r";
							case "n".code: esc = "\n".code; note = "\\n";
							case "t".code: esc = "\t".code; note = "\\t";
							case "\r".code, "\n".code: esc = -1;
							default: throw 'Escape character $c `'
								+ String.fromCharCode(c) + "` is not supported.";
						}
						if (strQuote) {
							strQuote = false;
							strBuf.add('"');
						}
						if (esc < 0) {
							strBuf.addChar(c);
						} else if (note != null) {
							strBuf.add('+chr($esc/*$note*/)');
						} else strBuf.add('+chr($esc)');
						strStart = pos;
					};
					default:
				}
			}
		}
		
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
				case '@'.code: { // possibly string literals
					c = src.fastCodeAt(pos++);
					if (c == '"'.code || c == "'".code) { // string literals
						flush(at);
						pos = src.skipString1(pos, c);
						out.addSub(src, at + 1, pos - at - 1);
						start = pos;
					}
				};
				case '"'.code: procString2(at);
				case "[".code: { // possibly an array literal
					var lp = at;
					var isLiteral = false;
					while (--lp >= 0) {
						c = src.fastCodeAt(lp);
						switch (c) {
							case " ".code, "\t".code, "\r".code, "\n".code: {};
							case _ if (c.isIdent1()): { // maybe an identifier
								var idEnd = lp + 1;
								while (--lp >= 0) {
									c = src.fastCodeAt(lp);
									if (!c.isIdent1()) break;
								}
								var id = src.substring(lp + 1, idEnd);
								isLiteral = id == "return";
								break;
							};
							default: {
								isLiteral = true; break;
							}
						}
					}
					if (isLiteral) {
						while (pos < len) {
							pos = src.skipExpr(pos);
							if (src.fastCodeAt(pos) != ",".code) break;
							pos++;
						}
						if (pos < len) {
							flush(at);
							out.add(proc("array_literal(" + src.substring(at + 1, pos) + ")", ctx));
							start = ++pos;
						}
					}
				};
				case _ if (c == "_".code
					|| c >= "a".code && c <= "z".code 
					|| c >= "A".code && c <= "Z".code 
				): {
					while (pos < len) {
						c = src.fastCodeAt(pos);
						if (c == "_".code
							|| c >= "a".code && c <= "z".code 
							|| c >= "0".code && c <= "9".code 
							|| c >= "A".code && c <= "Z".code 
						) {
							pos++;
						} else break;
					}
					var id = src.substring(at, pos);
					var remaps = Ruleset.remaps[id];
					if (remaps != null) procRemaps(id, at, remaps);
				};
				default: {
					
				};
			}
		}
		flush(pos);
		return out.toString();
	}
}
