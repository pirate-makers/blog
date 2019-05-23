+++
categories = []
date = "2019-05-22T14:29:43.000-04:00"
description = "Pirate FTW !"
externalLink = ""
series = []
slug = ""
tags = ["test"]
title = "Welcome to a Pirate world"

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

    Here is a little Python function to welcome you:
    
    {{< highlight python >}}
    def hello_world():
        print "Hello there!"
    {{< /highlight >}}

\`\`\`json

{"a": "v"}

\`\`\`