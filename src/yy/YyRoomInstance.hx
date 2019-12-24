package yy;

/**
 * @author YellowAfterlife
 */
typedef YyRoomInstance = {
	name:String,
	id:YyGUID,
	colour:{
		Value:Int
	},
	creationCodeFile:String,
	creationCodeType:String,
	ignore:Bool,
	imageIndex:Float,
	imageSpeed:Float,
	inheritCode:Bool,
	inheritItemSettings:Bool,
	IsDnD:Bool,
	m_originalParentID:YyGUID,
	m_serialiseFrozen:Bool,
	modelName:String,
	name_with_no_file_rename:String,
	objId:YyGUID,
	properties:Any,
	rotation:Float,
	scaleX:Float,
	scaleY:Float,
	mvc:String,
	x:Float,
	y:Float
};