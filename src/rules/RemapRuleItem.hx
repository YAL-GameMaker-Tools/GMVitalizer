package rules;
import haxe.ds.Map;
import haxe.io.Path;
import tools.Alias;
import tools.SfGmx;
using StringTools;
using tools.StringToolsEx;

/**
 * @author YellowAfterlife
 */
enum RemapRuleItem {
	Text(s:String);
	Capture(ind:Int);
	SkipSet; // `=`, no `==`
	CaptureSetOp(ind:Int); // `+=`
	CaptureBinOp(ind:Int); // `+`
}
