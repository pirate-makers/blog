---
title: making Kubecolor more inclusive using color themes
description: "In this article we'll dive how to build a Color Theme for Kubecolor and how to be more inclusive by providing themes for color-blind (color disabled or color impaired) people."
date: 2024-03-23T21:19:04.281Z
preview: ""
draft: false
tags: ["kubernetes", "cncf", "go"]
categories: ["devops"]
type: default

image: "images/1.png" 
images:
 - "images/1.png"
---
![image](images/1.png#layoutTextWidth)

[KubeColor](https://github.com/kubecolor/kubecolor) is a project I always used and loved.
I cloned it and started maintaining it back in 2022 when the original author wasn't active anymore.

{{< image src="images/Kubecolor_Logo_White.png" alt="KubeColor" position="center" style="border-radius: 0px; background-color: #212020; max-width: 50%;" >}}

It's a small wrapper around `kubectl`, which reformats the output to add colors. It make it *so easier* to read the output that I still don't understand that it's not more widely used. I actually [gave a lightning talk about it at the KubeCon's Cloud Native Reject europe 2024 in Paris](https://www.youtube.com/live/PWZJzjB7vso?si=CvfnmmdSZP3txENZ&t=32723) if you want a video pitch. But whatever.

One of the long requested feature we to be able to cusotmize the color scheme used for KubeColor.

Actually, when I first cloned the original project, I applied a patch that was globally changing the colors to make thinks less colory and more standard, limiting to a smaller set of colors. Some people started complaining right away, but that's what people do anyways.

Well, as of version 0.3.0, `kubecolor` now supports custom color scheme and theme, thanks to the other main contributor, [AppleJag](https://github.com/applejag), which is a talented (Go) devleoper. I can't thank you enough for all the help on this project.

**So why is this so important ?**

First, `kubecolor` uses the set of colors from your terminal's config, so it always was possible to configure it. Put it another way, `kubecolor` will use the colors from your terminal's theme. Not happy ? Change your theme !

**But there's more...**

According to [this article](https://enchroma.com/blogs/beyond-color/interesting-facts-about-color-blindness), one man out of 12 have some sort of **color blindness** (or color disability). Women are a little less concerned, with one out of 200, but still, it's a lot !

Check the [Wikipedia](https://en.wikipedia.org/wiki/Color_blindness) page to learn more, and there's tons of other sites about this matter. And still, it's usually not something we think of right away.

For example, just look at my blog, with it's low contrast and you'll understand that color blindness was not my main concerns at the time.

## So what to with this ?

Well, as soon as `kubecolor` got the functionnality, I started thinking of adding one or multiple color themes for the various kind of disability. 

The first question that came to my mind was :

It's quite usual to use {{< colour "green" >}} for good things (success) and {{< colour "red" >}} for bad things (errors). But is there a common pattern for disabled persons ? 

Well, so far I don't have this answer. But while searching I learnt few things:

- Color is important, but so is the contrast
- there's also modifiers like **bold** and *italic* that can help better differenciate things
- Maybe I should not add a theme at all and each person will built its own

## Understanding KubeColor Themes

Thanks to Jag, `kubecolor` can process [many kind of definitions to configure the colors](https://github.com/kubecolor/kubecolor/blob/main/README.md#color-theme).

In short:
- using the regular color names will use whatever is defined in your `terminal` application / theme. `white` may be white, or not, but *if* you already have a theme made for color-blindness, you may not have to change anything

- using many other ways to define HEX colors, RGB values and what not will allow to use custom colors not part of your theme

- using `bg=` or `fg=` will allow to change the background or the front (text) color

- it is possible to use any of the `modifiers` like **bold**, *italic* and so on to even better tune the visibility of each fields

- thanks to all the `KUBECOLOR_THEME_*` values, it is possible to fully customize the output of "each" field, depending on the original command used against `kubectl` (like `get` or a `describe`)

- it is possible to create the theme as a file, which also enable sharing it, by creating the `~/.kube/color.yaml` file (in OsX and Linux, may be a different location on Windows). We'll dive on the format later.

- `kubecolor` embeds default themes, as of this writing:
  - dark
    ![image](images/dark-theme.png#layoutTextWidth)
  - light
  - pre-0.0.21-dark: the previous color schema from the original project
    ![image](images/pre-0.0.21-dark-theme.png#layoutTextWidth)
  - pre-0.0.21-light
  - color-blind themes (TBA)

You can check the content of each basic theme in the code in the [config/theme.go](https://github.com/kubecolor/kubecolor/blob/main/config/theme.go#L15) file.

## How to build a theme

As said earlier, you can either use the `KUBECOLOR_THEME_*` env variables or create your theme in the `~/.kube/color.yaml` file.

### using ENV Variables

The easiest is to check the docs at [https://github.com/kubecolor/kubecolor/blob/main/README.md#color-theme](https://github.com/kubecolor/kubecolor/blob/main/README.md#color-theme) and experiment.

In any case, you have to pick a `base` theme, by setting `KUBECOLOR_PRESET`, then update some of the colors. For example you can change all the `running` pods to blue with: 

```
KUBECOLOR_THEME_BASE_SUCCESS=blue KUBECOLOR_PRESET=dark kubecolor get pods -o wide
```

![image](images/running-blue.png#layoutTextWidth)

### Using the config file

Create the file  `~/.kube/color.yaml` and add some content like:

```yaml
preset: dark
theme:
  table:
    header: fg=red:bold:bg=blue
```

So basically, you take the ENV variable and you nest the last part of it.

With `KUBECOLOR_THEME_STATUS_ERROR`, you remove the `KUBECOLOR` part, so the final path is `theme.status.error`, so:

```yaml
preset: dark
theme:
  table:
    header: fg=red:bold:bg=blue
  status:
    error: pink
```

![image](images/crash-magenta.png#layoutTextWidth)

## Color Blind Theme

First I want to clearly state I do not have any color impairement, and the work I'm trying to achieve here is based on some readings and talking to impaired people. The idea is to provide an out of the box solution to help people with color-blindness. The outcome may not be perfect or even useful. Bare with me.

After some researches, I found the [Cromatic Vision Simulator website](https://asada.website/webCVS/index.html) which allows to load an image and, using a quad view, see what impaired persons may see depending on the kind of disability.

In short, if I upload one of the previous images that captured the `k get pods -o wide` commands, we can check how it look:

using the `dark` theme:

- regular view
  ![image](images/get-pods-dark.png#layoutTextWidth)
- Protanopia view
  ![image](images/get-pods-dark-protanopia.png#layoutTextWidth)
- deuteranopia view
  ![image](images/get-pods-dark-deuteranopia.png#layoutTextWidth)
- tritanopia view
  ![image](images/get-pods-dark-tritanopia.png#layoutTextWidth)

Now I guess we all understand the issue with the current color scheme of the `dark` theme: any impaired person will lose most of the color informations.

I also tested the view with some chromatic progressions, trying to find a palette that could work:

![image](images/color-cycles-quad.png#layoutTextWidth)

My final conclusion is that it seems possible to achieve a them that will help. What we need here is having different color hues to show the difference of, mostly, good and bad situation, and color cycles when there's a table. The `turbo` color profile seems to help here.

Using the [Observable HQ website](https://observablehq.com/@d3/color-schemes), I used the `discrete 10` schema to cut the rainbow in 10 usable colors:

- {{< colour "#23171b" >}}
- {{< colour "#4860e6" >}}
- {{< colour "#2aabee" >}}
- {{< colour "#2ee5ae" >}}
- {{< colour "#6afd6a" >}}
- {{< colour "#c0ee3d" >}}
- {{< colour "#feb927" >}}
- {{< colour "#fe6e1a" >}}
- {{< colour "#c2270a" >}}
- {{< colour "#900c00" >}}

Once rendered, we have:

![image](images/turbo-colors.png#layoutTextWidth)

The `dark` theme only uses 6 colors (well, 5 as one if the default white for dark theme, or black for light theme):
- yellow -> {{< colour "#feb927" >}}
- magenta -> {{< colour "#4860e6" >}}
- green -> {{< colour "#6afd6a" >}}
- red -> {{< colour "#c2270a" >}}
- cyan -> {{< colour "#2aabee" >}}

I also used the `bold` on the `success` and I actually inverted the `error` so the background is `red` and the text is white.

The result seems to be pretty much working in all situations:
![image](images/get-pod-impaired-theme-1.png#layoutTextWidth)

![image](images/describe-pod-impaired-theme.png#layoutTextWidth)

So now you can use any of the themes if you're concerned by color blindness. They are:

- protanopia-dark
- protanopia-light
- deuteranopia-dark
- deuteranopia-light
- tritanopia-dark
- tritanopia-light

Just set your env variables like:
```bash
KUBECOLOR_PRESET=protanopia-dark kubecolor get pods

# or
export KUBECOLOR_PRESET=protanopia-dark
kubecolor get pods
```

Or set it in your config file `~/.kube/color.yaml` like:
```yaml
preset: protanopia-dark
```

### Updating the theme

As this is pretty much work in proress, please, feel free to comment and [open an issue](https://github.com/kubecolor/kubecolor/issues) if you feel the current themes can be enhenced.

Also, you can start creating your own theme, by modifying an existing one, then share it either in a `issue` or a `Pull Request`.

Simply add more customization to the `~/.kube/color.yaml`  file:

```yaml
preset: protanopia-dark
theme:
  base:
    key:
       - fg=#feb927
       - fg=white
    info:
    primary: fg=#4860e6
    secondary: fg=#2aabee
    success: fg=#6afd6a:bold
    warning: fg=#feb927
    danger: fg=white:bg=#c2270a
    muted: fg=#feb927
  options:
    flag: fg=#feb927
  table:
    header: fg=white:bold:bg=#2aabee
  status:
    error: fg=white:bg=#c2270a
```