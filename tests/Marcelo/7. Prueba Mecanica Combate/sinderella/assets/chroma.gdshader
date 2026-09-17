shader_type canvas_item;
render_mode unshaded;
// Generated sprite atlas uses a flat magenta key. Source pixels remain intact.
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float magenta = min(tex.r, tex.b) - tex.g;
	float alpha = 1.0 - smoothstep(0.20, 0.48, magenta);
	COLOR.a *= alpha;
}
