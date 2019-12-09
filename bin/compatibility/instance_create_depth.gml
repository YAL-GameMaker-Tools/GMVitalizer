/// instance_create_depth(x, y, depth, obj)

// this is less clean but what a delightful hack
var l_depth = object_get_depth(argument3);
object_set_depth(argument3, argument2);
var l_result = instance_create(argument0, argument1, argument3);
object_set_depth(argument3, l_depth);
return l_result;

/*// this is cleaner but won't work object checks depth in Create
var r = instance_create(argument0, argument1, argument3);
r.depth = argument2;
return r;
*/