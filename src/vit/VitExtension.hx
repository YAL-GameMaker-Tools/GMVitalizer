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
class VitExtension {
	public static function proc(name:String, q:YyExtension, inPath:String, outPath:String) {
		var q0 = new SfGmx("extension");
		var q1:SfGmx;
		q0.addTextChild("name", q.name);
		q0.addTextChild("version", q.version);
		q0.addTextChild("packageID", q.packageID);
		q0.addTextChild("ProductID", q.productID);
		q0.addTextChild("date", q.date);
		q0.addTextChild("license", q.license);
		q0.addTextChild("description", q.description);
		q0.addTextChild("helpfile", q.helpfile);
		q0.addTextChild("installdir", q.installdir);
		q0.addTextChild("classname", q.classname);
		q0.addTextChild("androidclassname", q.androidclassname);
		q0.addTextChild("sourcedir", q.sourcedir);
		q0.addTextChild("androidsourcedir", q.androidsourcedir);
		q0.addTextChild("macsourcedir", q.macsourcedir);
		q0.addTextChild("maclinkerflags", q.maclinkerflags);
		q0.addTextChild("maccompilerflags", q.maccompilerflags);
		q0.addTextChild("androidinject", q.androidinject);
		q0.addTextChild("androidmanifestinject", q.androidmanifestinject);
		q0.addTextChild("iosplistinject", q.iosplistinject);
		q0.addTextChild("androidactivityinject", q.androidactivityinject);
		q0.addTextChild("gradleinject", q.gradleinject);
		q0.addEmptyChild("iosSystemFrameworks"); // todo
		q0.addEmptyChild("iosThirdPartyFrameworks"); // todo
		q1 = q0.addEmptyChild("ConfigOptions");
		{
			var q2:SfGmx;
			q2 = q1.addEmptyChild("Config");
			q2.set("name", "Default");
			q2.addTextChild("CopyToMask", q.copyToTargets);
		}
		q0.addEmptyChild("androidPermissions");
		q0.addEmptyChild("IncludedResources");
		q1 = q0.addEmptyChild("files");
		var copyFiles = !Params.ignoreResourceType["extfile"];
		//
		var inDir = Path.directory(inPath);
		var outDir = Path.directory(outPath) + "/" + name;
		if (copyFiles) {
			if (!FileSystem.exists(outDir)) FileSystem.createDirectory(outDir);
		}
		//
		for (file in q.files) {
			var fname = file.filename;
			try {
				var inFile = inDir + "/" + fname;
				var outFile = outDir + "/" + fname;
				if (Path.extension(fname).toLowerCase() == "gml") {
					var gml = File.getContent(inFile);
					gml = VitGML.proc(gml, fname);
					File.saveContent(outFile, gml);
				} else File.copy(inFile, outFile);
			} catch (x:Dynamic) {
				trace('Failed to copy $name:$fname: $x');
			}
			var q2:SfGmx;
			q2 = q1.addEmptyChild("file");
			var q3:SfGmx;
			q2.addTextChild("filename", file.filename);
			q2.addTextChild("origname", file.origname);
			q2.addTextChild("init", file.init);
			q2.addTextChild("final", Reflect.field(file, "final"));
			q2.addIntChild("kind", file.kind);
			q2.addBoolChild("uncompress", file.uncompress);
			//
			q3 = q2.addEmptyChild("ConfigOptions");
			{
				var q4 = q3.addEmptyChild("Config");
				q4.set("name", "Default");
				q4.addTextChild("CopyToMask", file.copyToTargets);
			}
			//
			q2.addEmptyChild("ProxyFiles");
			q3 = q2.addEmptyChild("functions");
			for (fn in file.functions) {
				var q4 = q3.addEmptyChild("function");
				q4.addTextChild("name", fn.name);
				q4.addTextChild("externalName", fn.externalName);
				q4.addIntChild("kind", fn.kind);
				q4.addTextChild("help", fn.help);
				q4.addIntChild("returnType", fn.returnType);
				q4.addIntChild("argCount", fn.argCount);
				var q5 = q4.addEmptyChild("args");
				for (arg in fn.args) q5.addIntChild("arg", arg);
			}
			q3 = q2.addEmptyChild("constants");
			for (mc in file.constants) {
				var q4 = q3.addEmptyChild("constant");
				q4.addTextChild("name", mc.constantName);
				q4.addTextChild("value", mc.value);
				q4.addBoolChild("hidden", mc.hidden);
			}
		}
		File.saveContent(outPath + '.extension.gmx', q0.toGmxString());
	}
}