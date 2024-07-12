#if OPENGL
	#define SV_POSITION POSITION
	#define VS_SHADERMODEL vs_3_0
	#define PS_SHADERMODEL ps_3_0
#else
	#define VS_SHADERMODEL vs_5_0
	#define PS_SHADERMODEL ps_5_0
#endif

Texture2D SpriteTexture;
cbuffer textureDimensions : register( b0 )
{
    float2 SizeToUV;
    float2 UVToSize;

    float GreyscaleStrength;
    float2 ChromaticAberrationRedOffset;
    float2 ChromaticAberrationGreenOffset;
    float2 ChromaticAberrationBlueOffset;
    float2 MosaicBlockSize;
}

sampler2D SpriteTextureSampler = sampler_state
{
	Texture = <SpriteTexture>;
};

struct VertexShaderOutput
{
	float4 Position : SV_POSITION;
	float4 Color : COLOR0;
	float2 TextureCoordinates : TEXCOORD0;
};

#define MOSAIC_SAMPLE_SIZE 8

float4 GetColor(float2 coords : TEXCOORD0) : COLOR 
{
    float4 color = tex2D(SpriteTextureSampler, coords);
    if (MosaicBlockSize.x != 0 && MosaicBlockSize.y != 0) {
        float2 blockCoordToUV = MosaicBlockSize * SizeToUV;
        float2 blockCoords = coords / blockCoordToUV;
        coords = float2(floor(blockCoords.x + 0.5f), floor(blockCoords.y + 0.5f)) * blockCoordToUV;
        color.xyzw = 0;
        for (int x = 0; x < MOSAIC_SAMPLE_SIZE; x++) {
            for (int y = 0; y < MOSAIC_SAMPLE_SIZE; y++) {
                color += tex2D(SpriteTextureSampler, coords + float2(x, y) * MosaicBlockSize / MOSAIC_SAMPLE_SIZE * SizeToUV);
            }
        }
        color /= MOSAIC_SAMPLE_SIZE * MOSAIC_SAMPLE_SIZE;
    }
    return color;
}

float4 MainPS(VertexShaderOutput input) : COLOR
{
	float4 color = GetColor(input.TextureCoordinates);
	
    color.r = GetColor(input.TextureCoordinates + ChromaticAberrationRedOffset * SizeToUV).r;
    color.g = GetColor(input.TextureCoordinates + ChromaticAberrationGreenOffset * SizeToUV).g;
    color.b = GetColor(input.TextureCoordinates + ChromaticAberrationBlueOffset * SizeToUV).b;
	
    float4 greyColor;
    greyColor.rgb = (color.r + color.g + color.b) / 3.0f;
    greyColor.a = color.a;

	color = lerp(color, greyColor, GreyscaleStrength);
	
	return color;
}

technique SpriteDrawing
{
	pass P0
	{
		PixelShader = compile PS_SHADERMODEL MainPS();
	}
};