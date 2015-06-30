//------------------------------------------- Defines -------------------------------------------

#define Pi 3.14159265
#define MAX_LIGHTS 5
//------------------------------------- Top Level Variables -------------------------------------

// Top level variables can and have to be set at runtime
float4 DiffuseColor;
float3 PointLight;

//[E1] Multiple Lights
float3 LightPositions[MAX_LIGHTS];
float4 LightColors[MAX_LIGHTS];

//[E2] Spotlight
float3 SpotLightDirection;
float OuterAngle;
float InnerAngle;

float3 Eye;
// Matrices for 3D perspective projection 
float4x4 View, Projection, World, Size, tempWorld;

//---------------------------------- Input / Output structures ----------------------------------

// Each member of the struct has to be given a "semantic", to indicate what kind of data should go in
// here and how it should be treated. Read more about the POSITION0 and the many other semantics in 
// the MSDN library
struct VertexShaderInput
{
	float4 Position3D : POSITION0;
	float4 Normal : NORMAL0;
};

// The output of the vertex shader. After being passed through the interpolator/rasterizer it is also 
// the input of the pixel shader. 
// Note 1: The values that you pass into this struct in the vertex shader are not the same as what 
// you get as input for the pixel shader. A vertex shader has a single vertex as input, the pixel 
// shader has 3 vertices as input, and lets you determine the color of each pixel in the triangle 
// defined by these three vertices. Therefor, all the values in the struct that you get as input for 
// the pixel shaders have been linearly interpolated between there three vertices!
// Note 2: You cannot use the data with the POSITION0 semantic in the pixel shader.
struct VertexShaderOutput
{
	float4 Position2D : POSITION0;
	float4 Position2DPixel : TEXCOORD1;
	float4 Normal : TEXCOORD2;
	float4 Position3D : TEXCOORD3;
};

//------------------------------------------ Functions ------------------------------------------
float4 MultiLambertianStyle(VertexShaderOutput input)

{
	float4 tempcolor = float4(0, 0, 0, 0);

		// calculating the different light sources apart, and adding them up
	for (int x = 0; x < 5; x++)
	{
		float3 normLightVector = normalize(LightPositions[x] - input.Position3D.xyz);
		float3 worldNormals = normalize(mul((float3)input.Normal, (float3x3)World));
		float a = clamp(dot(normLightVector, worldNormals), 0, 1);
		float4 color = LightColors[x] * a;
		tempcolor = color + tempcolor;
	}
	return tempcolor;
}

float4 Spotlight(VertexShaderOutput input)

{
	//spotlight, lightintensity calculations
	float3 normLightVector = normalize(PointLight - input.Position3D.xyz);
	float3 worldNormals = normalize(mul((float3)input.Normal, (float3x3)World));
	float a = clamp(dot(normLightVector, worldNormals), 0, 1);

	// color calculation
	float4 color = DiffuseColor * a;

	//calculates the value to multiplicate the color with to make the color darken from the edge of the inner to the edge of the outer circle
	color *= 1 - ((max(acos(max(dot(-normLightVector, SpotLightDirection), 0.0f)) / Pi * 180, InnerAngle) - InnerAngle) / max((OuterAngle - InnerAngle), 0.000001));
	return color;
}

float4 LambertianStyleCell(VertexShaderOutput input)
{
	// the calculation of the lightintensity
	float3 normLightVector = normalize(LightPositions[1] - input.Position3D.xyz);
	float3 worldNormals = normalize(mul(input.Normal, World));
	float a = clamp(dot(normLightVector, worldNormals), 0, 1);

	// changing the intensity to with if statements to seperate intensity into four groups for cell shading
	if (a < .25)
		a = 0;
	else if (a < .50)
		a = .25;
	else if (a < .75)
		a = .50;
	else if (a < .1)
		a = .75;
	// an easy way to reuse old resources
	float4 color = LightColors[1] * a;
	return color;
}
//---------------------------------------- Technique: Simple ----------------------------------------

VertexShaderOutput SimpleVertexShader(VertexShaderInput input)
{
	// Allocate an empty output struct
	VertexShaderOutput output = (VertexShaderOutput)0;

	// Do the matrix multiplications for perspective projection and the world transform
	float4 worldPosition = mul(input.Position3D, World);

	//aanpassen van wereldgrootte
	float4 resized = mul(worldPosition, Size);
	float4 viewPosition = mul(resized, View);
	output.Position2D = mul(viewPosition, Projection);
	output.Normal = mul(input.Normal, tempWorld);

	// The calculation of the positions of the pixels in worldspace
	output.Position3D = mul(Size, worldPosition);
	return output;
}

// the several pixelshaders, as all our computations are done within the pixelshader, this makes it easier to switch scenes.
float4 SimplePixelShader(VertexShaderOutput input) : COLOR0
{
	float4 color;
	color = MultiLambertianStyle(input);
	return color;
}

float4 SpotlightPixelShader(VertexShaderOutput input) : COLOR0
{
	float4 color;
	color = Spotlight(input);
	return color;
}

float4 CellPixelShader(VertexShaderOutput input) : COLOR0
{
	float4 color;
	color = LambertianStyleCell(input);
	return color;
}

// the several techniques as to make it easier to switch between different scenes
technique Simple
{
	pass Pass0
	{
		VertexShader = compile vs_2_0 SimpleVertexShader();
		PixelShader = compile ps_2_0 SimplePixelShader();
	}
}
technique Cellshading
{
	pass Pass0
	{
		VertexShader = compile vs_2_0 SimpleVertexShader();
		PixelShader = compile ps_2_0 CellPixelShader();
	}

}
technique SpotLight
{
	pass Pass0
	{
		VertexShader = compile vs_2_0 SimpleVertexShader();
		PixelShader = compile ps_2_0 SpotlightPixelShader();
	}
}