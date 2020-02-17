package tools;
import haxe.Timer;
import sys.FileSystem;

/**
 * ...
 * @author YellowAfterlife
 */
class SysTools {
	public static function ensureDirectory(path:String) {
		if (!FileSystem.exists(path)) FileSystem.createDirectory(path);
	}
	static var blockTime:Float;
	public static function blockStart(name:String):Void {
		Sys.print(name + "... ");
		blockTime = Timer.stamp();
	}
	public static function blockEnd():Void {
		var dt = Timer.stamp() - blockTime;
		Sys.println("OK! (" + Math.ceil(dt * 1000) + "ms)");
	}
}