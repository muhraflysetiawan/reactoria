shader_type canvas_item;

// Size of the control in pixels (must match the button slot size)
uniform vec2 rect_size = vec2(280.0, 56.0);

// === Colors ===
uniform vec4 bg_color : source_color = vec4(0.10, 0.10, 0.12, 0.82);
uniform vec4 border_color : source_color = vec4(0.55, 0.50, 0.40, 0.85);
uniform vec4 accent_color : source_color = vec4(0.40, 0.72, 0.65, 1.0);

// === Tuning ===
uniform float border_width : hint_range(1.0, 5.0) = 2.0;
uniform float ornament_size : hint_range(2.0, 12.0) = 6.0;

// === State (animated from GDScript) ===
uniform float hover : hint_range(0.0, 1.0) = 0.0;
uniform float highlighted : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 px = UV * rect_size;

	// ── Edge distances ──
	float l = px.x;
	float r = rect_size.x - px.x;
	float t = px.y;
	float b = rect_size.y - px.y;
	float edge = min(min(l, r), min(t, b));

	float active = max(highlighted, hover);
	float inside = smoothstep(0.0, 1.0, edge);

	// ── Background fill with subtle vertical gradient ──
	vec4 bg = mix(
		bg_color,
		vec4(mix(bg_color.rgb, accent_color.rgb, 0.40),
		     min(bg_color.a + 0.08, 1.0)),
		active
	);
	bg.rgb *= 1.0 - UV.y * 0.12;
	vec4 color = bg * inside;

	// ── Border line ──
	float bm = smoothstep(border_width + 1.0, border_width, edge) * inside;
	vec4 bc = mix(border_color, accent_color, active * 0.70);
	color = mix(color, vec4(bc.rgb, 1.0), bm * bc.a);

	// ── Corner diamond ornaments ──
	float od = ornament_size * 2.5;                        // offset from corner
	vec4 oc = mix(border_color * 1.2, accent_color * 1.3, active * 0.8);

	// float d1 = abs(px.x - od)                + abs(px.y - od);
	// float d2 = abs(px.x - rect_size.x + od)  + abs(px.y - od);
	// float d3 = abs(px.x - od)                + abs(px.y - rect_size.y + od);
	// float d4 = abs(px.x - rect_size.x + od)  + abs(px.y - rect_size.y + od);
	// float dm = min(min(d1, d2), min(d3, d4));
	// float diamond = (1.0 - smoothstep(ornament_size - 0.5, ornament_size + 0.5, dm)) * inside;
	// color = mix(color, vec4(oc.rgb, 1.0), diamond);

	// ── Horizontal accent lines (between corner ornaments) ──
	float ly = border_width + 4.0;
	float hl = max(
		smoothstep(1.0, 0.0, abs(px.y - ly)),
		smoothstep(1.0, 0.0, abs(px.y - rect_size.y + ly))
	);
	float xf = smoothstep(od + ornament_size, od + ornament_size + 8.0, px.x)
	          * smoothstep(od + ornament_size, od + ornament_size + 8.0, rect_size.x - px.x);
	hl *= xf * inside;
	color.rgb += bc.rgb * hl * 0.40;

	// ── Center tick marks on each border edge ──
	float tick = 4.0;
	float cx = rect_size.x * 0.5;
	float cy = rect_size.y * 0.5;
	float tm = 0.0;
	tm += smoothstep(1.0, 0.0, abs(px.y - 0.5))
	    * smoothstep(tick + 0.5, tick - 0.5, abs(px.x - cx));
	tm += smoothstep(1.0, 0.0, abs(px.y - rect_size.y + 0.5))
	    * smoothstep(tick + 0.5, tick - 0.5, abs(px.x - cx));
	tm += smoothstep(1.0, 0.0, abs(px.x - 0.5))
	    * smoothstep(tick + 0.5, tick - 0.5, abs(px.y - cy));
	tm += smoothstep(1.0, 0.0, abs(px.x - rect_size.x + 0.5))
	    * smoothstep(tick + 0.5, tick - 0.5, abs(px.y - cy));
	color.rgb = mix(color.rgb, oc.rgb, min(tm, 1.0) * inside * 0.65);

	// ── Inner edge glow ──
	float glow = (1.0 - smoothstep(border_width, 22.0, edge)) * inside;
	color.rgb += accent_color.rgb * glow * (0.06 + hover * 0.18 + highlighted * 0.10);

	// ── Subtle breathing pulse on highlighted button ──
	float pulse = sin(TIME * 2.0) * 0.5 + 0.5;
	color.rgb += accent_color.rgb * highlighted * pulse * 0.03;

	// ── Subtle scanline texture ──
	float pattern = step(0.5, fract(px.y / 3.0)) * 0.02;
	color.rgb -= vec3(pattern) * inside;

	// ── Top highlight line ──
	float top_hl = smoothstep(2.0, 0.0, abs(px.y - border_width - 1.5)) * inside;
	top_hl *= step(border_width + 2.0, px.x) * step(border_width + 2.0, rect_size.x - px.x);
	color.rgb += vec3(1.0) * top_hl * 0.05;

	color.a *= inside;
	COLOR = color;
}
