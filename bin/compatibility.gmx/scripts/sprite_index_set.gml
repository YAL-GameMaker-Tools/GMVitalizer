/// sprite_index_set(id, sprite)
var l_inst = argument0;
var l_sprite = l_inst.sprite_index;
var l_image_speed;
if (l_sprite >= 0 && l_sprite < sprite_speed_array_size) {
	l_image_speed = l_inst.image_speed / sprite_speed_array[l_sprite];
} else l_image_speed = l_inst.image_speed;
//
l_inst.sprite_index = argument1;
if (argument1 >= 0 && argument1 < sprite_speed_array_size) {
	l_inst.image_speed = l_image_speed * sprite_speed_array[argument1];
} else l_inst.image_speed = l_image_speed;
