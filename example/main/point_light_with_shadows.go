components {
  id: "flicker"
  component: "/example/main/flicker.script"
}
components {
  id: "point_light"
  component: "/defrend/scripts/controllers/point_light.script"
}
embedded_components {
  id: "model"
  type: "model"
  data: "mesh: \"/builtins/assets/gltf/sphere.gltf\"\n"
  "name: \"{{NAME}}\"\n"
  "materials {\n"
  "  name: \"default\"\n"
  "  material: \"/defrend/materials/geometry/light_volume/point_light_with_shadows.material\"\n"
  "  attributes {\n"
  "    name: \"color\"\n"
  "    double_values {\n"
  "      v: 1.0\n"
  "      v: 0.98\n"
  "      v: 0.902\n"
  "      v: 1.0\n"
  "    }\n"
  "  }\n"
  "}\n"
  "create_go_bones: false\n"
  ""
}
