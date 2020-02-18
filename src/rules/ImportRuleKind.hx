package rules;

/**
 * ...
 * @author YellowAfterlife
 */
enum abstract ImportRuleKind(Int) {
	var Script;
	var Object;
	var Extension;
	var IncludedFile;
	public static function parse(s:String):ImportRuleKind {
		return switch (s.toLowerCase()) {
			case "script": Script;
			case "object": Object;
			case "extension": Extension;
			default: IncludedFile;
		}
	}
}