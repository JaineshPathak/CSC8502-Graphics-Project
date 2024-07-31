#version 430 core

layout(std140, binding = 0) uniform Matrices
{
	mat4 projMatrix;
	mat4 viewMatrix;
};

struct EnvironmentData
{
	vec4 fogData;
	vec4 fogColor;
};

layout(std140, binding = 3) uniform u_EnvironmentData
{
	EnvironmentData envData;
};

uniform mat4 modelMatrix;
uniform mat4 shadowMatrix;
uniform mat4 lightSpaceMatrix;

in vec3 position;
in vec4 colour;
in vec3 normal;
in vec4 tangent;
in vec2 texCoord;

out Vertex
{
	vec4 colour;
	vec2 texCoord;
	vec3 normal;
	vec3 tangent;
	vec3 binormal;
	vec3 worldPos;
	vec4 shadowProj;
	vec4 fragPosLightSpace;

	float visibility;
} OUT;

const float density = 0.00015f;
const float gradient = 1.5f;

void main(void)
{

	vec4 worldPos = (modelMatrix * vec4(position, 1));
	mat3 normalMatrix = transpose(inverse(mat3(modelMatrix)));
	vec3 wNormal = normalize(normalMatrix * normalize(normal));
	vec3 wTangent = normalize(normalMatrix * normalize(tangent.xyz));
	vec3 wBiTangent = cross(wTangent, wNormal) * tangent.w;

	OUT.colour = colour;
	OUT.texCoord = texCoord;
	OUT.normal = wNormal;
	OUT.tangent = wTangent;
	OUT.binormal = cross(wTangent, wNormal) * tangent.w;
	OUT.worldPos = worldPos.xyz;

	gl_Position = (projMatrix * viewMatrix) * worldPos;

	bool fogEnabled = bool(envData.fogData.x);
	if(fogEnabled)
	{
		vec4 posRelativeToCam = viewMatrix * worldPos;
		float fogDensity = envData.fogData.y;
		float fogGradient = envData.fogData.z;

		float distance = length(posRelativeToCam.xyz);
		OUT.visibility = exp(-pow((distance * fogDensity), fogGradient));
		OUT.visibility = clamp(OUT.visibility, 0.0, 1.0);
	}

	OUT.fragPosLightSpace = lightSpaceMatrix * vec4(OUT.worldPos, 1.0);
}