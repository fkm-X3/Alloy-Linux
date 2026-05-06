#!/usr/bin/env python3
"""Simple package recipe lister for Alloy-Linux (prototype)."""
import os
root = os.path.dirname(os.path.dirname(__file__))
pkgs = os.path.join(root, 'packages')
if os.path.isdir(pkgs):
    for name in sorted(os.listdir(pkgs)):
        if os.path.isdir(os.path.join(pkgs, name)):
            print(name)
