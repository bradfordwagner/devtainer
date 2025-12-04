---
description: conventional commit
---

1. Write a one liner conventional commit for these changes
    - if there are version upgrades make sure they come in the form of ${key}=${value} if there are multiple make them ${key1}=${value1},${key2}=${value2},etc where keys would be the component name
    - if we know the previous version use ${key}=${prev_value}->${value}
    - you do not need to add "update" at beginning oversion upgrades
    - if possible keep component name in snake_case.

2. Prompt user if ok. note if the user also indicates to push the changes

3. commit as indicated by user (requires git_write permissions)

4. if the user said to push then also push them (requires 'all' permissions for SSL cert access)

