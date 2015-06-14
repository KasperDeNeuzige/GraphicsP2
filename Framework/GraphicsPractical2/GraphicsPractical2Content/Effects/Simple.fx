//------------------------------------------- Defines -------------------------------------------

#define Pi 3.14159265

//------------------------------------- Top Level Variables -------------------------------------

// Top level variables can and have to be set at runtime
float4 DiffuseColor : COLOR0;
float ColorStrength;
float3 PointLight[5];

texture Cobblestones;

float3 Eye;

float4 AmbientColor;
float AmbientIntensity;
// Matrices for 3D perspective projection 
float4x4 View, Projection, World;

float4x4 InvTransWorld;

//---------------------------------- Input / Output structures ----------------------------------

// Each member of the struct has to be given a "semantic", to indicate what kind of data should go in
// here and how it should be treated. Read more about the POSITION0 and the many other semantics in 
// the MSDN library
struct VertexShaderInput
{
	float4 Position3D : POSITION0;
	float4 Normal : NORMAL0;
	//float2 TexCoord : TEXCOORD0;
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
	float2 TexCoord : TEXCOORD0;
};

//------------------------------------------ Functions ------------------------------------------

// Implement the Coloring using normals assignment here
float4 NormalColor(VertexShaderOutput input) : TEXCOORD1
{
	input.Normal += float4(1, 1, 1, 0);
	input.Normal = input.Normal / 2;
	input.Normal = normalize(input.Normal);
	return input.Normal;
}

// Implement the Procedural texturing assignment here
float4 ProceduralColor(VertexShaderOutput input)
{
	input.Position3D = NormalColor(input);
	if ((sin(input.Position3D.x) >0 && cos(input.Position3D.y)> 0) || (sin(input.Position3D.x)<0 && cos(input.Position3D.y)<0))
		input.Position3D *= -1;
	return input.Position3D;
}

//---------------------------------------- Technique: Simple ----------------------------------------

VertexShaderOutput SimpleVertexShader(VertexShaderInput input)
{
	// Allocate an empty output struct
	VertexShaderOutput output = (VertexShaderOutput)0;

	// Do the matrix multiplications for perspective projection and the world transform
	float4 worldPosition = mul(input.Position3D, World);
    float4 viewPosition  = mul(worldPosition, View);
	output.Position2D    = mul(viewPosition, Projection);
	output.Position3D	= input.Position3D;
	
	//output.TexCoord = input.TexCoord;
	// kleur opdracht
	output.Normal = mul(input.Normal, InvTransWorld);
	
	// checkerboard opdracht
	output.Position3D	 = worldPosition;

	return output;
}
sampler TextureSampler = sampler_state
{
	Texture = <Cobblestones>;
	MinFilter = Linear;
	MagFilter = Linear;
	AddressU = Wrap;
	AddressV = Wrap;
};
float4 SimplePixelShader(VertexShaderOutput input) : COLOR0
{
	//float4 color = NormalColor(input);
	//float4 color = ProceduralColor(input);
	float3 LichtVector = normalize(PointLight - input.Position3D);

	float3 Normals = normalize(mul(input.Normal, (float3x3)World));

	// ambient lighting
	float4 color = mul(dot(Normals, LichtVector), DiffuseColor);
	if (color.x < 0)
		color.x = 0;
	if (color.y < 0)
		color.y = 0;
	if (color.z < 0)
		color.z = 0;
	color += mul(AmbientColor, AmbientIntensity);
	
	
	//color = tex2D(TextureSampler, float2(input.TexCoord.x, input.TexCoord.y));
	return color;
}

float4 SimplePixelShader(VertexShaderOutput input) : COLOR0
{
	//The Ambient Shading
	float4 color = AmbientIntensity*AmbientColor;
	for (int a = 0; a < MAX_LIGHTS; a++)
	{
		color = color + LambertianPhong(input, a);
	}
	return color;
}

	float4 LambertianPhong(VertexShaderOutput input, int i)

	{
		float3 normLightVector = normalize(PointLight - input.Position3D.xyz);
			float3 worldNormals = normalize(mul((float3)input.Normal, (float3x3)InvTransWorld));
			float a = clamp(dot(normLightVector, worldNormals), 0, 1);
		float4 color = DiffuseColor * a;
			//the phong shading
			float3 eyeNorm = normalize(CameraEye - input.Position3D.xyz);
			float3 reflectVector = 2 * dot(normLightVector, worldNormals)*worldNormals - normLightVector;
			float b = clamp(dot(eyeNorm, reflectVector), 0, 1);
		b = mul(SpecularIntensity, pow(b, SpecularPower));
		color = color + (SpecularColor * b);
		return color;
	}

technique Simple
{
	pass Pass0
	{
		VertexShader = compile vs_2_0 SimpleVertexShader();
		PixelShader  = compile ps_2_0 SimplePixelShader();
	}
}