## Getting started

### 1. Add the dependency

First, add Defrend as an external dependency in your Defold project. You can either use the master archive for the latest development version, or one of the releases linked in the sidebar (preferably the latest). E.g.:

    https://github.com/akhleung/defrend/archive/master.zip

or

    https://github.com/akhleung/defrend/archive/refs/tags/1.6.1.zip

![dependencies](images/game.project_project_dependencies.png)

### 2. Add `defrend.render` to your project bootstrap settings

In the `game.project` file, under the Bootstrap section, in the Render box, select `/defrend/render/defrend.render`:

![bootstrap_render](images/game.project_bootstrap_render.png)

### 3. Add `defrend.collection` to your project outline

In your bootstrap collection (or whichever collection requires 3D rendering), add the collection file `/defrend/defrend.collection`. This collection file is supplied by Defrend and provides numerous components and scripts for initializing and configuring the various features of the library.

![outline_defrend_collection](images/outline_defrend.collection.png)

*Note: after this step, you may need to restart Defold if textures do not appear correctly when viewing models in the editor. The shading on models may also appear flat/unlit; this is because the deferred pipeline introduces many additional stages that the Defold editor is currently unable to integrate and preview.*

### 4. Add a camera and light source

In order to view your 3D scene, there must be a camera and at least one light, and Defrend must also know about them.

First, add a camera component to the project outline; this will be the *scene camera*, and rendering will be done from its point of view. Then, in `defrend.collection` in the project outline, select the `defrend | renderer | cameras` script component. In the `scene_camera_url` field, enter the URL of the camera component (Defrend needs to know which camera is being used to render the scene in order to perform shadow mapping correctly).

![outline_defrend_renderer_cameras](images/outline_defrend_renderer_cameras.png)

Next, add a GO (game object) to the project outline to represent a directional light source. Since directional lights are generally intended to simulate sunlight, name this GO `sun`. Add a camera component to the `sun` so that you can visualize its orientation more easily. Then move and rotate the `sun` so that the light points in the desired direction.

![outline_sun](images/outline_defrend_sun.png)

Then, in the project outline, select `defrend | renderer | lighting | light`, and in the `sun_url` field, copy the URL of the `sun` GO. Also adjust the intensity of the sunlight and ambient light to lower values.

![outline_defrend_renderer_lighting_light](images/outline_defrend_renderer_lighting_light.png)

### 5. Add 3D models with the appropriate materials

