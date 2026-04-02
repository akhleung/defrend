# Materials / renderable objects

Defrend provides a number of materials that should be used instead of the built-in ones so that rendered objects can be correctly lit. Defrend also offers some materials / types of objects that have no built-in counterparts such as billboards, decals, and skyboxes. This section covers all of these materials.

## Models

The model material is used to render the typical 3d object. The material file can be found in the Assets pane at:

`/defrend/materials/geometry/model/model.material`

This model material takes advantage of GPU instancing so that many duplicate objects can be rendered in a performant manner. This is ideal if the scene contains large numbers of copies or reusable modular elements (e.g., foliage, modular buildings or vehicles, props, hordes of characters, etc).

When using the model material, three textures must be provided: an albedo map, normal map, and specular / glow map.

![model material](images/cube_model_material.png)

The albedo map represents the "base color" or "diffuse color" of the object. The normal map provides surface normals. The specular / glow map combines information about specularity and emissiveness, with the red channel containing specularity and the green channel containing emissiveness. Because Defrend's focus is more on stylized and non-photorealistic rendering, specularity and emissiveness are simple scalar values; specular reflections are white, and emissive color is based on the underlying albedo of the object.

If an object does not require normal mapping, specular reflections, or glow effects, then Defrend provides the following default textures:

`/defrend/assets/textures/flat.png` for plain, flat surfaces

`/defrend/assets/textures/black.png` for matte, non-emissive surfaces

Defrend currently does not support non-instanced or skinned models, but these can easily be added to the pipeline.

## Billboards and sprites



## Particle FX



## Decals



## Skybox



## Point lights and spot lights

Point lights and spot lights are represented by geometries in Defrend, and hence have custom materials as well. However, because they affect the lighting of the scene, they are described in the [Lighting](lighting.md) section of the documentation.
