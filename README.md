# JUDE
Alternative pipeline for UVIT
Includes a number of GDL procedures to obtain Level 2 scientific products from the Level 1 UVIT data.
Reference is at https://ui.adsabs.harvard.edu/#abs/2016ascl.soft07007M/abstract

This has been modified by K Sriram for the following features
* Ability to run jude_uv_cleanup interactively
* Ability to run without creating png files
* Bug fixes
  * Fixed not being able to modify boxsize in jude_interactive
  * Rewrote extract_coord in jude_get_xy so that it doesn't use ishft
