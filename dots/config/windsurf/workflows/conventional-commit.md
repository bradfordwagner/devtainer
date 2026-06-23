---
description: conventional commit
---

1. Write a one liner conventional commit for these changes
    - keep it to 128 or less characters
    - if there are version upgrades make sure they come in the form of ${key}=${value} if there are multiple make them ${key1}=${value1},${key2}=${value2},etc where keys would be the component name
       - when this pushes over 128 characters do your best to summarize
    - if we know the previous version use ${key}=${value}
    - you do not need to add "update" at beginning of version upgrades
    - if possible keep component name in snake_case.

2. setup the command to copy to clipboard. the user will either accept your output or respond with feedback to change the commit message
