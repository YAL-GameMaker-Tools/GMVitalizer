package ;

/**
 * Ever try debugging Neko VM?
 * @author YellowAfterlife
 */
class GMCompFixJS {
	@:keep @:expose("compfix")
	static function compfix(gml:String):String {
		Ruleset.init();
		gml = VitGML.proc(gml, "js.gml", false);
		return gml;
	}
	public static function main() {
		
	}
}