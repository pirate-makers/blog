+++
slug = "tags"
title = "Tags"

+++
## All tags

{{- with .Params.tags -}}
<div class="tags-list">
<span class="dark-red">Tags</span><span class="decorative-marker">//</span>
{{ delimit (apply (apply (sort . ) "partial" "post/tag/link" ".") "chomp" ".") ", " }}
</div>
{{- end -}}

\`\`\`go-html-template

 <section id="main"> <div> <h1 id="title">{{ .Title }}</h1> {{ range .Pages }} {{ .Render "summary"}} {{ end }} </div> </section> 

\`\`\`