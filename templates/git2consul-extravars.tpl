gi2consulConfigMaps:
  data:
    init.sh: |-
      #!/bin/sh
      set -x

      mkdir ~/.ssh
      chmod -R 0700 ~/.ssh
      ssh-keyscan github.com >> ~/.ssh/known_hosts
      node /usr/lib/node_modules/git2consul --endpoint ${endpoint} --port 8500 --config-file /data/config.json
    config.json: |-
      {
      "version": "1.0",
      "repos" : [{
        "name" : "config",
        "url" : "git@github.com:ZupIT/darwin-consul-config-k8s-qa.git",
        "include_branch_name" : false,
        "branches" : ["${branch}"],
        "hooks": [{
          "type" : "polling",
          "interval" : "1"
        }]
      }]
      }
    id.rsa: |-
${id-rsa}   
    