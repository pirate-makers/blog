+++ 
draft = false
date = 2019-05-22T14:29:43-04:00
title = "Welcome to a Pirate world"
description = "Pirate FTW !"
slug = "" 
tags = ["test"]
categories = []
externalLink = ""
series = []
+++
{{< highlight html >}}
<section id="main">
  <div>
   <h1 id="title">{{ .Title }}</h1>
    {{ range .Pages }}
        {{ .Render "summary"}}
    {{ end }}
  </div>
</section>
{{< /highlight >}}

``` js
var foo = function (bar) {
  return bar++;
};

console.log(foo(5));
```