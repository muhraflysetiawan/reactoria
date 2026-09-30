shader_type canvas_item;

// Ratio bar yang terisi (0.0 = kosong, 1.0 = penuh)
uniform float fill_amount : hint_range(0.0, 1.0) = 1.0;

// Flash efek saat terkena damage (0.0 = normal, 1.0 = putih penuh)
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Tint warna (bisa digunakan untuk Ghost Bar berwarna kuning/oranye)
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Efek denyut saat darah kritis
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	
	// Hitung batas kanan potongan sesuai sudut jajaran genjang
	// Kemiringan 17px pada tinggi 74px, lebar aktif 794px dalam kanvas 812px
	float max_u = (fill_amount * 794.0 + 17.0 * UV.y) / 812.0;
	
	// Anti-aliasing yang valid di semua GPU/driver (DirectX 12, Vulkan, OpenGL) dengan edge0 < edge1
	float edge_width = 2.0 / 812.0;
	float alpha_mask = 1.0 - smoothstep(max_u - edge_width, max_u, UV.x);
	
	// Jika fill_amount sangat kecil/nol, pastikan transparan total
	if (fill_amount <= 0.001) {
		alpha_mask = 0.0;
	}
	
	tex.a *= alpha_mask;
	
	// Terapkan pewarnaan tint
	tex.rgb *= tint_color.rgb;
	
	// Efek flash putih/merah terang saat hit
	tex.rgb = mix(tex.rgb, flash_color.rgb, clamp(flash_amount, 0.0, 1.0));
	
	// Efek denyut bahaya saat HP rendah
	if (pulse_intensity > 0.0) {
		float pulse = (sin(TIME * 8.0) * 0.5 + 0.5) * pulse_intensity * 0.45;
		tex.rgb = mix(tex.rgb, vec3(1.0, 0.25, 0.25), pulse);
	}
	
	COLOR = tex;
}
