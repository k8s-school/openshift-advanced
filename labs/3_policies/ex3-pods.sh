#!/bin/bash

set -euxo pipefail

cat <<EOF > /tmp/ubuntu-root.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-root
  labels:
    app: ubuntu
spec:
  containers:
    - name:  ubuntu
      image: ubuntu:latest
      command: ["sleep", "infinity"]
      securityContext:
        runAsUser: 0
EOF

cat <<EOF > /tmp/ubuntu-simple.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-simple
  labels:
    app: ubuntu
spec:
  containers:
    - name:  ubuntu
      image: ubuntu:latest
      command: ["sleep", "infinity"]
EOF

cat <<EOF > /tmp/ubuntu-privileged.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-privileged
  labels:
    app: ubuntu
spec:
  containers:
    - name:  ubuntu
      image: ubuntu:latest
      command: ["sleep", "infinity"]
      securityContext:
        privileged: true
EOF

cat <<EOF > /tmp/nginx-privileged.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-privileged
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
        securityContext:
          privileged: true
EOF
