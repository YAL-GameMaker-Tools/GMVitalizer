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
class VitObject {
	static var eventTypeNames:Array<String> = {
		var r = [];
		inline function linkType(i:Int, s:String) r[i] = s;
		for (i in 0 ... 16) linkType(i, "event" + i);
		linkType(0, "Create");
		linkType(1, "Destroy");
		linkType(2, "Alarm");
		linkType(3, "Step");
		linkType(4, "Collision");
		linkType(5, "Keyboard");
		linkType(6, "Mouse");
		linkType(7, "Other");
		linkType(8, "Draw");
		linkType(9, "KeyPress");
		linkType(10, "KeyRelease");
		linkType(12, "CleanUp");
		linkType(13, "Gesture");
		r;
	};
	public static function proc(name:String, q:YyObject, inPath:String, outPath:String) {
		Sys.println('Converting $name...');
		var pj = VitProject.current;
		//
		inline function nameOf(s:String) {
			return s != null ? s : "<undefined>";
		}
		var q0 = new SfGmx("object");
		var q1:SfGmx;
		q0.addTextChild("spriteName", nameOf(pj.spriteNames[q.spriteId]));
		q0.addBoolChild("solid", q.solid);
		q0.addBoolChild("visible", q.visible);
		q0.addIntChild("depth", 0);
		q0.addBoolChild("persistent", q.persistent);
		q0.addTextChild("parentName", nameOf(pj.objectNames[q.parentObjectId]));
		q0.addTextChild("maskName", nameOf(pj.spriteNames[q.maskSpriteId]));
		q1 = q0.addEmptyChild("events");
		var inDir = Path.directory(inPath);
		for (e in q.eventList) {
			var q2 = q1.addEmptyChild("event");
			q2.setInt("eventtype", e.eventtype);
			if (e.eventtype == 4) {
				q2.set("ename", nameOf(pj.objectNames[e.collisionObjectId]));
			} else q2.setInt("enumb", e.enumb);
			var q3 = q2.addEmptyChild("action");
			q3.addIntChild("libid", 1);
			q3.addIntChild("id", 603);
			q3.addIntChild("kind", 7);
			q3.addIntChild("userelative", 0);
			q3.addIntChild("isquestion", 0);
			q3.addIntChild("useapplyto", -1);
			q3.addIntChild("exetype", 2);
			q3.addTextChild("functionname", "");
			q3.addTextChild("codestring", "");
			q3.addTextChild("whoName", "self");
			q3.addIntChild("relative", 0);
			q3.addIntChild("isnot", 0);
			var q4 = q3.addEmptyChild("arguments");
			var q5 = q4.addEmptyChild("argument");
			q5.addIntChild("kind", 0);
			//
			var epath = eventTypeNames[e.eventtype];
			if (e.eventtype == 4) {
				epath += "_" + e.id;
			} else epath += "_" + e.enumb;
			var efull = Path.join([inDir, epath + ".gml"]);
			var gml = File.getContent(efull);
			gml = VitGML.proc(gml, epath);
			q5.addTextChild("string", gml);
		}
		q0.addBoolChild("PhysicsObject", q.physicsObject);
		q0.addBoolChild("PhysicsObjectSensor", q.physicsSensor);
		q0.addIntChild("PhysicsObjectShape", q.physicsShape);
		q0.addFloatChild("PhysicsObjectDensity", q.physicsDensity);
		q0.addFloatChild("PhysicsObjectRestitution", q.physicsRestitution);
		q0.addIntChild("PhysicsObjectGroup", q.physicsGroup);
		q0.addFloatChild("PhysicsObjectLinearDamping", q.physicsLinearDamping);
		q0.addFloatChild("PhysicsObjectAngularDamping", q.physicsAngularDamping);
		q0.addFloatChild("PhysicsObjectFriction", q.physicsFriction);
		q0.addBoolChild("PhysicsObjectAwake", q.physicsStartAwake);
		q0.addBoolChild("PhysicsObjectKinematic", q.physicsKinematic);
		q1 = q0.addEmptyChild("PhysicsShapePoints");
		if (q.physicsShapePoints != null) 
		for (p in q.physicsShapePoints) {
			q1.addTextChild("point", p.x + "," + p.y);
		}
		File.saveContent(outPath + '.object.gmx', q0.toGmxString());
	}
}