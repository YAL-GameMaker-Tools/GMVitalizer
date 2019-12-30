package;
using StringTools;
using tools.StringToolsEx;
import rules.*;
import tools.Alias;
import tools.StringBuilder;

/**
 * GMS2-GML -> GMS1-GML conversion
 * @author YellowAfterlife
 */
class VitGML {
	public static var macroList:Array<GmlMacro> = [];
	public static inline var commentEOL:CharCode = 27;
	public static inline var commentEOLs:String = String.fromCharCode(27);
	
	static function fixSpaces(src:String):String {
		src = src.replace("\t", "    "); // GMS1 is Very Bad with tabs
		src = src.replace("\u00A0", " "); // non-breaking space! Allowed in GMS2 for some reason
		return src;
	}
	
	static function escapeComments(src:String):String {
		var out = new StringBuf();
		var pos = 0;
		var len = src.length;
		var start = 0;
		
		#if !debug inline #end
		function flush(till:Int):Void {
			out.addSub(src, start, till - start);
		}
		
		while (pos < len) {
			var at = pos;
			var c = src.fastCodeAt(pos++);
			switch (c) {
				case "/".code: { // comments
					if (pos < len) switch (src.fastCodeAt(pos)) {
						case "/".code: {
							pos = src.skipLine(pos + 1);
							flush(pos);
							out.addChar(commentEOL);
							start = pos;
						};
						case "*".code: pos = src.skipComment(pos + 1);
					}
				};
				case '#'.code: { // possibly macros or regions
					if (!src.fastCodeAt(pos).isIdent0()) {
						// not what we want
					} else {
						var np = src.skipIdent1(pos);
						switch (src.substring(pos, np)) {
							case "macro": {
								var nameAt = src.skipSpace1(np);
								pos = src.skipIdent1(nameAt);
								var name = src.substring(nameAt, pos);
								var config:String;
								if (src.fastCodeAt(pos) == ":".code) {
									config = name;
									nameAt = ++pos;
									pos = src.skipIdent1(pos);
									name = src.substring(nameAt, pos);
								} else config = null;
								var valueAt = src.skipSpace1(pos);
								pos = src.skipLine(pos);
								var value = "";
								while (src.fastCodeAt(pos - 1) == "\\".code) {
									if (value != "") value += " ";
									value += src.substring(valueAt, pos - 1);
									if (src.fastCodeAt(pos) == "\r".code) pos++;
									if (src.fastCodeAt(pos) == "\n".code) pos++;
									valueAt = pos;
									pos = src.skipLine(pos);
								}
								if (value != "") value += " ";
								value += src.substring(valueAt, pos);
								var m = new GmlMacro(name, value, config);
								macroList.push(m);
								flush(at);
								out.add('//#macro ');
								if (config != null) out.add('$config:');
								out.add('$name $value');
								start = pos;
							};
							case "region", "endregion": {
								pos = src.skipLine(pos);
								flush(at);
								out.add("//");
								out.addSub(src, at, pos - at);
								start = pos;
							};
						}
					}
				};
				case '@'.code: pos = src.skipAtSignCommon(pos);
				case '"'.code: pos = src.skipString2(pos);
				default:
			}
		}
		if (start == 0) return src;
		flush(pos);
		return out.toString();
	}
	
