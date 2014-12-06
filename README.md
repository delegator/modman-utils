# modman Utils

This repo is the home of `modman-gen`, a tool to automatically generate [modman][1] files.

# Requirements

  - ruby (tested on 2.1.5p273)

# Usage

Assuming `modman-gen.rb` is located in your `PATH`:

```
cd /project/path/.modman/yourmodule
modman-gen.rb                       # Inspect output before blindly overwriting!
modman-gen.rb > modman
```

# License

Copyright 2014 Delegator, LLC.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

[1]: https://github.com/colinmollenhour/modman
