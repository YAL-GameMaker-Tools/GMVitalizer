remap d3d_set_culling($1) -> gpu_set_cullmode(($1) ? cull_counterclockwise : cull_noculling)
remap d3d_set_fog -> gpu_set_fog
remap d3d_set_hidden -> gpu_set_ztestenable
remap d3d_set_lighting -> draw_set_lighting
remap d3d_set_zwriteenable -> gpu_set_zwriteenable
remap draw_enable_alphablend -> gpu_set_blendenable
remap draw_get_alpha_test -> gpu_get_alphatestenable
remap draw_set_alpha_test -> gpu_set_alphatestenable
remap draw_get_alpha_test_ref_value -> gpu_get_alphatestref
remap draw_set_alpha_test_ref_value -> gpu_set_alphatestref
remap draw_set_blend_mode -> gpu_set_blendmode
remap draw_set_blend_mode_ext -> gpu_set_blendmode_ext
remap draw_set_color_write_enable -> gpu_set_colorwriteenable
remap draw_set_colour_write_enable -> gpu_set_colourwriteenable
remap texture_set_interpolation -> gpu_set_texfilter
remap texture_set_interpolation_ext -> gpu_set_texfilter_ext
remap texture_set_repeat -> gpu_set_texrepeat
remap texture_set_repeat_ext -> gpu_set_texrepeat_ext

//{ view
remap __view_get( e__VW.XView, $1 ) -> camera_get_view_x(view_camera[$1])
remap __view_get( e__VW.YView, $1 ) -> camera_get_view_y(view_camera[$1])
remap __view_get( e__VW.HView, $1 ) -> camera_get_view_height(view_camera[$1])
remap __view_get( e__VW.WView, $1 ) -> camera_get_view_width(view_camera[$1])
remap __view_get( e__VW.Angle, $1 ) -> camera_get_view_angle(view_camera[$1])
remap __view_get( e__VW.HBorder, $1 ) -> camera_get_view_border_x(view_camera[$1])
remap __view_get( e__VW.VBorder, $1 ) -> camera_get_view_border_y(view_camera[$1])
remap __view_get( e__VW.HSpeed, $1 ) -> camera_get_view_speed_x(view_camera[$1])
remap __view_get( e__VW.VSpeed, $1 ) -> camera_get_view_speed_y(view_camera[$1])
remap __view_get( e__VW.Object, $1 ) -> camera_get_view_target(view_camera[$1])
remap __view_get( e__VW.Visible, $1 ) -> view_visible[$1]
remap __view_get( e__VW.XPort, $1 ) -> view_xport[$1]
remap __view_get( e__VW.YPort, $1 ) -> view_yport[$1]
remap __view_get( e__VW.HPort, $1 ) -> view_hport[$1]
remap __view_get( e__VW.WPort, $1 ) -> view_wport[$1]
remap __view_get( e__VW.SurfaceID, $1 ) -> view_surface_id[$1]
//
remap __view_set( e__VW.XView, $1, $2 ) -> camera_set_view_x(view_camera[$1], $2)
remap __view_set( e__VW.YView, $1, $2 ) -> camera_set_view_y(view_camera[$1], $2)
remap __view_set( e__VW.HView, $1, $2 ) -> camera_set_view_height(view_camera[$1], $2)
remap __view_set( e__VW.WView, $1, $2 ) -> camera_set_view_width(view_camera[$1], $2)
remap __view_set( e__VW.Angle, $1, $2 ) -> camera_set_view_angle(view_camera[$1], $2)
remap __view_set( e__VW.HBorder, $1, $2 ) -> camera_set_view_border_x(view_camera[$1], $2)
remap __view_set( e__VW.VBorder, $1, $2 ) -> camera_set_view_border_y(view_camera[$1], $2)
remap __view_set( e__VW.HSpeed, $1, $2 ) -> camera_set_view_speed_x(view_camera[$1], $2)
remap __view_set( e__VW.VSpeed, $1, $2 ) -> camera_set_view_speed_y(view_camera[$1], $2)
remap __view_set( e__VW.Object, $1, $2 ) -> camera_set_view_target(view_camera[$1], $2)
remap __view_set( e__VW.Visible, $1, $2 ) -> view_visible[$1] = $2
remap __view_set( e__VW.XPort, $1, $2 ) -> view_xport[$1] = $2
remap __view_set( e__VW.YPort, $1, $2 ) -> view_yport[$1] = $2
remap __view_set( e__VW.HPort, $1, $2 ) -> view_hport[$1] = $2
remap __view_set( e__VW.WPort, $1, $2 ) -> view_wport[$1] = $2
remap __view_set( e__VW.SurfaceID, $1, $2 ) -> view_surface_id[$1] = $2
//}

#if defs["no_background"]
// Replaces background-functions with their sprite equivalents (-D no_background).
// Note that this more or less implies that you
// will not be able to convert them back via GMVitalizer later.
remap background_add($1, $2, $3) -> sprite_add($1, 0, $2, $3, 0, 0)
remap background_assign -> sprite_assign
remap background_delete -> sprite_delete
remap background_duplicate -> sprite_duplicate
remap background_exists -> sprite_exists
remap background_get_width -> sprite_get_width
remap background_get_height -> sprite_get_height
remap background_get_name -> sprite_get_name
remap background_get_texture($1) -> sprite_get_texture($1, 0)
remap background_get_uvs($1) -> sprite_get_uvs($1, 0)
remap background_prefetch -> sprite_prefetch
remap background_prefetch_multi -> sprite_prefetch_multi
remap background_replace($1, $2, $3, $4) -> sprite_replace($1, $2, 1, $3, $4, 0, 0)
remap background_set_alpha_from_background -> sprite_set_alpha_from_sprite
remap draw_background($1, $2, $3) -> draw_sprite($1, 0, $2, $3)
remap draw_background_ext($1, $2, $3, $4, $5, $6, $7, $8) -> draw_sprite_ext($1, 0, $2, $3, $4, $5, $6, $7, $8)
remap draw_background_general($0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) -> draw_sprite_general($0, 0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
remap draw_background_part($0, $1, $2, $3, $4, $5, $6) -> draw_sprite_part($0, 0, $1, $2, $3, $4, $5, $6)
remap draw_background_part_ext($0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10) -> draw_sprite_part_ext($0, 0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
remap draw_background_stretched($0, $1, $2, $3, $4) -> draw_sprite_stretched_ext($0, 0, $1, $2, $3, $4)
remap draw_background_stretched_ext($0, $1, $2, $3, $4, $5, $6) -> draw_sprite_stretched_ext($0, 0, $1, $2, $3, $4, $5, $6)
remap draw_background_tiled($0, $1, $2) -> draw_sprite_tiled($0, 0, $1, $2)
remap draw_background_tiled_ext($0, $1, $2, $3, $4, $5, $6) -> draw_sprite_ext($1, 0, $2, $3, $4, $5, $6)
#end

#if defs["tile_caching"]
import tile_cache_flush
import tile_get_region

replace tile_get_left with __tile_get_left
replace tile_get_top with __tile_get_top
replace tile_get_width with __tile_get_width
replace tile_get_height with __tile_get_height

replace tile_add with __tile_add
replace tile_delete with __tile_delete

replace tile_get_ids_at_depth with __tile_get_ids_at_depth
replace tile_get_ids with __tile_get_ids
replace tile_layer_find with __tile_layer_find

remap tile_get_background -> layer_tile_get_sprite
remap tile_get_x -> layer_tile_get_x
remap tile_get_y -> layer_tile_get_y
#end