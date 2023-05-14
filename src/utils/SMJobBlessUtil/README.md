#  update helper app's and tool's info.plist

First, build X-Helper app.

Run SMJobBlessUtil in terminal:
```
python3 SMJobBlessUtil-Python3.py setreq path/to/X-Helper.app path/to/X-Helper.app/Contents/Info.plist source/src/X-Helper/helper/_info.plist
```

Copy `Tools owned after installation` from `path/to/X-Helper.app/Contents/Info.plist`, paste into `source/src/X-Helper/info.plist`.

Copy `Clients allowed to add and remove tool` from `source/src/X-Helper/helper/_info.plist`, paste into `source/src/X-Helper/helper/info.plist`.

Then, you don't need fucking plist property anymore.
