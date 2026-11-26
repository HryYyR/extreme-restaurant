extends RefCounted

# One clock drives the street, interior and character lighting. Colors are specified
# in display space to match the game's painted materials in the Compatibility renderer.
const HOURS = [0.0, 4.8, 6.4, 8.0, 9.0, 12.5, 16.5, 18.5, 21.0, 24.0]
const WASH = [Color("1e2b50", .63), Color("2c3962", .57), Color("a5738f", .34),
	Color("f5b68f", .16), Color("f7b179", .13), Color("fff1cd", .025), Color("f1bd86", .09),
	Color("d88991", .20), Color("243856", .53), Color("1e2b50", .63)]
const KEY = [Color("a1b8e3"), Color("a5b4dc"), Color("e5a78d"), Color("ffd090"),
	Color("ffd19a"), Color("fff2d1"), Color("ffd69c"), Color("ffb487"), Color("b5c9f3"), Color("a1b8e3")]

static func sample(hour: float, colors: Array) -> Color:
	for i in range(1, HOURS.size()):
		if hour <= HOURS[i]:
			return colors[i - 1].lerp(colors[i], smoothstep(HOURS[i - 1], HOURS[i], hour))
	return colors.back()

static func lamplight(hour: float) -> float:
	if hour < 9.0: return 1.0 - smoothstep(5.25, 8.55, hour)
	return smoothstep(16.5, 21.0, hour)

static func cast_direction(hour: float) -> Vector2:
	var evening = lamplight(hour)
	var sweep = 1.0 - smoothstep(0.0, 6.0, hour) if hour < 9.0 else clampf((hour - 9.0) / 11.0, 0.0, 1.0)
	return Vector2(lerpf(1.05, -1.35, sweep), 0.48).lerp(Vector2(.22, .23), evening * .86)

static func radial_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0, .22, .55, .82, 1])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1,1,1,.89), Color(1,1,1,.43), Color(1,1,1,.095), Color(1,1,1,0)])
	var texture := GradientTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(.5, .5)
	texture.fill_to = Vector2(1, .5)
	texture.gradient = gradient
	return texture
