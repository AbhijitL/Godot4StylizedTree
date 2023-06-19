shader_type spatial;
render_mode blend_mix, depth_draw_opaque,cull_disabled;

uniform sampler2D alphaTexture;
uniform vec4 leavesColor : source_color;
uniform float alphaThreshold = 0.1;

uniform float offsetScale : hint_range(0.0001, 1.0, 0.001);

//Fresnel
uniform float fresnelStrength : hint_range(-2.0, 2.0) =  0.5;
uniform float fresnelBlend : hint_range(-1.0,1.0) = 1.0;
uniform vec4 fresnelColor : source_color = vec4(0.58,0.65,0.33,1.0);

//WindShader
global uniform float WindScale;
global uniform float WindSpeed;
global uniform float WindStrength;
global uniform float WindDensity;
uniform bool deactiveGlobalVariation;
uniform float clampTop : hint_range(0.0,1.0) = 1.0;
uniform float clampBottom : hint_range(-1.0, 0.0) = 0.0;



void fragment() {
	
	//Fresnel Effect.
	float rate_col = clamp(COLOR.r,0.0,1.0);
	float fresnel = pow(1.0 - clamp(dot(NORMAL,VIEW),0.0,1.0),3.0);
	float fresnel_rate = clamp(rate_col,0.1,1);
	vec3 albedo = vec3(leavesColor.xyz);
	vec3 fres_col = albedo * (1.0-fresnelStrength);
	fres_col += fresnelColor.rgb * fresnelStrength;
	fres_col *= fresnel;
	fres_col *= fresnel_rate;
	fres_col *= fresnelBlend;
	
	ALBEDO = vec3(leavesColor.xyz);
	ALPHA = texture(alphaTexture,UV).x;
	ALPHA_SCISSOR_THRESHOLD = alphaThreshold;
	EMISSION = fres_col;
}

void vertex(){
	
	vec2 uvOffset = vec2(UV.x * 2.0 - 1.0, -(UV.y * 2.0 - 1.0));
	uvOffset /= 2.0;
	vec4 off = inverse(MODELVIEW_MATRIX) * vec4(uvOffset,1.0,0.0);
	off = vec4(normalize(off.xyz),0.0) * offsetScale;
	
	//Wind
	vec3 world_pos = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	float contribution = 1.0 * (1.0 - float(deactiveGlobalVariation));
	vec3 world_pos_eff = world_pos * contribution;
	float positional_influence = - VERTEX.x + VERTEX.z - world_pos_eff.x + world_pos_eff.z;
	float offset = fract(positional_influence * (1.0/WindScale) + (TIME * WindScale/1000.0));
	offset = min(1.0 - offset, offset);
	offset = (1.0 - offset) * offset * 2.0;
	
	float t = TIME + sin(TIME + offset + cos(TIME + offset * WindStrength * 2.0) * WindStrength);
	float mask = clamp(VERTEX.y * WindDensity,0.0, 1.0) * (clampTop - clampBottom) + clampBottom;
	
	float si = sin(t) / 20.0 * WindStrength * offset;
	float csi = cos(t) / 20.0 * WindStrength * offset;
	
	vec3 wind_offset = vec3(VERTEX.x * si * mask, VERTEX.y * si * mask, VERTEX.z * csi * mask);
	
	VERTEX += off.xyz + wind_offset;
}

