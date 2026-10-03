<p align="center">
  <img src="assets/logo.png" width="128" alt="d77void logo">
</p>

<h1 align="center">d77void</h1>

<p align="center">
  ISO creator for d77void.
</p>

---

## Overview

This repository is a fork of void-mklive, heavily modified to include skel for a huge amount of WM and DE.

It is possible to build ISOs with and without Calamares.

Builds with Calamares use the d77void logo throughout the installer and a
four-image slideshow presenting d77void, Void Linux, the available desktop
choices and the project community. The slideshow images fill the available
area and the installer window adapts to smaller screens.

Every variant identifies itself as `d77void GNU/Linux` through
`/etc/os-release`, while `ID_LIKE=void` records its Void Linux base. The file
uses the project website and the `d77void` icon installed with the image.

## Usage

Clone repository

```
git clone https://github.com/d77void/d77void
```

Clone submodules

```
git submodule update --init --checkout
```

Read carefully the INSTALL.md file to know how to use it.

Happy hacking.
