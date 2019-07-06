couchbase-cluster
-----------------
couchbase-cluster is a simple 'docker-compose.yml' file which enables the
quick and easy creation of a Couchbase cluster for testing purposes.

Usage
-----
Dependencies:
 - docker
 - docker-compose

First of all ensure that the Couchbase cluster is created and running.
```sh
docker-compose up  # run the whole cluster
docker-compose up -d  # run the whole cluster in daemon mode
docker-compose up node1  # only run a single node
docker-compose up -d node1  # only run a single node in daemon mode
```

Determine the IP address of each Couchbase node.
```sh
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container_id>
```

Setup the Couchbase cluster using the Couchbase WebUI or REST API.

Access the Couchbase testing/backup tools using 'docker exec'
```sh
docker exec -it <container_id> /bin/bash

# change into the tools directory
cd /opt/couchbase/bin
```

License
-------
MIT License

Copyright (c) 2019 James Lee <jamesl33info@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
