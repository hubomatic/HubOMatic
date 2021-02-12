# Hub-O-Matic

[![Build Status](https://github.com/hubomatic/HubOMatic/workflows/HubOMatic%20CI/badge.svg?branch=main)](https://github.com/hubomatic/HubOMatic/actions)
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)


Hub-O-Matic (`HubOMatic`) is a framework for auto-updating macOS 11 apps from GitHub releases.

## About

It handles checking for updates, downloading app releases, and installing it over the currently-running app.

## Sandboxing & App Store distribution

Hub-O-Matic works with sandboxed apps by providing a non-sandboxed XPC helper task to perform the updating. This process is currently not permitted by Apple in the App Store apps, but HubOMatic is designed to enable the same binary to be distributed both to the App Store and distibuted independently by excluding the XPC process from App Store builds (which only requires re-signing the app).

## Process

1. Check 
https://github.com/hubomatic/MicroVector/releases/latest/download/RELEASE_NOTES.md

2. Download
https://github.com/hubomatic/MicroVector/releases/latest/download/MicroVector.zip



## Limitations

## FAQ

1. Is there any purchasing of payment system? 
No. Hub-O-Matic only handles updating the app.




