# Defrend (pronounced "de-friend")

This is a debugging snapshot to demonstrate a strange issue I've encountered while implementing cubemap omnidirectional shadows. To see all aspects of the glitchy behavior, please do the following:
1. Run the project as-is. One point light will render shadows correctly, but the other point light's shadows will flicker in and out, as if the shadowmap isn't always rendered or sampled. Additionally, some of the steady shadows appear to be geometrically incorrect.
2. If you change the resolution of one of the cubemaps (even by only 1 pixel), the shadowmaps should render correctly.
3. Alternatively, if you change the scale of one of the point lights so that they have different sizes, the shadowmaps should also render correctly. (E.g., change the scale of `/example/main/point_light_with_shadows.go` to 49 or 51.)
4. When applying one of the above workarounds, try deleting the `texel_size` uniform from the `point_light_with_shadows.fp` shader and the `point_light_with_shadows.script` controller. The shadows will render incorrectly again, even though the `texel_size` uniform isn't used anywhere.

Other notes:
* This is a deferred rendering pipeline in which point lights are represented by sphere models and drawn with an instanced material. The built-in light components are not used.
* During the shadowmapping phase (`cubemap_shadow.material`), I'm writing linear depth to `gl_FragDepth` in order to avoid extra math in the lighting shader. In particular, I want to avoid having to manually determine which cube face a fragment should sample from, and then manually putting that fragment into the corresponding coordinate space.
* In an earlier implementation, I was using the default nonlinear depth from the depth map and it worked fine. After I switched to linear depth, it seemed to work fine for a while, but at some point the glitches started and I can't seem to get it back to a properly working state.