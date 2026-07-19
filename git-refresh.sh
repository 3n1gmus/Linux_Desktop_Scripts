#!/bin/bash

# Note: Copy one level up from script source folder.

# Remove Existing
rm -dfr ./Linux_Desktop_Scripts/

# Clone from Source
git clone https://github.com/3n1gmus/Linux_Desktop_Scripts.git

# Set Execution
chmod +x ./Linux_Desktop_Scripts/*.sh