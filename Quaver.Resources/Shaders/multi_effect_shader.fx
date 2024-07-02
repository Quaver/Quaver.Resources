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

float2 p_rendertarget_sizetouv;
float2 p_rendertarget_uvtosize;

float p_greyscale_strength;
float2 p_chromeabber_offset_r;
float2 p_chromeabber_offset_g;
float2 p_chromeabber_offset_b;
float p_mosaic_strength;

float4 GetColor(float2 coords : TEXCOORD0) : COLOR 
{
    if (p_mosaic_strength != 0) {
        float blockSizeX = p_rendertarget_uvtosize.x * (1 - p_mosaic_strength);
        float blockSizeY = p_rendertarget_uvtosize.y * (1 - p_mosaic_strength);
        coords = float2(floor(coords.x * blockSizeX) / blockSizeX, floor(coords.y * blockSizeY) / blockSizeY);
    }
    return tex2D(SpriteTextureSampler, coords);
}

float4 MainPS(VertexShaderOutput input) : COLOR
{
	float4 color = GetColor(input.TextureCoordinates);
	
    color.r = GetColor(input.TextureCoordinates + p_chromeabber_offset_r * p_rendertarget_sizetouv).r;
    color.g = GetColor(input.TextureCoordinates + p_chromeabber_offset_g * p_rendertarget_sizetouv).g;
    color.b = GetColor(input.TextureCoordinates + p_chromeabber_offset_b * p_rendertarget_sizetouv).b;
	
    float4 greyColor;
    greyColor.rgb = (color.r + color.g + color.b) / 3.0f;
    greyColor.a = color.a;

	color = lerp(color, greyColor, p_greyscale_strength);
	
	return color;
}

technique SpriteDrawing
{
	pass P0
	{
		PixelShader = compile PS_SHADERMODEL MainPS();
	}
};