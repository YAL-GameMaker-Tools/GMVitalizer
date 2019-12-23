package;
using StringTools;
using tools.StringToolsEx;
import Ruleset;

/**
 * GMS2-GML -> GMS1-GML conversion
 * @author YellowAfterlife
 */
class VitGML {
	public static var macroList:Array<GmlMacro> = [];
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
				case "\r".code, "\n".code: {
					if (isInVarDecl) {
						// no need to worry about semicolons if not followed by an identifier
						var np = pos;
						while (np < len) {
							c = src.fastCodeAt(np++);
							switch (c) {
								case " ".code, "\t".code, "\r".code, "\n".code: continue;
								case "/".code: { // comments
									if (np < len) switch (src.fastCodeAt(np)) {
										case "/".code: np = src.skipLine(np + 1);
										case "*".code: np = src.skipComment(np + 1);
									}
								};
								default: {
									if (!c.isIdent0()) {
										isInVarDecl = false;
									}
									break;
								}
							}
						}
					}
					if (isInVarDecl) {
						var lp = commentAt >= 0 ? commentAt : at;
						var needsSemico = false;
						while (--lp >= 0) {
							var c = src.fastCodeAt(lp);
							switch (c) {
								case " ".code, "\t".code: continue;
								case ",".code, "[".code, "(".code,
									// operators:
									"+".code, "-".code, "*".code, "/".code, "%".code,
									"<".code, ">".code, "=".code, "!".code,
									"|".code, "&".code, "^".code
								: break;
								case _ if (c.isIdent1()): {
									var np = lp;
									while (--np >= 0) {
										c = src.fastCodeAt(np);
										if (!c.isIdent1()) break;
									}
									var id = src.substring(np + 1, lp + 1);
									switch (id) {
										case "and", "or", "xor", "not", "var": {};
										default: needsSemico = true;
									}
									break;
								};
								default: needsSemico = true; break;
							}
						} // backtracking to first meaningful character
						if (needsSemico) {
							flush(lp + 1);
							out.addChar(";".code);
							start = lp + 1;
						}
						isInVarDecl = false;
					}
					commentAt = -1;
				};
				case ";".code: isInVarDecl = false;
				case "/".code: { // comments
					if (pos < len) switch (src.fastCodeAt(pos)) {
						case "/".code: {
							commentAt = at;
							pos = src.skipLine(pos + 1);
						};
						case "*".code: pos = src.skipComment(pos + 1);
					}
				};
				case '@'.code: { // possibly string literals
					c = src.fastCodeAt(pos++);
					if (c == '"'.code || c == "'".code) { // it's them
						pos = src.skipString1(pos, c);
					}
				};
				case '"'.code: pos = src.skipString2(pos);
				case _ if (c.isIdent0()): {
					pos = src.skipIdent1(pos);
					var id = src.substring(at, pos);
					if (id == "var") isInVarDecl = true;
				};
			}
		}
		
		if (start == 0) return src;
		flush(pos);
		return out.toString();
	}
	
	public static function fixTernaryOperators():Void {
		/*
		Detection: Upon encountering a `?`,
		we must backtrack to find the start of the expression (`=:[(`, some ops...) 
		and also forward-track to find the end of expression (`)];`, what else)
		
		Implementation:
		a ? b : c -> tern_get(a && tern_set(b) || tern_set(c))
		where
		tern_set(x) => global.tern_value = x; return true;
		tern_get(_) => return global.tern_value;
		
		Specifics: Writing a good expression skipper is inherently unexciting, maybe adapt one
		from GMEdit's linter or something.
		*/
	}
	
	public static function proc(src:String, ctx:String):String {
		src = fixVarDecl(src, ctx);
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
			var foundRemap = false;
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
									} else if (depth == 0) {
										np++;
									} else {
										// getting to a closing bracket without having gotten
										// the arguments and alike
										break;
									}
								} else np++;
							}
						};
					}
				} // while (iid)
				if (debug) {
					trace('np=$np, id=$iid/$length');
				}
				if (length > 0 && (np < 0 || iid < length)) continue;
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
				flush(at);
				if (debug) {
					trace("replace", remap.outputs, caps);
					Sys.getChar(true);
				}
				for (item in remap.outputs) switch (item) {
					case Text(s): out.add(s);
					case Capture(i): out.add(caps[i]);
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
					c = src.fastCodeAt(pos++);
					if (c == '"'.code || c == "'".code) { // string literals
						flush(at);
						pos = src.skipString1(pos, c);
						out.addSub(src, at + 1, pos - at - 1);
						start = pos;
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
								start = pos;
							};
						}
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
							out.add(proc("gmv_array(" + src.substring(at + 1, pos) + ")", ctx));
							start = ++pos;
						}
					}
				};
				case _ if (c.isIdent0()): {
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
		if (start == 0) return src;
		flush(pos);
		return out.toString();
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