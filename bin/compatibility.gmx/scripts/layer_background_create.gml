/// layer_background_create(layer, sprite)
with (instance_create_layer(0, 0, argument0, obj_gmv_layer_background)) {
	sprite_index = argument1;
	return id;
}
return -1;