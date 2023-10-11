uniform highp float time;

// vertex shader
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    vertex_position.y += sin(-time * 8.0 + vertex_position.x/32.0) * 2.0;
    return transform_projection * vertex_position;
}

// pixel shader (does nothing so far)
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
    vec4 texcolor = Texel(tex, texture_coords);
    return texcolor * color;
}