package tools;
import sys.io.File;

/**
 * A miniaturized version of lib-format reader
 * @author YellowAfterlife
 */
class PNGTools {
	public static function getInfo(path:String):PNGInfo {
		var i = File.read(path, true);
		i.bigEndian = true;
		for( b in [137,80,78,71,13,10,26,10] ) {
			if( i.readByte() != b ) throw "Invalid header";
		}
		while (!i.eof()) {
			var dataLen = i.readInt32();
			var id = i.readString(4);
			switch (id) {
				case "IEND": break;
				case "IHDR": {
					var w = i.readInt32();
					var h = i.readInt32();
					return { width: w, height: h };
				};
				default: i.seek(dataLen, sys.io.FileSeek.SeekCur);
			}
		}
		throw "Hit end of file without getting a header";
	}
}
typedef PNGInfo = {
	width:Int,
	height:Int,
};