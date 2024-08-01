#version 430

layout (points) in;
layout (triangle_strip, max_vertices = 12) out;

layout(location = 1) uniform sampler2D diffuseWindTex;
layout(location = 2) uniform sampler2D diffuseDensityTex;
uniform float u_Time;

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

const float PI = 3.141592653589793;

float grass_size;
const float c_min_size = 1.5f;

const float grassWidthMin = 0.5;
const float grassWidthMax = 0.6;
const float grassHeightMin = 0.5;
const float grassHeightMax = 0.6;
const float terrainScale = 8160.0;

//This should be same as from Vertex Shader
in Vertex
{
    vec3 position;
    vec4 colour;
	vec2 texCoord;
	vec3 normal;
    vec3 worldPos;
	mat4 instanceModelMat;
} IN[];

//This should same for Fragment Shader
out Vertex
{
    vec3 position;
    vec4 colour;
    vec2 texCoord;
    vec3 normal;
    vec3 worldPos;
    float visibility;
    vec2 splatTexCoord;
    flat int discardGrass;
} OUT;

float random(vec2 st);
float randomRange(float min, float max, vec2 seed);
mat4 rotationX(in float angle);
mat4 rotationY(in float angle);
mat4 rotationZ(in float angle);

bool isColorClose(vec3 colorCurrent, vec3 colorTarget, float threshold)
{
    vec3 diff = abs(colorCurrent - colorTarget);
    float distance = length(diff);
    return distance < threshold;
}

void CreateQuad(in vec4 basePosition, in mat4 crossModel)
{
    OUT.discardGrass = 0;

    mat4 modelRandY = rotationY(random(basePosition.xz) * PI);
       
    float u = (IN[0].worldPos.x + terrainScale * 0.5) / terrainScale;
    float v = 1 - (IN[0].worldPos.z + terrainScale * 0.5) / terrainScale;
    u = clamp(u, 0.01, 0.99);
    v = clamp(v, 0.01, 0.99);
    vec2 densityTexCoord = vec2(u, v);
    float density = texture(diffuseDensityTex, densityTexCoord).r;
    if( (1 - density) >= 1) OUT.discardGrass = 1;

    if(OUT.discardGrass == 0) 
    {
        float R = randomRange(0.0, 1.0, basePosition.xz);

        float grassWidth = grassWidthMin + R * (grassWidthMax - grassWidthMin);
        float grassHeight = (grassHeightMin + R * (grassHeightMax - grassHeightMin)) * density;
    
        vec4 vertexPosition[4];
        /*vertexPosition[0] = vec4(-0.2, 0.0, 0.0, 0.0); 	// down left
        vertexPosition[1] = vec4( 0.2, 0.0, 0.0, 0.0);  // down right
        vertexPosition[2] = vec4(-0.2, 0.2, 0.0, 0.0);	// up left
        vertexPosition[3] = vec4( 0.2, 0.2, 0.0, 0.0);  // up right*/

        vertexPosition[0] = basePosition - vec4(0.5 * grassWidth, 0.0, 0.0, 0.0); 	        // down left
        vertexPosition[1] = basePosition + vec4(0.5 * grassWidth, 0.0, 0.0, 0.0);           // down right
        vertexPosition[2] = basePosition + vec4(0.5 * grassWidth, grassHeight, 0.0, 0.0);	// up left
        vertexPosition[3] = basePosition - vec4(0.5 * grassWidth, grassHeight, 0.0, 0.0);   // up right

        vec2 textCoords[4];
        textCoords[0] = vec2(0.0, 0.0); // down left
        textCoords[1] = vec2(1.0, 0.0); // down right
        textCoords[2] = vec2(0.0, 1.0); // up left
        textCoords[3] = vec2(1.0, 1.0); // up right

        vec2 windDirection = vec2(1.0, 1.0);
	    float windStrength = 0.15;

	    vec2 uv = basePosition.xz + windDirection * windStrength * u_Time;
	    uv.x = mod(uv.x, 1.0);
	    uv.y = mod(uv.y, 1.0);

	    vec4 wind = texture(diffuseWindTex, uv);

        // we calculate the matrix that allows the quad to be tilted according to the wind direction and force
	    mat4 modelWind = (rotationX(wind.x * PI * 0.25 - PI * 0.25) * rotationZ(wind.y * PI * 0.25 - PI * 0.25));

    //    vec3 normal = normalize(cross(vertexPosition[1].xyz - vertexPosition[0].xyz, vertexPosition[2].xyz - vertexPosition[0].xyz));
    //    mat3 normalMat = transpose(inverse(mat3(IN[0].instanceMat)));
    //    OUT.normal = normalize(normalMat * normalize(normal));

        mat4 modelWindApply = mat4(1.0);    
        /*if (isColorClose(splatColor.rgb, vec3(1.0, 0.0, 0.0), 1.25))
        {
            for(int i = 0; i < 4; i++) 
            {
                //TODO: FIX THIS
                //float grassAmount = texture(diffuseSplatmapTex, textCoords[i] / 16.0).r;
                if(grassAmount < 0.2f)
                    grass_size = 1.5f;
                else
                    grass_size = 0.0f;

                if (i == 2) 
			        modelWindApply = modelWind;

                //vertexPosition[i] *= grass_size;	         
                gl_Position = projMatrix * viewMatrix * IN[0].instanceModelMat * (gl_in[0].gl_Position + modelWindApply * crossModel * vertexPosition[i] * grass_size);
                OUT.texCoord = textCoords[i];

                //grass_size = mix(0.0f, 1.5f, grassAmount);
                //gl_Position = projMatrix * viewMatrix * IN[0].instanceMat * (basePosition + crossModel * vertexPosition[i] * grass_size);
	            EmitVertex();
            }    
        }*/

        for(int i = 0; i < 4; i++)
        {
            if (i == 2) modelWindApply = modelWind;

            OUT.texCoord = textCoords[i];
            gl_Position = projMatrix * viewMatrix * IN[0].instanceModelMat * (crossModel * modelWindApply * vertexPosition[i]);
            EmitVertex();
        }
        EndPrimitive();
    }
}