	/**
	 * Doing `var a = 1\nb = 2` throws an ambiguity error in GM:S
	 * (because you used to be able to `var a b` instead of `var a, b` in GM8)
	 * 
	 */
	static function fixVarDecl(src:String, ctx:String):String {
		var out = new StringBuf();
		var pos = 0;
		var len = src.length;
		var start = 0;
		
		#if !debug inline #end
		function flush(till:Int):Void {
			out.addSub(src, start, till - start);
		}
		
		var isInVarDecl = false;
		var commentAt = -1;
		while (pos < len) {
			var at = pos;
			var c = src.fastCodeAt(pos++);
			switch (c) {
				case "/".code: pos = src.skipSlashCommon(pos);
				case '@'.code: pos = src.skipAtSignCommon(pos);
				case '"'.code: pos = src.skipString2(pos);
				case _ if (c.isIdent0()): {
					pos = src.skipIdent1(pos);
					var id = src.substring(at, pos);
					if (id != "var") continue;
					while (pos < len) {
						pos = src.skipBlanks(pos);
						if (!src.fastCodeAt(pos).isIdent0()) break;
						var nameStart = pos;
						pos = src.skipIdent1(pos);
						var name = src.substring(nameStart, pos);
						if (StringToolsEx.statementKeywords[name]) break;
						var till = pos;
						pos = src.skipBlanks(pos);
						//
						c = src.fastCodeAt(pos);
						if (c == "=".code) {
							pos += 1;
							pos = src.skipExpr(pos);
							till = pos;
							pos = src.skipBlanks(pos);
							c = src.fastCodeAt(pos);
						}
						//
						if (c == ",".code) {
							pos++;
							continue;
						} else if (c.isIdent0()) {
							var afterStart = pos;
							var afterPos = src.skipIdent1(pos);
							var after = src.substring(afterPos, pos);
							if (StringToolsEx.statementKeywords[after]) break;
							flush(till);
							out.addChar(";".code);
							start = till;
							break;
						} else break;
					}
				};
			}
		}
		
		if (start == 0) return src;
		flush(pos);
		return out.toString();
	}
	
	/**
	 * No ternaries in GMS1 but we can convert
	 * (a ? b : c) -> tern_get((a) && tern_set(b) || tern_set(c))
	 * And this will actually work as expected.
	 */
	static function replaceTernaryOperators(src:String):String {
		var isReady = false;
		var out = new StringBuilder();
		var pos = 0;
		var len = src.length;
		var start = 0;
		
		#if !debug inline #end
		function flush(till:Int):Void {
			//if (till < start) throw 'illegal flush ($till<$start) `${src.substring(0, till)}`';
			//out.add(src.substring(start, till));
			out.addSub(src, start, till - start);
		}
		
		while (pos < len) {
			var at = pos;
			var c = src.fastCodeAt(pos++);
			switch (c) {
				case "/".code: pos = src.skipSlashCommon(pos);
				case '@'.code: pos = src.skipAtSignCommon(pos);
				case '"'.code: pos = src.skipString2(pos);
				case "?".code: do {
					if (src.fastCodeAt(src.skipSpaceBackwards(at)) == "[".code) break;
					var condStart = src.skipExprBackwards(at, true);
					var condEnd = src.skipSpaceBackwards(at) + 1;
					var thenStart = src.skipBlanks(pos);
					var thenEnd = src.skipExpr(thenStart);
					var colPos = src.skipBlanks(thenEnd);
					if (src.fastCodeAt(colPos) != ":".code) break;
					var elseStart = src.skipBlanks(colPos + 1);
					var elseEnd = src.skipExpr(elseStart);
					if (!isReady) {
						isReady = true;
						Ruleset.includeIdent("gmv_tern_get");
						Ruleset.includeIdent("gmv_tern_set");
					}
					flush(condStart);
					//
					out.addFormat("tern_get((%s) && tern_set(%s) || tern_set(%s))",
						replaceTernaryOperators(src.substring(condStart, condEnd)),
						replaceTernaryOperators(src.substring(thenStart, thenEnd)),
						replaceTernaryOperators(src.substring(elseStart, elseEnd))
					);
					pos = elseEnd;
					start = pos;
				} while (false);
			}
		}
		
		if (start == 0) return src;
		flush(pos);
		return out.toString();
	}
	
	public static function index(src:String, ctx:String) {
		var pos = 0;
		var len = src.length;
		while (pos < len) {
			var c = src.fastCodeAt(pos++);
			switch (c) {
				case "/".code: pos = src.skipSlashCommon(pos);
				case '@'.code: pos = src.skipAtSignCommon(pos);
				case '"'.code: pos = src.skipString2(pos);
				case _ if (c.isIdent0()): {
					var at = pos - 1;
					pos = src.skipIdent1(pos);
					var id = src.substring(at, pos);
					if (!VitProject.current.apiUses.exists(id)) {
						VitProject.current.apiUses[id] = true;
					}
				};
			}
		}
	}
	
