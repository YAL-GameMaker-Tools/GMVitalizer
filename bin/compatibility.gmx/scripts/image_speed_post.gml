/// image_speed_post(value)
var l_inst = global.image_speed_target;
var l_sprite = l_inst.sprite_index;
if (l_sprite >= 0 && l_sprite < sprite_speed_array_size) {
	l_inst.image_speed = argument0 * sprite_speed_array[l_sprite];
} else l_inst.image_speed = argument0;
