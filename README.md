# Defrend (pronounced "de-friend")

Defrend is a deferred 3D rendering pipeline for the Defold game engine. It provides a collection of materials, shaders, scripts, and other components to facilitate the creation of 3D scenes with modern lighting and post-processing effects. Defrend currently offers the following:

- directional lighting
- deferred, instanced point lights and spot lights
- normal, specular, and emissive maps
- stable, cascaded shadow mapping
- billboard images and sprites
- deferred, instanced decals
- skyboxes
- SSAO
- glow effects
- FXAA
- dual Kawase blur
- Gaussian blur
- outline effects
- comprehensive debug visualizations for the g-buffer, lighting buffers, shadow partitions, shadow map, ssao buffer, etc.
- comprehensive GUI for dynamically configuring all the aforementioned features

In addition to the preceding, Defrend also offers experimental versions of the following features, currently works-in-progress:

- depth of field
- kuwahara blur
- bloom
- gamma correction

Please take a look at the **[web demo](https://akhleung.github.io/Defrend/index.html)** to get a feel for this library's capabilities (left-click and drag to rotate the camera around the scene; middle-click and drag to move the camera vertically and laterally; use the scroll wheel to move the camera forward and backward):

[![demo screenshot](docs/images/demo.png)](https://akhleung.github.io/Defrend/index.html)

## Table of contents

- [Requirements](#requirements)
- [Getting started](#setup)

## Requirements

- requires Defold version 1.11.1 or higher
- in the `game.project` file, under the `Script` section, make sure that `Shared State` is checked, as Defrend uses numerous singleton modules to share state between various components:  
![shared state](docs/images/game.project_script_shared_state.png)

This documentation also assumes basic familiarity with how to use the Defold editor -- e.g., adjusting settings in `game.project`, manipulating assets and adding them to the project outline, navigating around the 3D viewport, and so forth.

## Getting started

### 1. Add the dependency

First, add Defrend as an external dependency in your Defold project. You can either use the master archive for the latest development version, or one of the releases linked in the sidebar (preferably the latest). E.g.:

    https://github.com/akhleung/defrend/archive/master.zip

or

    https://github.com/akhleung/defrend/archive/refs/tags/1.6.1.zip

![dependencies](docs/images/game.project_project_dependencies.png)

### 2. Add `defrend.render` to your project bootstrap settings

In the `game.project` file, under the Bootstrap section, in the Render box, select `/defrend/render/defrend.render`:

![bootstrap_render](/docs/images/game.project_bootstrap_render.png)

### 3. Add `defrend.collection` to your project outline

In your bootstrap collection (or whichever collection requires 3D rendering), add the collection file `/defrend/defrend.collection`. This collection file is supplied by Defrend and provides numerous components and scripts for initializing and configuring the various features of the library.

![outline_defrend_collection](/docs/images/outline_defrend.collection.png)

*Note: after this step, you may need to restart Defold if textures do not appear correctly when viewing models in the editor. The shading on models may also appear flat/unlit; this is because the deferred pipeline introduces many additional stages that the Defold editor is currently unable to integrate and show a live preview of.*

### 4. Add a camera and light source

In order to view your 3D scene, there must be a camera and at least one light, and Defrend must also know about them.

First, add a camera component to the project outline; this will be the *scene camera*, and rendering will be done from its point of view. Then, in `defrend.collection` in the project outline, select the `defrend | renderer | cameras` script component. In the `scene_camera_url` field, enter the URL of the camera component (Defrend needs to know which camera is being used to render the scene in order to perform shadow mapping correctly).

![outline_defrend_renderer_cameras](/docs/images/outline_defrend_renderer_cameras.png)

Next, add a GO (game object) to the project outline to represent a directional light source. Since directional lights are generally intended to simulate sunlight, name this GO `sun`. Add a camera component to the `sun` so that you can visualize its orientation more easily. Make sure that the rotations of the GO and camera are both `(0, 0, 0)` to begin with. Then, move and orient the `sun` so that the light points in the desired direction.

![outline_sun](/docs/images/outline_defrend_sun.png)

Then, in the project outline, select `defrend | renderer | lighting | light`, and in the `sun_url` field, copy the URL of the `sun` GO. Also adjust the intensity of the sunlight and ambient light to lower values.

![outline_defrend_renderer_lighting_light](/docs/images/outline_defrend_renderer_lighting_light.png)

