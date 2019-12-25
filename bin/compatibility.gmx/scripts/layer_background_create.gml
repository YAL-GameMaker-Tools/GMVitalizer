/// layer_background_create(layer, background, arrayIndex = -1)
with (instance_create_layer(0, 0, argument[0], obj_gmv_layer_background)) {
	backIndex = argument[1];
	if (argument_count > 2) {
		backArrayIndex = argument[2];
		if (backArrayIndex >= 0) {
			background_index[backArrayIndex] = argument[1];
			background_visible[backArrayIndex] = true;
		}
	} else backArrayIndex = -1;
	return id;
}
return -1;
