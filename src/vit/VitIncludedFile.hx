package vit;
import yy.*;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import tools.SfGmx;

/**
 * ...
 * @author YellowAfterlife
 */
class VitIncludedFile {
	public static function proc(
		name:String, q:YyIncludedFile, inPath:String, outPath:String,
		outNode:SfGmx, chain:Array<String>
	) {
		Sys.println('Converting $name...');
		var q0 = outNode;
		q0.text = null;
		q0.addTextChild("name", q.name);
		q0.addBoolChild("exists", q.exists);
		q0.addIntChild("size", q.size);
		q0.addIntChild("exportAction", q.exportAction);
		q0.addTextChild("exportDir", q.exportDir);
		q0.addBoolChild("overwrite", q.overwrite);
		q0.addBoolChild("freeData", q.freeData);
		q0.addBoolChild("removeEnd", q.removeEnd);
		q0.addBoolChild("store", q.store);
		var q1 = q0.addEmptyChild("ConfigOptions");
		var q2 = q1.addEmptyChild("Config");
		q2.set("name", "Default");
		q2.addFloatChild("CopyToMask", q.CopyToMask);
		q0.addTextChild("filename", q.fileName);
		//
		if (!Params.ignoreResourceType["datafilesrc"]) {
			var pj = VitProject.current;
			var dstDir = pj.outDir + "/datafiles";
			for (rel in chain.slice(1)) {
				dstDir += "/" + rel;
				if (!FileSystem.exists(dstDir)) FileSystem.createDirectory(dstDir);
			}
			File.copy(
				pj.projectDir + "/" + q.filePath + "/" + q.fileName,
				dstDir + "/" + q.fileName
			);
		}
	}
}