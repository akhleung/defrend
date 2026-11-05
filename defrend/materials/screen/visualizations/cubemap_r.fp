#version 420 core

in vec2 var_texcoord0;

uniform samplerCube input_sampler;

out vec4 frag_output;

void main() {
    vec3 dir = vec3(0.0);
    
    // Scale UV to fit a 4x3 grid map layout
    float x = var_texcoord0.x * 4.0;
    float y = var_texcoord0.y * 3.0;
    
    // Determine which grid cell the pixel is in
    int cell_x = int(floor(x));
    int cell_y = int(floor(y));
    
    // Local coordinates inside the active cell, mapped from -1.0 to 1.0
    float local_x = (x - float(cell_x)) * 2.0 - 1.0;
    float local_y = (y - float(cell_y)) * 2.0 - 1.0;

    bool valid_cell = true;

    // Row 2 (Middle row contains -X, +Z, +X, -Z)
    if (cell_y == 1) {
        if (cell_x == 0)      dir = vec3(-1.0,  local_y,  local_x); // -X (Left)
        else if (cell_x == 1) dir = vec3( local_x,  local_y,  1.0); // +Z (Front)
        else if (cell_x == 2) dir = vec3( 1.0,  local_y, -local_x); // +X (Right)
        else if (cell_x == 3) dir = vec3(-local_x,  local_y, -1.0); // -Z (Back)
    }
    // Row 3 (Top row contains +Y)
    else if (cell_y == 2 && cell_x == 1) {
        dir = vec3(local_x, 1.0, -local_y); // +Y (Top)
    }
    // Row 1 (Bottom row contains -Y)
    else if (cell_y == 0 && cell_x == 1) {
        dir = vec3(local_x, -1.0, local_y); // -Y (Bottom)
    } 
    else {
        valid_cell = false; // Dead space in the 4x3 cross template
    }

    if (valid_cell) {
        // Sample the cubemap using the calculated 3D direction vector; copy the r component into all channels
        frag_output = vec4(vec3(texture(input_sampler, normalize(dir)).r), 1.0); 
    } else {
        frag_output = vec4(0.0, 0.0, 0.0, 1.0); // Render empty background spaces black
    }
}
