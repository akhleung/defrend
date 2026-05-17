# Materials / renderable objects

Defrend provides a number of materials that should be used instead of the built-in ones so that rendered objects can be correctly lit. Defrend also offers some materials / types of objects that have no built-in counterparts such as billboards, decals, and skyboxes. This section covers all of these materials.

## Models

The model material is used to render the typical 3D object, represented by a model component in Defold. The material file can be found at:

`/defrend/materials/geometry/model/model.material`

This model material takes advantage of GPU instancing so that many duplicate objects can be rendered in a performant manner. This is ideal if the scene contains large numbers of copies or reusable modular elements (e.g., foliage, modular buildings or vehicles, props, hordes of characters, etc).

When using the model material, three textures must be provided: an **albedo map**, **normal map**, and **specular / glow map**.

![model material](images/cube_model_material.png)

The **albedo map** represents the "base color" or "diffuse color" of the object. The **normal map** provides surface normals. The **specular / glow map** combines information about specularity and emissiveness, with the red channel containing specularity and the green channel containing emissiveness. Because Defrend's focus is more on stylized and non-photorealistic rendering, specularity and emissiveness are simple scalar values; specular reflections are white, and emissive color is based on the underlying albedo of the object.

If an object does not require normal mapping, specular reflections, or glow effects, then Defrend provides the following default textures:

`/defrend/assets/textures/flat.png` for plain, flat surfaces

`/defrend/assets/textures/black.png` for matte, non-emissive surfaces

Defrend currently does not support non-instanced or skinned models, but these can easily be added to the pipeline.

## Billboards

The billboard material is used to render static billboards -- 2D images that always face the camera. These are generally used to mimic 3D objects in order to achieve a retro aesthetic, or to represent "imposter" objects for reduced levels of detail in faraway parts of a scene. The material file can be found at:

`/defrend/materials/geometry/billboard_sprite/billboard.material`

>[!NOTE]
> In Defrend, billboards only rotate around the Y axis in order to mimic the appearance of characters and props in early first-person 3D games. In the future, an option will be added to enable rotation along the other axes as well.

The billboard material should be applied to a quad or a cube model component (the reason for using a cube is that frustum culling may be more accurate; the material works by transforming the billboard's vertices in the shader, but a quad billboard may already have been culled too eagerly if it was originally oriented toward the camera edge-on, and was just outside the field of view).

As with [models](#models), billboards require an **albedo map**, **normal map**, and **specular / glow map**, which serve the same purposes as above. The albedo maps for billboards are expected to contain completely transparent regions, which will be rendered as completely transparent. As with models, you can use the included `flat.png` and `black.png` textures if normals, specularity, and emissiveness are not required. For an example of all this, please examine the `/example/assets/billboards/flowerbed/flower.go` object.

![flower billboard](images/flower_billboard.png)

## Sprites

The sprite material is used to render animated [billboards](#billboards) using the built-in sprite component. The material file can be found at:

`/defrend/materials/geometry/billboard_sprite/sprite.material`

>[!NOTE]
> In Defrend, billboard sprites only rotate around the Y axis in order to mimic the appearance of characters and props in early first-person 3D games. In the future, an option will be added to enable rotation along the other axes as well.

As with [models](#models), sprite billboards require an **albedo map**, **normal map**, and **specular / glow map**, which serve the same purposes as above. Tile sources should be constructed out of these texture maps and provided to the material configuration:

![sheep sprite billboard](images/sheep_sprite_billboard.png)

The albedo maps for sprite billboards are expected to contain completely transparent regions, which will be rendered as completely transparent. As with models, you can use the included `flat.png` and `black.png` textures if normals, specularity, and emissiveness are not required. For an example of all this, please examine the `/example/assets/billboards/sheep/sheep.go` object.

## Particle FX

Under construction.

## Decals

The decal material is used to project a 2D image onto a 3D surface; the projected image is called a *decal*, as the name of this material implies. The material file can be found at:

`/defrend/materials/geometry/decal/decal.material`

To create a decal, first create a *decal projector box* using a cube-shaped model component (Defold's built-in cube model is fine), assign the decal material to it, and then assign the textures that you want to project. Note that decals, as with [models](#models), also require an **albedo map**, **normal map**, and **specular / glow map**, which serve the same purposes as above.

>[!NOTE]
> The decal material projects the decal in the positive Z direction, relative to the projector box's local coordinates. In the editor, the visualization for the projector box shows the decal image on the negative Z side, to assist with orienting the projector box correctly.

![decal projector](images/decal_projector.png)

To use a decal, place the projector box in your scene, and position / orient it so that its positive Z face intersects with whatever object it should be projected on.

![decal projector in scene](images/decal_projector_in_scene.png)

>[!NOTE]
> A decal will not be rendered if the camera moves inside its projector box. To minimize the chances of this, try to make the projector box as flat as possible along its Z axis. This should also improve rendering performance, as a flatter (and hence smaller) box will require fewer fragments to be rendered.

For an example of all this, please examine the `/example/assets/models/decal.go` and `/example/main/defold_decal.go` objects.

## Skybox

Under construction.

## Point lights and spot lights

Point lights and spot lights are represented by geometries in Defrend, and hence have custom materials as well. However, because they affect the lighting of the scene, they are described in the [Lighting](lighting.md) section of the documentation.
