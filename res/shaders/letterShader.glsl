uniform highp float screenWidth;

// vertex shader (does nothing so far)
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    return transform_projection * vertex_position;
}

// pixel shader
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
    vec4 texcolor = Texel(tex, texture_coords);
    if(color.r >= 0.55) { // this is a shitty fix
        texcolor.a *= min(screen_coords.x/100.0, 1.0);
        texcolor.a *= min((screenWidth - screen_coords.x)/100.0, 1.0);
    }
    return texcolor * color;
}