void CreateGrass()
{
    mat4 model0, model45, modelm45;
	model0 = mat4(1.0f);
	model45 = rotationY(radians(45.0f));
	modelm45 = rotationY(-radians(45.0f));
 
	CreateQuad(gl_in[0].gl_Position, model0);
	CreateQuad(gl_in[0].gl_Position, model45);
	CreateQuad(gl_in[0].gl_Position, modelm45);
}

void main()
{
    OUT.position = IN[0].position;
    OUT.colour = IN[0].colour;
    OUT.normal = IN[0].normal; 
    OUT.worldPos = IN[0].worldPos;
    
    //float u = mod(IN[0].worldPos.x, terrainScale) / terrainScale;
    //float v = mod(IN[0].worldPos.z, terrainScale) / terrainScale;
    //OUT.splatTexCoord = vec2(u, v);

    float u = (IN[0].worldPos.x + terrainScale * 0.5) / terrainScale;
    float v = 1 - (IN[0].worldPos.z + terrainScale * 0.5) / terrainScale;
    u = clamp(u, 0.01, 0.99);
    v = clamp(v, 0.01, 0.99);
    OUT.splatTexCoord = vec2(u, v);

    //OUT.splatTexCoord = (IN[0].worldPos.xz + terrainScale * 0.5) / terrainScale;
    //OUT.splatTexCoord = (IN[0].worldPos.xz / textureSize(diffuseSplatmapTex, 0)) / 16.0f;
    //OUT.splatTexCoord = ((IN[0].instanceModelMat * vec4(IN[0].position, 1.0)).xz / textureSize(diffuseSplatmapTex, 0)) / 16.0f;
    //OUT.splatTexCoord = (inverse(IN[0].instanceModelMat) * vec4(IN[0].worldPos, 1.0)).xz / textureSize(diffuseSplatmapTex, 0) / 16.0f;

    bool fogEnabled = bool(envData.fogData.x);
    if(fogEnabled)
	{
		float fogDensity = envData.fogData.y;
		float fogGradient = envData.fogData.z;
        vec4 posRelativeToCam = (viewMatrix * vec4(IN[0].worldPos, 1.0));

		float distance = length(posRelativeToCam.xyz);
		OUT.visibility = exp(-pow((distance * fogDensity), fogGradient));
		OUT.visibility = clamp(OUT.visibility, 0.0, 1.0);
	}

    grass_size = random(gl_in[0].gl_Position.xz) * (1.0f - c_min_size) + c_min_size;

    CreateGrass();
}


//------------------------------------------------------------------------------------------------------------------------
//UTILITIES
float random(vec2 st) 
{
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float randomRange(float min, float max, vec2 seed) 
{
    return mix(min, max, random(seed));
}

mat4 rotationX(in float angle) 
{
	return mat4(1.0,		0,			0,			0,
			 	0, 	cos(angle),	-sin(angle),		0,
				0, 	sin(angle),	 cos(angle),		0,
				0, 			0,			  0, 		1);
}
 
mat4 rotationY(in float angle)
{
	return mat4(cos(angle),		0,		sin(angle),	0,
			 			0,		1.0,			 0,	0,
				-sin(angle),	0,		cos(angle),	0,
						0, 		0,				0,	1);
}
 
mat4 rotationZ(in float angle) 
{
	return mat4(cos(angle),		-sin(angle),	0,	0,
			 	sin(angle),		cos(angle),		0,	0,
						0,				0,		1,	0,
						0,				0,		0,	1);
}
//------------------------------------------------------------------------------------------------------------------------