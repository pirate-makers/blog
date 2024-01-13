+++
categories = []
date = 2019-05-22T18:29:43Z
description = "Pirate FTW !"
draft = true
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

```js
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


Table:
|Kind                         | Group              | Version|
|:--------------------------:|:------------------:|:------:|
|DatabaseInstance             | sql.gcp.upbound.io | v1beta1|
|Database                     | sql.gcp.upbound.io | v1beta1|
|SourceRepresentationInstance | sql.gcp.upbound.io | v1beta1|
|SSLCert                      | sql.gcp.upbound.io | v1beta1|
|User                         | sql.gcp.upbound.io | v1beta1|
