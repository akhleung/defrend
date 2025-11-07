#version 420 core

#ifdef EDITOR
layout(location = 0) out vec4 frag_color;
#endif

void main() {
    #ifdef EDITOR
    frag_color = vec4(0, 0, 0, 0.5);
    #endif
}
