package vit;
import yy.*;
import haxe.io.Path;
import sys.io.File;
import sys.io.FileInput;
import tools.SfGmx;

/**
 * ...
 * @author YellowAfterlife
 */
class VitSound {
	public static function proc(name:String, q:YySound, inPath:String, outPath:String) {
		Sys.println('Converting $name...');
		// detect type
		var s = File.read(Path.withoutExtension(inPath));
		var b0 = s.readByte();
		var b1 = s.readByte();
		var b2 = s.readByte();
		var b3 = s.readByte();
		s.close();
		var type:String;
		if (b0 == "R".code && b1 == "I".code && b2 == "F".code && b3 == "F".code) {
			type = "wav";
		} else type = "ogg";
		//
		var q0 = new SfGmx("sound");
		var q1:SfGmx;
		q0.addIntChild("kind", 0);
		q0.addTextChild("extension", '.$type');
		q0.addTextChild("origname", 'sound\\audio\\$name.$type');
		q0.addIntChild("effects", 0);
		q1 = q0.addEmptyChild("volume");
		q1.addFloatChild("volume", q.volume);
		q0.addFloatChild("pan", 0);
		q1 = q0.addEmptyChild("bitRates");
		q1.addIntChild("bitRate", q.bitRate);
		q1 = q0.addEmptyChild("sampleRates");
		q1.addIntChild("sampleRate", q.sampleRate);
		q1 = q0.addEmptyChild("types");
		q1.addIntChild("type", q.type);
		q1 = q0.addEmptyChild("bitDepths");
		q1.addIntChild("bitDepth", q.bitDepth == 0 ? 8 : 16);
		q0.addBoolChild("preload", q.preload);
		q0.addTextChild("data", '$name.$type');
		q0.addIntChild("compressed", q.kind > 0 ? 1 : 0);
		q0.addIntChild("streamed", q.kind == 3 ? 1 : 0);
		q0.addIntChild("uncompressOnLoad", q.kind == 2 ? 1 : 0);
		q0.addIntChild("audioGroup", 0); // todo
		var audioSource = Path.join([Path.directory(outPath), "audio", '$name.$type']);
		if (!Params.ignoreResourceType["soundsrc"]) {
			File.copy(Path.withoutExtension(inPath), audioSource);
		}
		File.saveContent(outPath + '.sound.gmx', q0.toGmxString());
	}
}