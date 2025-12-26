shader_type canvas_item;

uniform vec4 color : source_color;
uniform float brightness : hint_range(1.0, 3.0) = 1.0;
uniform sampler2D fast_noise : repeat_enable;
uniform sampler2D screen_content : hint_screen_texture;
uniform vec2 speed = vec2(0.03, 0.07);
uniform float wave_strength = 2;

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 uv = UV + speed * TIME;
	vec2 noise = texture(fast_noise, uv).rg;
	COLOR = vec4(color.r, color.g, color.b, 0.01) + vec4(noise.x, noise.y,0.9,0.6);
	COLOR *= texture(screen_content, SCREEN_UV + noise * (wave_strength /20.0));

}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
