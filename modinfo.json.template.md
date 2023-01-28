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
      "imageURL": "A direct download URL to an image that will be displayed in the mod list (optional)",
      "readmeURL": "A link to the 'raw' version of your mod's README"
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

## Field Descriptions

- `"name"`             : **[required]** The name of your mod
- `"author"`           : **[required]** The name of the author of your mod
- `"version"`          : **[recommended]** The version of your mod (semantic versioning is recommended)
- `"compatibility"`    : **[recommended]** The latest version of Icarus that your mod is compatible with (e.g. w56)
- `"description"`      : **[required]** A description of what your mod does
- `"long_description"` : **[deprecated]** A longer description of what your mod does (use `readmeURL` instead)
- `"fileType"`         : **[required]** The type of file your mod is (can be "pak" or "zip" but will default to "pak" if not specified)
- `"fileURL"`          : **[required]** The full direct download URL for your mod (either the .zip or .pak file)
- `"readmeURL"`        : **[optional]** A link to the RAW version of your mod's README
- `"imageURL"`         : **[optional]** A link to the RAW/direct download URL of an image that will be displayed along with this mod

## Notes

- The file should be named `modinfo.json` and live in the top-level directory of your tool's repository.
- "mod" is an Array of Objects (even if you only have one)
- Please try to list all the tools in a single repository into one `modinfo.json` file.
- The *URL paths should be the "RAW" or "Direct Download" urls.
  - This is the link that you would find by right-clicking the "download" button and selecting "copy link" for binary files
  - Or by clicking the "raw" button and copying the link from the address bar for text files (README, etc.)
