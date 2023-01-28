# toolinfo.json File Template

```json
{
  "tools": [
    {
      "name": "First Tool Name",
      "author": "whatever name you want as the Author",
      "version": "1.0",
      "compatibility": "all",
      "description": "A description of what your tool does",
      "fileType": "ZIP",
      "fileURL": "the direct download URL for your tool (e.g. https://github.com/your-repo/Icarus-Tools/raw/your-branch/your-tool.pak)",
      "imageURL": "A direct download URL to an image that will be displayed in the tool list (optional)",
      "readmeURL": "A link to the 'raw' version of your tool's README"
    },
    {
      "name": "Second Tool Name",
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

- The file should be named `toolinfo.json` and live in the top-level directory of your tool's repository.
- "tools" is an Array of Objects (even if you only have one)
- Please try to list all the tools in a single repository into one `toolinfo.json` file.
- The *URL paths should be the "RAW" or "Direct Download" urls.
  - This is the link that you would find by right-clicking the "download" button and selecting "copy link" for binary files
  - Or by clicking the "raw" button and copying the link from the address bar for text files (README, etc.)

### fields

- `"name"`         : **[required]** The name of your tool
- `"author"`       : **[required]** The name of the author of your tool
- `"version"`      : **[recommended]** The version of your tool (semantic versioning is recommended)
- `"compatibility"`: **[recommended]** The latest version of Icarus that your tool is compatible with (e.g. w56)
- `"description"`  : **[required]** A description of what your tool does
- `"fileType"`     : **[required]** The type of file your tool is (can be "exe" or "zip" but will default to "zip" if not specified)
- `"fileURL"`      : **[required]** The full direct download URL for your tool (either the .zip or .pak file)
- `"readmeURL"`    : **[optional]** A link to the RAW version of your tool's README
- `"imageURL"`     : **[optional]** A link to the RAW/direct download URL of an image that will be displayed along with this tool