	public static function proc(src:String, ctx:String):String {
		src = escapeComments(src);
		src = fixSpaces(src);
		src = fixVarDecl(src, ctx);
		if (src.indexOf("?") >= 0) src = replaceTernaryOperators(src);
		
		var out = new StringBuf();
		var pos = 0;
		var len = src.length;
		var start = 0;
		
		#if !debug inline #end
		function flush(till:Int):Void {
			//if (till < start) throw 'illegal flush ($till<$start) `${src.substring(0, till)}`';
			//out.add(src.substring(start, till));
			out.addSub(src, start, till - start);
		}
		
		#if !debug inline #end
		function procRemaps(startWord:String, at:Int, remaps:Array<RemapRule>) {
			var debug = false;
			var foundRemap = false;
			var dotPrefixReady = false;
			var dotPrefixString:String = null;
			var dotPrefixStart:StringPos = 0;
			var precedingDot = false;
			var precedingDotPos = -1;
			var precedingDotReady = false;
			for (remap in remaps) {
				var dotIndex = remap.dotIndex;
				if ((dotIndex >= 0 || remap.selfOnly) && !precedingDotReady) {
					precedingDotReady = true;
					var lp = at;
					while (--lp >= 0) {
						var c = src.fastCodeAt(lp);
						if (c.isSpace0()) continue;
						precedingDotPos = lp;
						precedingDot = (c == ".".code);
						break;
					}
				}
				if (remap.selfOnly && precedingDot) continue;
				if (dotIndex >= 0) {
					if (!dotPrefixReady) {
						dotPrefixReady = true;
						if (precedingDot) {
							dotPrefixStart = src.skipDotExprBackwards(precedingDotPos);
							dotPrefixString = src.substring(dotPrefixStart, precedingDotPos);
						}
					}
					if (dotPrefixString == null) continue;
				}
				//
				var flushTill = dotIndex >= 0 ? dotPrefixStart : at;
				if (remap.statOnly) {
					//trace(src.substring(0, flushTill));
					if (!src.isStatementBacktrack(flushTill)) continue;
				} else if (remap.exprOnly) {
					if (src.isStatementBacktrack(flushTill)) continue;
				}
				//
				var caps = null;
				var np = pos;
				var item:RemapRuleItem;
				var inputs = remap.inputs;
				var length = inputs.length;
				var iid = -1;
				var debug_eol:Int = -1;
				if (debug) {
					debug_eol = src.indexOf("\n", pos);
					if (debug_eol < 0) {
						debug_eol = len;
					} else if (src.fastCodeAt(debug_eol - 1) == "\r".code) {
						debug_eol--;
					}
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
						case SkipSet: {
							np = src.skipSpace0(np);
							if (src.fastCodeAt(np++) != "=".code) break;
							if (src.fastCodeAt(np) == "=".code) break;
						};
						case CaptureBinOp(ind), CaptureSetOp(ind): {
							np = src.skipSpace0(np);
							var opStart = np;
							var c = src.fastCodeAt(np++);
							switch (c) {
								case "+".code, "-".code, "*".code, "/".code, "%".code,
									"|".code, "^".code, "&".code
								: {
									var isSet = item.match(CaptureSetOp(_));
									if (isSet) {
										if (src.fastCodeAt(np++) != "=".code) break;
									} else {
										var c1 = src.fastCodeAt(np);
										switch (c1) {
											case "=".code: break;
											case "|".code, "^".code, "&".code if (c == c1): np++;
										}
									}
									if (caps == null) caps = [];
									caps[ind] = src.substring(opStart, np).trim();
								};
								default: break;
							}
						};
						case Capture(capi): {
							var depth = 0;
							var after:String = null;
							if (iid + 1 < length) switch (inputs[iid + 1]) {
								case Text(s): after = s;
								default:
							}
							var np0 = np;
							if (after == null) {
								np = src.skipExpr(np);
								if (caps == null) caps = [];
								caps[capi] = src.substring(np0, np);
							} else while (np < len) {
								var c = src.fastCodeAt(np);
								//trace('$np `${src.substring(np, debug_eol)}`');
								switch (c) {
									case "[".code, "(".code, "{".code: depth++;
									case "]".code, ")".code, "}".code: {
										if (depth-- > 0) {
											np++; continue;
										}
									};
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
									// todo: comments
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
									} else if (depth == 0) {
										np++;
									} else {
										// getting to a closing bracket without having gotten
										// the arguments and alike
										break;
									}
								} else np++;
							} // while (balanced walk till after-expr)
						};
					}
				} // while (iid)
				if (debug) {
					trace('np=$np, id=$iid/$length');
				}
				if (length > 0 && (np < 0 || iid < length)) continue;
				//
				if (dotIndex >= 0) {
					if (caps == null) caps = [];
					caps[remap.dotIndex] = dotPrefixString;
				}
				// process code inside captures (to allow nesting):
				if (caps != null) for (i in 0 ... caps.length) {
					if (caps[i] != null) caps[i] = proc(caps[i].trim(), ctx);
				}
				//
				if (!remap.isUsed) {
					remap.isUsed = true;
					for (imp in remap.dependants) imp.include();
				}
				// flush and print rule output:
				flush(flushTill);
				if (debug) {
					trace("replace", remap.outputs, caps);
					//Sys.getChar(true);
				}
				for (item in remap.outputs) switch (item) {
					case Text(s): out.add(s);
					case Capture(i): out.add(caps[i]);
					case SkipSet: out.add("=");
					case CaptureSetOp(i): {
						var cap = caps[i];
						if (cap != null && !cap.endsWith("=")) cap += "=";
						out.add(cap);
					};
					case CaptureBinOp(i): {
						var cap = caps[i];
						if (cap != null && cap.endsWith("=")) cap = cap.substr(0, cap.length - 1);
						out.add(cap);
					};
				}
				pos = np;
				start = np;
				foundRemap = true;
				break;
			} // for in remaps
			return foundRemap;
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
							case "\\".code: esc = "\\".code; note = "\\";
							case '"'.code: esc = '"'.code; note = '"';
							case "\r".code, "\n".code: esc = -1;
							default: throw 'Escape character $c `'
								+ String.fromCharCode(c) + "` is not supported.";
						}
						if (strBuf == null) {
							strBuf = new StringBuf();
							strBuf.add('(""');
							strQuote = false;
						} else if (strQuote) {
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
					c = src.fastCodeAt(pos);
					if (c == '"'.code || c == "'".code) { // string literals
						flush(at);
						pos = src.skipString1(pos + 1, c);
						out.addSub(src, at + 1, pos - at - 1);
						start = pos;
					}
				};
				case '"'.code: procString2(at);
				case "[".code: { // possibly an array literal
					var lp = at;
					var isLiteral = false;
					while (--lp >= 0) { // walk back to see if it's really a literal
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
							out.add(proc("gmv_array(" + src.substring(at + 1, pos) + ")", ctx));
							start = ++pos;
						}
					}
				};
				case "0".code if (src.fastCodeAt(pos) == "x".code): {
					pos = src.skipHexDigits(pos + 1);
					flush(at);
					out.addChar("$".code);
					out.addSub(src, at + 2, pos - at - 2);
					start = pos;
				};
				case _ if (c.isIdent0()): {
					while (pos < len) {
						c = src.fastCodeAt(pos);
						if (inline c.isIdent1()) {
							pos++;
						} else break;
					}
					var id = src.substring(at, pos);
					var remaps = Ruleset.remaps[id];
					var foundRemap:Bool;
					if (remaps != null) {
						foundRemap = procRemaps(id, at, remaps);
					} else foundRemap = false;
					if (!foundRemap) {
						var arr = Ruleset.importsByIdent[id];
						if (arr != null) for (imp in arr) imp.include();
					}
				};
				default: {
					
				};
			}
		}
		if (start != 0) {
			flush(pos);
			src = out.toString();
		}
		src = src.replace(commentEOLs, "");
		return src;
	}
}
class GmlMacro {
	public var name:String;
	public var value:String;
	public var config:String;
	public function new(name:String, value:String, ?config:String) {
		this.name = name;
		this.value = value;
		this.config = config;
	}
}