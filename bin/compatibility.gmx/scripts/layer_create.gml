/// layer_create(depth, ?name)
with (instance_create(0, 0, obj_gmv_layer)) {
	depth = argument[0];
	if (argument_count > 1) {
		name = argument[1];
		nameLQ = string_lower(name);
	} else {
		name = "_layer_" + string(id);
		nameLQ = name;
	}
	return id;
}
return noone;
