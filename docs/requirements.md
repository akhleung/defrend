## Requirements

- requires Defold version 1.11.1 or higher
- in the `game.project` file, under the `Script` section, make sure that `Shared State` is checked, as Defrend uses numerous singleton modules to share state between various components:  
![shared state](images/game.project_script_shared_state.png)
- if you plan to use the configuration GUI, then you will also need to do the following:
    - add [this ImGUI extension](https://github.com/britzl/extension-imgui) to your project's dependencies
    - after fetching the aforementioned dependency, add its `/imgui/bindings/imgui.input_binding` (or a superset of it) to the `Game Binding` field of the `Input` section of `game.project`.

This documentation also assumes basic familiarity with how to use the Defold editor -- e.g., adjusting settings in `game.project`, creating and manipulating assets and adding them to the project outline, navigating around the 3D viewport, and so forth.
