components {
  id: "rotate"
  component: "/example/main/rotate.script"
  properties {
    id: "reverse"
    value: "true"
    type: PROPERTY_TYPE_BOOLEAN
  }
}
embedded_components {
  id: "model"
  type: "model"
  data: "mesh: \"/builtins/assets/gltf/cube.gltf\"\n"
  "name: \"{{NAME}}\"\n"
  "materials {\n"
  "  name: \"default\"\n"
  "  material: \"/defrend/materials/geometry/decal/decal.material\"\n"
  "  textures {\n"
  "    sampler: \"albedo_map\"\n"
  "    texture: \"/builtins/assets/images/logo/logo_256.png\"\n"
  "  }\n"
  "  textures {\n"
  "    sampler: \"normal_map\"\n"
  "    texture: \"/defrend/assets/textures/flat.png\"\n"
  "  }\n"
  "  textures {\n"
  "    sampler: \"spec_glow_map\"\n"
  "    texture: \"/defrend/assets/textures/black.png\"\n"
  "  }\n"
  "}\n"
  ""
}
