/// image_speed_set(id, speed)
var l_inst = argument0;
var l_sprite = l_inst.sprite_index;
if (l_sprite >= 0 && l_sprite < sprite_speed_array_size) {
	l_inst.image_speed = argument1 * sprite_speed_array[l_sprite];
} else l_inst.image_speed = argument1;
