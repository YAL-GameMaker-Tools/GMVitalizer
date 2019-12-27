package vit;
import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import yy.*;
import tools.SfGmx;
import tools.Alias;
using StringTools;

/**
 * Config deltas are so unpure
 * @author YellowAfterlife
 */
class VitProjectOptions {
	public static inline var defTxG:YyGUID = cast "1225f6b0-ac20-43bd-a82e-be73fa0b6f4f";
	public static inline var defAuG:YyGUID = cast "7b2c4976-1e09-44e5-8256-c527145e03bb";
	public static function proc(pj:VitProject) {
		var outPath = pj.outDir + "/Configs/Default.config.gmx";
		var config:SfGmx = try {
			SfGmx.parse(File.getContent(outPath));
		} catch (_:Dynamic) {
			trace("No config available, copying default");
			var defPath = GMVitalizer.dir + "/compatibility.gmx/Configs/Default.config.gmx";
			var template = File.getContent(defPath);
			template = template.replace('compProjectName', pj.outName);
			SfGmx.parse(template);
		}
		var options = config.find("Options");
		//
		var rawDeltas = File.getContent(
			pj.projectDir + "/options/main/inherited/options_main.inherited.yy"
		);
		rawDeltas = ~/(\n[ \t]*"targets":[ \t]*)(\d+)([\r\n,])/g.replace(rawDeltas, '$1"$2"$3');
		//
		function read(guid:String, fn:Dynamic->Void) {
			var rs = '←$guid\\|({\r?\n[\\s\\S]+?\n})';
			var rx = new EReg(rs, '');
			if (rx.match(rawDeltas)) {
				var s = rx.matched(1);
				fn(Json.parse(s));
			}// else trace('$rs -> no match');
		}
		//{ texture groups
		var confTexGroups:Array<VitConfigTxG> = [{
			name:"Default",
			targets:"461609314234257646",
			autocrop:true,
			border:2,
			parent:null,
			scaled:true
		}];
		pj.textureGroupIDs[defTxG] = 0;
		read(defTxG, function(txg:VitOptTxG) {
			var defCTxG = confTexGroups[0];
			if (txg.groupName != null) defCTxG.name = txg.groupName;
			if (txg.targets != null) defCTxG.targets = txg.targets;
			if (txg.autocrop != null) defCTxG.autocrop = txg.autocrop;
			if (txg.border != null) defCTxG.border = txg.border;
			if (txg.scaled != null) defCTxG.scaled = txg.scaled;
		});
		read("be5f1418-b31b-48af-a023-f04cdf6e5121", function(txgDelta:VitOptTxGDelta) {
			if (txgDelta.textureGroups == null) return;
			if (txgDelta.textureGroups.Additions == null) return;
			var ctxgToCheckParentFor = [];
			for (txgPair in txgDelta.textureGroups.Additions) {
				var txg:VitOptTxG = txgPair.Value;
				pj.textureGroupIDs[txg.id] = txgPair.Key;
				var ctxg = {
					name:txg.groupName,
					targets:txg.targets,
					autocrop:txg.autocrop,
					border:txg.border,
					parent:cast txg.groupParent,
					scaled:txg.scaled,
				};
				if (txg.groupParent != YyGUID.zero) {
					ctxgToCheckParentFor.push(ctxg);
				} else ctxg.parent = null;
				confTexGroups[txgPair.Key] = ctxg;
			}
			for (ctxg in ctxgToCheckParentFor) {
				ctxg.parent = confTexGroups[pj.textureGroupIDs[cast ctxg.parent]].name;
			}
		});
		{
			// remove existing config items:
			var i = options.children.length;
			var refNode = null;
			while (--i >= 0) {
				var oc = options.children[i];
				if (oc.name.startsWith("option_textureGroup")) {
					if (refNode == null) refNode = options.children[i + 1];
					options.removeChildAt(i);
				}
			}
			// add new ones:
			for (i in 0 ... confTexGroups.length) {
				var ctxg = confTexGroups[i];
				options.insertBefore(new SfGmx(
					'option_textureGroup${i}_border', Std.string(ctxg.border)
				), refNode);
				options.insertBefore(new SfGmx(
					'option_textureGroup${i}_nocropping', ctxg.autocrop ? "0" : "-1"
				), refNode);
				options.insertBefore(new SfGmx(
					'option_textureGroup${i}_parent', ctxg.parent != null ? ctxg.parent : "<none>"
				), refNode);
				options.insertBefore(new SfGmx(
					'option_textureGroup${i}_scaled', ctxg.scaled ? "-1" : "0"
				), refNode);
				options.insertBefore(new SfGmx(
					'option_textureGroup${i}_targets', ctxg.targets
				), refNode);
			}
			// encore:
			options.insertBefore(new SfGmx(
				'option_textureGroup_count', Std.string(confTexGroups.length)
			), refNode);
			for (i in 0 ... confTexGroups.length) {
				options.insertBefore(new SfGmx(
					'option_textureGroups${i}', confTexGroups[i].name
				), refNode);
			}
		};
		//}
		//{ audio groups
		pj.audioGroupIDs[defAuG] = 0;
		pj.audioGroupNames[0] = "audiogroup_default";
		var augTargets = [];
		read("7fa50043-cea6-4cd0-9521-a8ba8c6ea9f0", function(augDelta:VitOptAuGDelta) {
			if (augDelta.audioGroups == null) return;
			if (augDelta.audioGroups.Additions == null) return;
			for (augPair in augDelta.audioGroups.Additions) {
				var aug = augPair.Value;
				pj.audioGroupIDs[aug.id] = augPair.Key;
				pj.audioGroupNames[augPair.Key] = aug.groupName;
				augTargets[augPair.Key] = aug.targets;
			}
		});
		{
			// remove existing config items:
			var i = options.children.length;
			var refNode = null;
			while (--i >= 0) {
				var oc = options.children[i];
				if (oc.name.startsWith("option_audioGroup")) {
					if (refNode == null) refNode = options.children[i + 1];
					options.removeChildAt(i);
				}
			}
			//
			for (i in 0 ... augTargets.length) {
				if (augTargets[i] != null) options.insertBefore(new SfGmx(
					'option_audioGroup${i}_targets', Std.string(augTargets[i])
				), refNode);
			}
			options.insertBefore(new SfGmx(
				'option_audioGroupCount', Std.string(pj.audioGroupNames.length)
			), refNode);
		};
		//}
		// whew
		File.saveContent(outPath, config.toGmxString());
	}
}

private typedef VitConfigTxG = {
	name:String,
	targets:ConfigTargets,
	autocrop:Bool,
	border:Int,
	parent:String,
	scaled:Bool,
};
private typedef VitOptTxG = {
	id:YyGUID,
	modelName:String,
	mvc:String,
	?groupName:String,
	?targets:ConfigTargets,
	?autocrop:Bool,
	?border:Int,
	?groupParent:YyGUID,
	?mipsToGenerate:Int,
	?scaled:Bool
};
private typedef VitOptTxGDelta = {
	textureGroups:{
		Additions:Array<{
			Key:Int,
			Value:VitOptTxG
		}>,
		Checksum:String,
		Deletions:Array<Any>,
		Ordering:Array<Any>
	}, // if there's no comma here, FD doesn't highlight next type
};
private typedef VitOptAuGDelta = {
	audioGroups:{
		Additions:Array<{
			Key:Int,
			Value:{
				id:YyGUID,
				modelName:String,
				mvc:String,
				groupName:String,
				targets:ConfigTargets
			}
		}>,
		Checksum:String,
		Deletions:Array<Any>,
		Ordering:Array<Any>
	}
}