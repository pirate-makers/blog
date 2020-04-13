+++
categories = []
date = 2020-04-11T18:29:43Z
description = "Laser Post-Processor for Autodesk Fusion 360 and Shapeoko CNC"
externalLink = ""
series = []
slug = ""
tags = ["laser", "shapeoko", "fusion360", "cnc"]
title = "Laser Post-Processor for Fusion 360 that works on Shapeoko"

+++
 bought a 10W+ Endurence Laser last year. This is an addon to mount on my Shapeoko3 CNC. It's really easy to setup as you only have to attach it on your spindle and connect it to the PWM port of the Shapeoko controler. Don't forget to unplug your spindle :)

I mostly use Autodesk Fusion 360 when I create my CNC projects, and sadly, I found no post-processor that could create Gcode files compatible with the Shapeoko 3 (GRBL).
Differences between a spindle and a laser are really few...:

* PWM goes from 0 to 255
* you don't have to wait for spindle to start spinning
* you want the laser to turn off when you are doing rapid movements

So you need a special Post-Processor to take care of this.

I cloned an existing one and adapted to work with a laser.

You can find the code and instructions at https://github.com/pirate-makers/shapeokolaser