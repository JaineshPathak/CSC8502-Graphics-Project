#version 430

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
in vec2 texCoord;
in vec3 normal;
in vec4 tangent;
in vec4 jointWeights;
in ivec4 jointIndices;

uniform mat4 joints[128];

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
	mat3 normalMatrix = transpose(inverse(mat3(modelMatrix)));

	vec3 wNormal = normalize(normalMatrix * normalize(normal));
	vec3 wTangent = normalize(normalMatrix * normalize(tangent.xyz));

	OUT.texCoord = texCoord;
	
	OUT.normal = wNormal;
	OUT.tangent = wTangent;
	OUT.binormal = cross(wTangent, wNormal) * tangent.w;



	vec4 localPos = vec4(position, 1.0f);
	vec4 skelPos = vec4(0, 0, 0, 0);

	for(int i = 0; i < 4; ++i)
	{
		int jointIndex = jointIndices[i];
		float jointWeight = jointWeights[i];

		skelPos += joints[jointIndex] * localPos * jointWeight;
	}
	mat4 mvp = projMatrix * viewMatrix * modelMatrix;
	gl_Position = mvp * vec4(skelPos.xyz, 1.0);



	vec4 worldPos = (modelMatrix * vec4(position, 1.0));
	vec4 posRelativeToCam = viewMatrix * worldPos;
	OUT.worldPos = worldPos.xyz;

	bool fogEnabled = bool(envData.fogData.x);
	if(fogEnabled)
	{
		float fogDensity = envData.fogData.y;
		float fogGradient = envData.fogData.z;

		float distance = length(posRelativeToCam.xyz);
		OUT.visibility = exp(-pow((distance * fogDensity), fogGradient));
		OUT.visibility = clamp(OUT.visibility, 0.0, 1.0);
	}

	OUT.fragPosLightSpace = lightSpaceMatrix * vec4(OUT.worldPos, 1.0);
}