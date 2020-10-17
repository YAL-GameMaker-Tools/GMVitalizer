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

/**
 * ...
 * @author YellowAfterlife
 */
class GMCompFix extends VitProject {
	public var resourceExists:Map<Ident, Bool> = new Map();
	
	//
	function new(path:String) {
		super(path);
		for (yyr in project.resources) {
			var name = yyr.Value.resourceName;
			if (name != null) resourceExists[name] = true;
		}
		//trace(projectDir);
	}
	//
	function addResource(yyr:YyProjectResource):Void {
		var resources = project.resources;
		var ni = yyr.Key;
		var i = -1; while (++i < resources.length) {
			if (ni.toString() < resources[i].Key.toString()) break;
		}
		resources.insert(i, yyr);
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
			var yyr:YyProjectResource = {
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
				case Script: {
					if (scriptView == null) {
						scriptView = makeView(GMScript);
						SysTools.ensureDirectory(fullPath("scripts"));
					}
					var scriptDir = fullPath('scripts\\$name');
					SysTools.ensureDirectory(scriptDir);
					var id = new YyGUID();
					addResource({
						Key: id,
						Value: {
							id: new YyGUID(),
							resourcePath: 'scripts\\$name\\$name.yy',
							resourceType: GMScript
						}
					});
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
		for (yyr in project.resources) switch (yyr.Value.resourceType) {
			case GMScript: {
				var yyv = yyr.Value;
				var gmlPath = Path.withExtension(fullPath(yyv.resourcePath), "gml");
				var yyScript:YyScript = getAssetData(yyr.Key);
				if (yyScript == null) continue;
				if (yyScript.IsCompatibility) {
					// comp script, see if we have a replacement on hand
					var imp = Ruleset.importMap[yyv.resourceName];
					if (imp == null) {
						imp = Ruleset.replaceBy[yyv.resourceName];
						// prevents it from adding to project
						if (imp != null) imp.name = yyv.resourceName;
					}
					if (imp == null || imp.kind != Script) continue;
					var gmlOld = getAssetText(gmlPath);
					var gmlNew = File.getContent(Path.withExtension(imp.path, "gml"));
					if (gmlNew != gmlOld) {
						Sys.println("Modified " + yyv.resourceName + ".");
						File.saveContent(gmlPath, gmlNew);
					}
					imp.include();
				} else {
					var gmlOld = getAssetText(gmlPath);
					var gmlNew = VitGML.proc(gmlOld, yyv.resourceName);
					if (gmlNew != gmlOld) {
						Sys.println("Modified " + yyv.resourceName + ".");
						File.saveContent(gmlPath, gmlNew);
					}
				}
			};
			case GMObject: {
				var yyObject:YyObject = getAssetData(yyr.Key);
				if (yyObject == null) continue;
				var objDir = Path.directory(fullPath(yyr.Value.resourcePath));
				var objName = yyr.Value.resourceName;
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
			default:
		}
		//
		var changedYYP = procImports();
		if (changedYYP) {
			SysTools.blockStart("Saving project");
			for (yyr in project.resources) {
				Reflect.deleteField(yyr.Value, "resourceName");
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