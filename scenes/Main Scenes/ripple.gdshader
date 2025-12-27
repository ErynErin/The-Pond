shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float time = -1.0;       // Starts at -1
uniform vec2 center = vec2(-0.5); // Ripple origin
uniform float strength = 0.05;   // Intensity of the distortion
uniform float frequency = 100.0; // Higher = "A lot" of ripples
uniform float speed = 10.0;      // How fast they move
uniform float duration = 1.2;    // Should match your GDScript tween duration

void fragment() {
	vec2 uv = SCREEN_UV;

	if (time >= 0.0) {
		float dist = distance(uv, center);
		float ripple = sin(dist * 150.0 - time * 15.0);
		float time_decay = clamp(1.0 - (time / 1.2), 0.0, 1.0);
		float spatial_fade = smoothstep(0.23, 0.0, dist);
		uv += normalize(uv - center) * ripple * strength * spatial_fade * time_decay;
	}

	COLOR = texture(SCREEN_TEXTURE, uv);
}