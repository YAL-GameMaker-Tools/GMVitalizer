package ;
import haxe.CallStack;
import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import tools.Alias;
import tools.Dictionary;
import tools.SysTools;
import yy.YyProject;
import yy.YyProjectResource;
import yy.*;
import vit.*;
import yy.YyView;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GMCompFix extends VitProject {
	public var resourceExists:Map<Ident, Bool> = new Map();
	
	//
	function new(path:String) {
		super(path);
		if (v23) {
			for (pair in project.resources) {
				var yyr = pair.v23;
				var name = yyr.id.name;
				if (name != null) resourceExists[name] = true;
			}
		} else {
			for (pair in project.resources) {
				var yyr = pair.v22;
				var name = yyr.Value.resourceName;
				if (name != null) resourceExists[name] = true;
			}
		}
		//trace(projectDir);
	}
	//
	function addResource(yyr:YyProjectResource):Void {
		if (v23) {
			project.resources.push(yyr);
		} else {
			var resources = project.resources;
			var ni = yyr.v22.Key;
			var i = -1; while (++i < resources.length) {
				if (ni.toString() < resources[i].v22.Key.toString()) break;
			}
			resources.insert(i, yyr);
		}
	}
	function flushView(view:YyView) {
		if (view == null) return;
		var id = view.id;
		File.saveContent(fullPath('views//$id.yy'), YyJson.stringify(view));
	}
	//
	function procImports():Bool {
		var changedYYP = false;
		function makeView(type:YyResourceType, name:String = "compfix"):YyView {
			var id = new YyGUID();
			var yyr:YyProjectResource22 = {
				Key: id,
				Value: {
					id: new YyGUID(),
					resourcePath: 'views\\$id.yy',
					resourceType: GMFolder
				}
			};
			//
			var foundParent = false;
			for (rvid in rootView.children) {
				var rv = folders[rvid];
				if (rv == null || rv.filterType != type) continue;
				foundParent = true;
				rv.children.push(id);
				flushView(rv);
			}
			if (!foundParent) throw "Couldn't find parent folder for " + type;
			// sorted insert
			addResource(yyr);
			changedYYP = true;
			//
			var view:YyView = {
				id: id,
				modelName: "GMFolder",
				mvc: "1.1",
				name: id,
				children: [],
				filterType: type,
				folderName: name,
				isDefaultView: false,
				localisedFolderName: ""
			};
			return view;
		}
		//
		var scriptView:YyView = null;
		for (imp in Ruleset.importList) {
			var name = imp.name;
			if (resourceExists[name]) continue;
			SysTools.blockStart('Importing $name');
			switch (imp.kind) {
				case Script if (!v23): {
					if (scriptView == null) {
						scriptView = makeView(GMScript);
						SysTools.ensureDirectory(fullPath("scripts"));
					}
					var scriptDir = fullPath('scripts\\$name');
					SysTools.ensureDirectory(scriptDir);
					var id = new YyGUID();
					var yyr22:YyProjectResource22 = {
						Key: id,
						Value: {
							id: new YyGUID(),
							resourcePath: 'scripts\\$name\\$name.yy',
							resourceType: GMScript
						}
					};
					addResource(yyr22);
					scriptView.children.push(id);
					//
					var yyScript:YyScript = {
						id: id,
						modelName: "GMScript",
						mvc: "1.0",
						name: name,
						IsCompatibility: true,
						IsDnD: false
					};
					File.saveContent('$scriptDir/$name.yy', YyJson.stringify(yyScript));
					//
					var dest = '$scriptDir/$name.gml';
					File.copy(Path.withExtension(imp.path, "gml"), dest);
				};
				default: Sys.println('Can\'t import ${imp.kind} yet (for $name)');
			}
			SysTools.blockEnd();
		}
		for (view in [scriptView]) flushView(view);
		return changedYYP;
	}
	public function proc() {
		if (!isOK) return;
		VitProject.current = this;
		index();
		Ruleset.init();
		forEachResource(function(name, path, type, guid) {
			switch (type) {
				case GMScript: {
					var gmlPath = Path.withExtension(fullPath(path), "gml");
					var yyScript:YyScript = getAssetData(guid);
					if (yyScript == null) return;
					if (yyScript.IsCompatibility) {
						// comp script, see if we have a replacement on hand
						var imp = Ruleset.importMap[name];
						if (imp == null) {
							imp = Ruleset.replaceBy[name];
							// prevents it from adding to project
							if (imp != null) imp.name = name;
						}
						if (imp == null || imp.kind != Script) return;
						var gmlOld = getAssetText(gmlPath);
						var gmlNew = File.getContent(Path.withExtension(imp.path, "gml"));
						if (gmlNew != gmlOld) {
							Sys.println("Modified " + name + ".");
							File.saveContent(gmlPath, gmlNew);
						}
						imp.include();
					} else {
						var gmlOld = getAssetText(gmlPath);
						var gmlNew = VitGML.proc(gmlOld, name);
						if (gmlNew != gmlOld) {
							Sys.println("Modified " + name + ".");
							File.saveContent(gmlPath, gmlNew);
						}
					}
				};
				case GMObject: {
					var yyObject:YyObject = getAssetData(guid);
					if (yyObject == null) return;
					var objDir = Path.directory(fullPath(path));
					var objName = name;
					for (qe in yyObject.eventList) {
						var epath = VitObject.getEventFileName(qe);
						var efull = Path.join([objDir, epath + ".gml"]);
						var ectx = '$objName:$epath';
						var gmlOld = getAssetText(efull);
						var gmlNew = VitGML.proc(gmlOld, ectx);
						if (gmlNew != gmlOld) {
							Sys.println('Modified $ectx.');
							File.saveContent(efull, gmlNew);
						}
					}
				};
				case GMExtension: {
					var yyExt:YyExtension = getAssetData(guid);
					var extDir = Path.directory(fullPath(path));
					for (file in yyExt.files) {
						if (Path.extension(file.filename).toLowerCase() != "gml") continue;
						var fileFull = Path.join([extDir, file.filename]);
						var fileCtx = yyExt.name + ":" + file.filename;
						var gmlOld = getAssetText(fileFull);
						var gmlNew = VitGML.proc(gmlOld, fileCtx);
						if (gmlNew != gmlOld) {
							Sys.println('Modified $fileCtx.');
							File.saveContent(fileFull, gmlNew);
						}
					}
				};
				default:
			}
		});
		//
		var changedYYP = procImports();
		if (changedYYP) {
			SysTools.blockStart("Saving project");
			if (!v23) for (yyr in project.resources) {
				Reflect.deleteField(yyr.v22.Value, "resourceName");
			}
			File.saveContent(projectPath, YyJson.stringify(project));
			SysTools.blockEnd();
		} else Sys.println("Project file unchanged.");
		VitProject.current = null;
	}
	public static function main() {
		var args = Sys.args();
		args = Params.proc(args);
		if (args.length == 0) {
			Sys.println("How to use: GMCompFix <path to YYP>");
			Sys.println("(in PowerShell, do .\\GMCompFix <path to YYP>)");
			Sys.println("Don't forget to make a backup of your project!");
			Sys.println("Add --nowait to skip 'press any key to exit'.");
			Sys.println("Press any key to exit.");
			Sys.getChar(false);
			return;
		}
		//
		try {
			var path = args[0];
			switch (Path.extension(path).toLowerCase()) {
				case "gml": {
					Ruleset.init();
					var gml = File.getContent(path);
					gml = VitGML.proc(gml, Path.withoutDirectory(path), false);
					File.saveContent(args[1], gml);
				};
				case "yyp": {
					var pj = new GMCompFix(args[0]);
					pj.proc();
				};
				default: throw "Expected a YYP";
			}
		} catch (x:Dynamic) {
			Sys.println("Got an error: " + x);
			Sys.println(CallStack.toString(CallStack.exceptionStack()));
		}
		Sys.println("Press any key to exit.");
		Sys.getChar(false);
	}
}