package yy;

/**
 * ...
 * @author YellowAfterlife
 */
enum abstract YyResourceType(String) {
	var GMScript;
	var GMSprite;
	var GMRoom;
	var GMExtension;
	var GMTileSet;
	var GMObject;
	var GMFolder;
	public inline function toString():String return this;
}