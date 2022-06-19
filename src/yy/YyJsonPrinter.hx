package yy;
import haxe.Json;
import haxe.ds.ObjectMap;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class YyJsonPrinter {
	static var isExt:Bool = false;
	static var wantCompact:Bool = false;
	static var trailingCommas:Bool = false;
	static function stringify_string(b:StringBuf, s:String) {
		var r = '"';
		var start = 0;
		for (i in 0 ... s.length) {
			var esc:String;
			switch (StringTools.fastCodeAt(s, i)) {
				case '"'.code: esc = '\\"';
				case '/'.code: esc = isExt ? "/" : '\\/';
				case '\\'.code: esc = '\\\\';
				case '\n'.code: esc = '\\n';
				case '\r'.code: esc = '\\r';
				case '\t'.code: esc = '\\t';
				case 8: esc = '\\b';
				case 12: esc = '\\f';
				default: esc = null;
			}
			if (esc != null) {
				if (i > start) {
					r += s.substring(start, i) + esc;
				} else r += esc;
				start = i + 1;
			}
		}
		if (start == 0) {
			b.add('"$s"');
		} else if (start < s.length) {
			b.add(r + s.substring(start) + '"');
		} else b.add(r + '"');
	}
	
	public static var mvcOrder = ["configDeltas", "id", "modelName", "mvc", "name"];
	public static var orderByModelName:Dictionary<Array<String>> = (function() {
		var q = new Dictionary();
		var plain = ["id", "modelName", "mvc"];
		q["GMExtensionFunction"] = plain.concat([]);
		q["GMEvent"] = plain.concat(["IsDnD"]);
		return q;
	})();
	
	static var isOrderedCache:Map<Array<String>, Dictionary<Bool>> = new Map();
	
	static function fieldComparator(a:String, b:String):Int {
		return a > b ? 1 : -1;
	}
	
	static function addIndent(b:StringBuf, n:Int):Void {
		while (--n >= 0) b.add(indentString);
	}
	static function addIndentPre(b:StringBuf, s:String, n:Int):Void {
		b.add(s);
		while (--n >= 0) b.add(indentString);
	}
	
	static var indentString:String = "    ";
	static function stringify_rec(b:StringBuf, obj:Dynamic, indent:Int, compact:Bool):Void {
		if (obj == null) { // also hits "undefined"
			b.add("null");
		}
		else if (obj is String) {
			stringify_string(b, obj);
		}
		else if (obj is Array) {
			var indentString = YyJsonPrinter.indentString;
			var arr:Array<Dynamic> = obj;
			var len = arr.length;
			var wantedCompact = YyJsonPrinter.wantCompact;
			if (len == 0 && wantedCompact) {
				b.add("[]");
			}
			addIndentPre(b, "[\r\n", ++indent);
			for (i in 0 ... arr.length) {
				if (wantedCompact) {
					if (i > 0) addIndentPre(b, "\r\n", indent);
					stringify_rec(b, arr[i], indent, true);
					b.add(",");
				} else {
					if (i > 0) addIndentPre(b, ",\r\n", indent);
					stringify_rec(b, arr[i], indent, compact);
				}
			}
			addIndentPre(b, "\r\n", --indent);
			b.add("]");
		}
		else if (Reflect.isObject(obj)) {
			var indentString = YyJsonPrinter.indentString;
			if (!compact) {
				addIndentPre(b, "{\r\n", ++indent);
			} else b.add("{");
			var orderedFields:Array<String> = Reflect.field(obj, "hxOrder");
			var found = 0, sep = false;
			if (orderedFields == null) {
				if (Reflect.hasField(obj, "mvc")) {
					orderedFields = orderByModelName[Reflect.field(obj, "modelName")];
				}
				if (orderedFields == null) orderedFields = mvcOrder;
			} else found++;
			//
			var isOrdered:Dictionary<Bool> = isOrderedCache[orderedFields];
			if (isOrdered == null) {
				isOrdered = new Dictionary();
				isOrdered["hxOrder"] = true;
				for (field in orderedFields) isOrdered[field] = true;
				isOrderedCache[orderedFields] = isOrdered;
			}
			//
			var tcs = trailingCommas;
			inline function addField(field:String):Void {
				if (!tcs) {
					if (sep) addIndentPre(b, ",\r\n", indent); else sep = true;
				} else if (!compact) {
					if (sep) addIndentPre(b, "\r\n", indent); else sep = true;
				}
				found++;
				stringify_string(b, field);
				b.add(compact ? ":" : ": ");
				stringify_rec(b, Reflect.field(obj, field), indent, compact);
				if (tcs) b.add(",");
			}
			//
			for (field in orderedFields) {
				if (!Reflect.hasField(obj, field)) continue;
				addField(field);
			}
			//
			var allFields = Reflect.fields(obj);
			if (allFields.length > found) {
				allFields.sort(fieldComparator);
				for (field in allFields) {
					if (isOrdered.exists(field)) continue;
					addField(field);
				}
			}
			if (!compact) {
				addIndentPre(b, "\r\n", --indent);
			}
			b.add("}");
		}
		else {
			b.add(Json.stringify(obj));
		}
	}
	
	public static function stringify(obj:Dynamic, extJson:Bool = false):String {
		wantCompact = extJson;
		trailingCommas = extJson;
		isExt = extJson;
		indentString = extJson ? "  " : "    ";
		var b = new StringBuf();
		stringify_rec(b, obj, 0, false);
		return b.toString();
	}
}
