# modinfo.json File Template

```json
{
  "mods": [
    {
      "name": "First Mod Name",
      "author": "whatever name you want as the Author",
      "version": "1.0",
      "compatibility": "w57",
      "description": "A description of what your mod does",
      "fileType": "pak",
      "fileURL": "the direct download URL for your mod (e.g. https://github.com/your-repo/Icarus-Mods/raw/your-branch/your-mod_P.pak)",
      "imageURL": "A URL to an image that will be displayed in the mod list (optional)",
      "readmdURL": "A link to your mod's README"
    },
    {
      "name": "Second Mod Name",
      "author": "see below",
      "version": "see below",
      "compatibility": "see below",
      "description": "see below",
      "fileType": "see below",
      "fileURL": "see below",
      "imageURL": "see below",
      "readmeURL": "see below"
    }
  ]
}
```

## Notes

- The file should be named `modinfo.json` and live in the top-level directory of your mods repository.
- "mods" is an Array of Objects (even if you only have one mod)
- Please try to list all the mods in a repository in a single `modinfo.json` file.
- You can generally get the "direct download URL" by right-clicking the "download" button and selecting "copy link"

### fields

- `"name"`: The name of your mod
- `"author"`: The name of the author of your mod
- `"version"`: The version of your mod (semantic versioning is recommended)
- `"compatibility"`: The latest version of Icarus that your mod is compatible with (e.g. w56)
- `"description"`: A description of what your mod does
- `"fileType"`: The type of file your mod is (can be "pak" or "zip" but will default to "pak" if not specified)
- `"fileURL"`: The full direct download URL for your mod (either the .zip or .pak file)
- `"readmeURL"`: A link to your mod's README (optional)
- `"imageURL"`: A URL to an image that will be displayed in the mod list (optional)
