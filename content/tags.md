+++
slug = "tags"
title = "Tags"

+++
## All tags

trying to add something

    ---
    # Source: elasticsearch-curator/templates/configmap.yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: es-curator-elasticsearch-curator-config
      labels:
        app: elasticsearch-curator
        chart: elasticsearch-curator-1.5.0
        release: es-curator
        heritage: Tiller
    data:
      action_file.yml:   |-
        ---