package yy;

/**
 * ...
 * @author YellowAfterlife
 */
typedef YyProject = {
	>YyBase,
	resources:Array<YyProjectResource>,
	//
	?Folders:Array<YyProjectFolder>,
};
typedef YyProjectFolder = {
	>YyBase,
	folderPath:String,
	name:String,
}
