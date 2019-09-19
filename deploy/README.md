## Deployment options

### Yaml

Simple deployment using in-cluster authentication with service account

```console
kubectl apply -f yaml/
```

### Helm

Designed for multi cluster deployment injecting kubeconfig through a kubernetes secret.


#### Generating kubeconfig

Create service accounts per cluster:

```bash
CLUSTER_DOMAIN=kops.example.com
NAMESPACE=default
for c in cluster1 cluster2; do
    CONTEXT=${c}.${CLUSTER_DOMAIN}
    kubectl --context ${CONTEXT} -n ${NAMESPACE} apply -f yaml/rbac.yaml
done
```

Generate kubeconfig with sa JWT token and context for each cluster (OSX using `base64 -D`)

```bash
CLUSTER_DOMAIN=kops.example.com
NAMESPACE=default
for c in cluster1 cluster2; do
    CONTEXT=${c}.${CLUSTER_DOMAIN}
    TOKEN=$(kubectl --context ${CONTEXT} -n ${NAMESPACE} get secret `kubectl --context ${CONTEXT} -n ${NAMESPACE} get sa kube-web-view -o json | jq -r .secrets[].name` -o json | jq -r .data.token | base64 -D)
    kubectl --context ${CONTEXT} config view --minify --raw > kubeconfig-${c}.yaml
    KUBECONFIG=kubeconfig-${c}.yaml kubectl config set-credentials ${CONTEXT}-kube-web-view-sa --token=$TOKEN
    KUBECONFIG=kubeconfig-${c}.yaml kubectl config set-context ${CONTEXT} --cluster=${CONTEXT}  --user=${CONTEXT}-kube-web-view-sa
    KUBECONFIG=kubeconfig-${c}.yaml kubectl config use-context ${CONTEXT}

    KUBECONFIG=kubeconfig-${c}.yaml kubectl config unset contexts.${CONTEXT}.namespace
    KUBECONFIG=kubeconfig-${c}.yaml kubectl config unset users.${CONTEXT}
done
# merge the configurations
KUBECONFIG=kubeconfig-cluster1.yaml:kubeconfig-cluster2.yaml kubectl config view --raw > kubeconfig.yaml
```

#### Managing the kubeconfig

You may use something like [helm-secrets](https://github.com/futuresimple/helm-secrets) plugin to keep the contents of `kubeconfig.yaml` encrypted in a `secrets.yaml` file.

```yaml
secrets:
  create: true
  config: |
    <kubeconfig.yaml contents>
```

```console
helm secrets upgrade \
  kube-web-view \
  ./kube-web-view \
  --install \
  --timeout 600 \
  --wait \
  -f secrets.yaml \
  -f values.yaml 
```

Or you may use something like [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets) and refer to the separately managed secret:


After setting up the sealed secrets controller and fetching the public certificate locally, create a secret from the kubeconfig and seal it as follows:

```console
NAMESPACE=default
kubectl create secret generic kube-web-view --from-file=config=kubeconfig.yaml -o yaml --dry-run | kubeseal -n ${NAMESPACE} --cert ./pub-cert.pem --format yaml >kubeconfig-sealed.yaml
kubectl apply -f kubeconfig-sealed.yaml
```

Finally, refer to the secret from the helm install

```
helm upgrade \
  kube-web-view \
  ./kube-web-view \
  --install \
  --timeout 600 \
  --wait \
  --set secrets.name=kube-web-view \
  -f values.yaml
```

#### Cleaning up secrets

Don't forget to remove the unencrypted secrets (and be careful not to commit them to git ... )

```console
rm kubeconfig*.yaml
```
