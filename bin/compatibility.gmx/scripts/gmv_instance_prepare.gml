/// gmv_instance_prepare(inst, depth)
with (argument0) {
	depth = argument1;
	if (sprite_index >= 0 && sprite_index < sprite_speed_array_size) {
		image_speed *= sprite_speed_array[sprite_index];
	}
}