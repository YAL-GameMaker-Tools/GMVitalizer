package yy;

/**
 * ...
 * @author YellowAfterlife
 */
typedef YyView = {
	>YyBase,
	name:YyGUID,
	children:Array<YyGUID>,
	filterType:YyResourceType,
	folderName:String,
	isDefaultView:Bool,
	localisedFolderName:String,
}
