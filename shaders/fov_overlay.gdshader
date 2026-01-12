shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled;

uniform vec3 player_pos;
uniform vec3 player_forward;
uniform float fov_radius;
uniform float fov_angle; // 弧度
uniform float darken_amount : hint_range(0.0, 1.0) = 0.3;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

void vertex() {
	// 使 Quad 覆盖整个屏幕
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	// 获取屏幕颜色
	vec3 screen_color = texture(screen_texture, SCREEN_UV).rgb;
	
	// 获取深度并重建世界坐标
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	vec4 world_pos = INV_VIEW_MATRIX * vec4(view_pos.xyz, 1.0);
	
	// 计算到玩家的向量
	vec3 to_pixel = world_pos.xyz - player_pos;
	float dist = length(to_pixel);
	
	// 默认视野外（变暗）
	vec3 final_color = screen_color * darken_amount;
	
	// 只有在非背景区域才计算视野
	if (depth < 1.0) {
		if (dist < 0.5) {
			// 玩家脚下总是可见
			final_color = screen_color;
		} else {
			vec3 to_pixel_flat = normalize(vec3(to_pixel.x, 0.0, to_pixel.z));
			vec3 forward_flat = normalize(vec3(player_forward.x, 0.0, player_forward.z));
			
			float dot_prod = clamp(dot(to_pixel_flat, forward_flat), -1.0, 1.0);
			float angle = acos(dot_prod);
			
			if (dist <= fov_radius && angle <= fov_angle * 0.5) {
				final_color = screen_color;
			}
		}
	}
	
	ALBEDO = final_color;
}
