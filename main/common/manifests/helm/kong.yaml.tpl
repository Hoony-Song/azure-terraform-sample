# Default values for Kong's Helm Chart.
# Declare variables to be passed into your templates.
#
# Sections:
# - Deployment parameters
# - Kong parameters
# - Ingress Controller parameters
# - Postgres sub-chart parameters
# - Miscellaneous parameters
# - Kong Enterprise parameters

# -----------------------------------------------------------------------------
# Deployment parameters
# -----------------------------------------------------------------------------

deployment:
  kong:
    # Enable or disable Kong itself
    # Setting this to false with ingressController.enabled=true will create a
    # controller-only release.
    enabled: true
  ## Minimum number of seconds for which a newly created pod should be ready without any of its container crashing,
  ## for it to be considered available.
  # minReadySeconds: 60
  ## Specify the service account to create and to be assigned to the deployment / daemonset and for the migrations
  serviceAccount:
    create: true
    # Automount the service account token. By default, this is disabled, and the token is only mounted on the controller
    # container. Some sidecars require enabling this. Note that enabling this exposes Kubernetes credentials to Kong
    # Lua code, increasing potential attack surface.
    automountServiceAccountToken: false
  ## Optionally specify the name of the service account to create and the annotations to add.
  #  name:
  #  annotations: {}

  ## Optionally specify any extra sidecar containers to be included in the deployment
  ## See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#container-v1-core
  # sidecarContainers:
  #   - name: sidecar
  #     image: sidecar:latest
  # initContainers:
  # - name: initcon
  #   image: initcon:latest
  # hostAliases:
  # - ip: "127.0.0.1"
  #   hostnames:
  #   - "foo.local"
  #   - "bar.local"

  ## Define any volumes and mounts you want present in the Kong proxy container
  # userDefinedVolumes:
  # - name: "volumeName"
  #   emptyDir: {}
  # userDefinedVolumeMounts:
  # - name: "volumeName"
  #   mountPath: "/opt/user/dir/mount"
  test:
    # Enable creation of test resources for use with "helm test"
    enabled: false
  # Use a DaemonSet controller instead of a Deployment controller
  daemonset: false
  hostNetwork: false
  # Set the Deployment's spec.template.hostname field.
  # This propagates to Kong API endpoints that report
  # the hostname, such as the admin API root and hybrid mode
  # /clustering/data-planes endpoint
  hostname: ""
  # kong_prefix empty dir size
  prefixDir:
    sizeLimit: 256Mi
  # tmp empty dir size
  tmpDir:
    sizeLimit: 1Gi
# Override namepsace for Kong chart resources. By default, the chart creates resources in the release namespace.
# This may not be desirable when using this chart as a dependency.
# namespace: "example"

# -----------------------------------------------------------------------------
# Kong parameters
# -----------------------------------------------------------------------------

# Specify Kong configuration
# This chart takes all entries defined under `.env` and transforms them into into `KONG_*`
# environment variables for Kong containers.
# Their names here should match the names used in https://github.com/Kong/kong/blob/master/kong.conf.default
# See https://docs.konghq.com/latest/configuration also for additional details
# Values here take precedence over values from other sections of values.yaml,
# e.g. setting pg_user here will override the value normally set when postgresql.enabled
# is set below. In general, you should not set values here if they are set elsewhere.
env:
  admin_api_uri: "http://kongadmin.${pip}.nip.io"
  proxy_api_uri: "http://kongproxy.${pip}.nip.io"
  manager_api_uri: "http://kongmgr.${pip}.nip.io"
  database: "postgres"
  pg_host: "kong-postgresql"
  pg_port: 5432
  pg_user: kong
  pg_database: kong
  # database: "off"
  # the chart uses the traditional router (for Kong 3.x+) because the ingress
  # controller generates traditional routes. if you do not use the controller,
  # you may set this to "traditional_compatible" or "expressions" to use the new
  # DSL-based router
  router_flavor: "traditional"
  nginx_worker_processes: "2"
  proxy_access_log: /dev/stdout
  admin_access_log: /dev/stdout
  admin_gui_access_log: /dev/stdout
  portal_api_access_log: /dev/stdout
  proxy_error_log: /dev/stderr
  admin_error_log: /dev/stderr
  admin_gui_error_log: /dev/stderr
  portal_api_error_log: /dev/stderr
  prefix: /kong_prefix/

# This section is any customer specific environments variables that doesn't require KONG_ prefix.
# These custom environment variables are typicall used in custom plugins or serverless plugins to
# access environment specific credentials or tokens.
# Example as below, uncomment if required and add additional attributes as required.
# Note that these environment variables will only apply to the proxy and init container. The ingress-controller
# container has its own customEnv section.

# customEnv:
#   api_token:
#     valueFrom:
#       secretKeyRef:
#         key: token
#         name: api_key
#   client_name: testClient

# Load all ConfigMap or Secret keys as environment variables:
# https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#configure-all-key-value-pairs-in-a-configmap-as-container-environment-variables
envFrom: []

# This section can be used to configure some extra labels that will be added to each Kubernetes object generated.
extraLabels: {}

# Specify Kong's Docker image and repository details here
image:
  repository: kong/kong-gateway
  tag: "3.6"
  # Kong Enterprise
  # repository: kong/kong-gateway
  # tag: "3.5"

  # Specify a semver version if your image tag is not one (e.g. "nightly")
  effectiveSemver:
  pullPolicy: IfNotPresent
  ## Optionally specify an array of imagePullSecrets.
  ## Secrets must be manually created in the namespace.
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
  ##
  # pullSecrets:
  #   - myRegistrKeySecretName

# Specify Kong admin API service and listener configuration
admin:
  # Enable creating a Kubernetes service for the admin API
  # Disabling this is recommended for most ingress controller configurations
  # Enterprise users that wish to use Kong Manager with the controller should enable this
  enabled: true
  type: ClusterIP
  loadBalancerClass:
  # To specify annotations or labels for the admin service, add them to the respective
  # "annotations" or "labels" dictionaries below.
  annotations: 
    service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
  labels: {}

  http:
    # Enable plaintext HTTP listen for the admin API
    # Disabling this and using a TLS listen only is recommended for most configuration
    enabled: true
    servicePort: 8001
    containerPort: 8001
    # Set a nodePort which is available if service type is NodePort
    # nodePort: 32080
    # Additional listen parameters, e.g. "reuseport", "backlog=16384"
    parameters: []

  tls:
    # Enable HTTPS listen for the admin API
    enabled: false
    servicePort: 8444
    containerPort: 8444
    # Set a target port for the TLS port in the admin API service, useful when using TLS
    # termination on an ELB.
    # overrideServiceTargetPort: 8000
    # Set a nodePort which is available if service type is NodePort
    # nodePort: 32443
    # Additional listen parameters, e.g. "reuseport", "backlog=16384"
    parameters:
    - http2

    # Specify the CA certificate to use for TLS verification of the Admin API client by:
    # - secretName - the secret must contain a key named "tls.crt" with the PEM-encoded certificate.
    # - caBundle (PEM-encoded certificate string).
    # If both are set, caBundle takes precedence.
    client:
      caBundle: ""
      secretName: ""

  # Kong admin ingress settings. Useful if you want to expose the Admin
  # API of Kong outside the k8s cluster.
  ingress:
    # Enable/disable exposure using ingress.
    enabled: true
    ingressClassName: "nginx"
    # TLS secret name.
    # tls: kong-admin.example.com-tls
    # Ingress hostname
    hostname: kongadmin.${pip}.nip.io
    # Map of ingress annotations.
    annotations: {}
      # alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:ap-northeast-2:530406784682:certificate/e13a99b8-bcba-497c-bc83-c74d8c2285f4
      # alb.ingress.kubernetes.io/scheme: internet-facing
      # alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-2016-08
      # alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
      # alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
      # alb.ingress.kubernetes.io/ssl-redirect: '443'
      # alb.ingress.kubernetes.io/target-type: ip
      # external-dns.alpha.kubernetes.io/hostname: kongadmin.hoony.shop
    # Ingress path.
    path: /
    # Each path in an Ingress is required to have a corresponding path type. (ImplementationSpecific/Exact/Prefix)
    pathType: ImplementationSpecific

# Specify Kong status listener configuration
# This listen is internal-only. It cannot be exposed through a service or ingress.
status:
  enabled: true
  http:
    # Enable plaintext HTTP listen for the status listen
    enabled: true
    containerPort: 8100
    parameters: []

  tls:
    # Enable HTTPS listen for the status listen
    # Kong versions prior to 2.1 do not support TLS status listens.
    # This setting must remain false on those versions
    enabled: false
    containerPort: 8543
    parameters: []

# Name the kong hybrid cluster CA certificate secret
clusterCaSecretName: ""

# Specify Kong cluster service and listener configuration
#
# The cluster service *must* use TLS. It does not support the "http" block
# available on other services.
#
# The cluster service cannot be exposed through an Ingress, as it must perform
# TLS client validation directly and is not compatible with TLS-terminating
# proxies. If you need to expose it externally, you must use "type:
# LoadBalancer" and use a TCP-only load balancer (check your Kubernetes
# provider's documentation, as the configuration required for this varies).
cluster:
  enabled: false
  # To specify annotations or labels for the cluster service, add them to the respective
  # "annotations" or "labels" dictionaries below.
  annotations: {}
  #  service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
  labels: {}

  tls:
    enabled: false
    servicePort: 8005
    containerPort: 8005
    parameters: []

  type: ClusterIP
  loadBalancerClass:

  # Kong cluster ingress settings. Useful if you want to split CP and DP
  # in different clusters.
  ingress:
    # Enable/disable exposure using ingress.
    enabled: false
    ingressClassName:
    # TLS secret name.
    # tls: kong-cluster.example.com-tls
    # Ingress hostname
    hostname:
    # Map of ingress annotations.
    annotations: {}
    # Ingress path.
    path: /
    # Each path in an Ingress is required to have a corresponding path type. (ImplementationSpecific/Exact/Prefix)
    pathType: ImplementationSpecific

# Specify Kong proxy service configuration
proxy:
  # Enable creating a Kubernetes service for the proxy
  enabled: true
  type: ClusterIP
  loadBalancerClass:
  # Override proxy Service name
  nameOverride: ""
  # To specify annotations or labels for the proxy service, add them to the respective
  # "annotations" or "labels" dictionaries below.
  annotations: 
  # If terminating TLS at the ELB, the following annotations can be used
  # "service.beta.kubernetes.io/aws-load-balancer-backend-protocol": "*",
  # "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled": "true",
  # "service.beta.kubernetes.io/aws-load-balancer-ssl-cert": "arn:aws:acm:REGION:ACCOUNT:certificate/XXXXXX-XXXXXXX-XXXXXXX-XXXXXXXX",
  # "service.beta.kubernetes.io/aws-load-balancer-ssl-ports": "kong-proxy-tls",
  # "service.beta.kubernetes.io/aws-load-balancer-type": "elb"
  labels:
    enable-metrics: "true"

  http:
    # Enable plaintext HTTP listen for the proxy
    enabled: true
    # Set the servicePort: 0 to skip exposing in the service but still
    # let the port open in container to allow https to http mapping for
    # tls terminated at LB.
    servicePort: 80
    containerPort: 8000
    # Set a nodePort which is available if service type is NodePort
    # nodePort: 32080
    # Additional listen parameters, e.g. "reuseport", "backlog=16384"
    parameters: []

  tls:
    # Enable HTTPS listen for the proxy
    enabled: false
    servicePort: 443
    containerPort: 8443
    # Set a target port for the TLS port in proxy service
    # overrideServiceTargetPort: 8000
    # Set a nodePort which is available if service type is NodePort
    # nodePort: 32443
    # Additional listen parameters, e.g. "reuseport", "backlog=16384"
    parameters:
    - http2

    # Specify the Service's TLS port's appProtocol. This can be useful when integrating with
    # external load balancers that require the `appProtocol` field to be set (e.g. GCP).
    appProtocol: ""

  # Define stream (TCP) listen
  # To enable, remove "[]", uncomment the section below, and select your desired
  # ports and parameters. Listens are dynamically named after their containerPort,
  # e.g. "stream-9000" for the below.
  # Note: although you can select the protocol here, you cannot set UDP if you
  # use a LoadBalancer Service due to limitations in current Kubernetes versions.
  # To proxy both TCP and UDP with LoadBalancers, you must enable the udpProxy Service
  # in the next section and place all UDP stream listen configuration under it.
  stream: []
    #   # Set the container (internal) and service (external) ports for this listen.
    #   # These values should normally be the same. If your environment requires they
    #   # differ, note that Kong will match routes based on the containerPort only.
    # - containerPort: 9000
    #   servicePort: 9000
    #   protocol: TCP
    #   # Optionally set a static nodePort if the service type is NodePort
    #   # nodePort: 32080
    #   # Additional listen parameters, e.g. "ssl", "reuseport", "backlog=16384"
    #   # "ssl" is required for SNI-based routes. It is not supported on versions <2.0
    #   parameters: []

  # Kong proxy ingress settings.
  # Note: You need this only if you are using another Ingress Controller
  # to expose Kong outside the k8s cluster.
  ingress:
    # Enable/disable exposure using ingress.
    enabled: true
    ingressClassName: "nginx"
    # To specify annotations or labels for the ingress, add them to the respective
    # "annotations" or "labels" dictionaries below.
    annotations: {}
      # alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:ap-northeast-2:530406784682:certificate/e13a99b8-bcba-497c-bc83-c74d8c2285f4
      #  alb.ingress.kubernetes.io/scheme: internet-facing
      # alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-2016-08
      # alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
      # alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
      # alb.ingress.kubernetes.io/ssl-redirect: '443'
      # alb.ingress.kubernetes.io/target-type: ip
      # external-dns.alpha.kubernetes.io/hostname: kongproxy.hoony.shop
    labels: {}
    # Ingress hostname
    hostname: kongproxy.${pip}.nip.io
    # Ingress path (when used with hostname above).
    path: /
    # Each path in an Ingress is required to have a corresponding path type (when used with hostname above). (ImplementationSpecific/Exact/Prefix)
    pathType: ImplementationSpecific
    # Ingress hosts. Use this instead of or in combination with hostname to specify multiple ingress host configurations
    hosts: []
      # - host: "kongproxy.hoony.shop"
      #   http:
      #     paths:
      #       - path: /
      #         pathType: ImplementationSpecific
      #         backend:
      #           service:
      #             name: kong-kong-proxy
      #             port:
      #               number: 80
    # - host: kong-proxy.example.com
    #   paths:
    #   # Ingress path.
    #   - path: /*
    #   # Each path in an Ingress is required to have a corresponding path type. (ImplementationSpecific/Exact/Prefix)
    #     pathType: ImplementationSpecific
    # - host: kong-proxy-other.example.com
    #   paths:
    #   # Ingress path.
    #   - path: /other
    #   # Each path in an Ingress is required to have a corresponding path type. (ImplementationSpecific/Exact/Prefix)
    #     pathType: ImplementationSpecific
    #     backend:
    #       service:
    #         name: kong-other-proxy
    #         port:
    #           number: 80
    #
    # TLS secret(s)
    # tls: kong-proxy.example.com-tls
    # Or if multiple hosts/secrets needs to be configured:
    # tls:
    # - secretName: kong-proxy.example.com-tls
    #   hosts:
    #   - kong-proxy.example.com
    # - secretName: kong-proxy-other.example.com-tls
    #   hosts:
    #   - kong-proxy-other.example.com

  # Optionally specify a static load balancer IP.
  # loadBalancerIP:

# Specify Kong UDP proxy service configuration
# Currently, LoadBalancer type Services are generally limited to a single transport protocol
# Multi-protocol Services are an alpha feature as of Kubernetes 1.20:
# https://kubernetes.io/docs/concepts/services-networking/service/#load-balancers-with-mixed-protocol-types
# You should enable this Service if you proxy UDP traffic, and configure UDP stream listens under it
udpProxy:
  # Enable creating a Kubernetes service for UDP proxying
  enabled: false
  type: LoadBalancer
  loadBalancerClass:
  # To specify annotations or labels for the proxy service, add them to the respective
  # "annotations" or "labels" dictionaries below.
  annotations: {}
  #  service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
  labels: {}
  # Optionally specify a static load balancer IP.
  # loadBalancerIP:

  # Define stream (UDP) listen
  # To enable, remove "[]", uncomment the section below, and select your desired
  # ports and parameters. Listens are dynamically named after their servicePort,
  # e.g. "stream-9000" for the below.
  stream: []
    #   # Set the container (internal) and service (external) ports for this listen.
    #   # These values should normally be the same. If your environment requires they
    #   # differ, note that Kong will match routes based on the containerPort only.
    # - containerPort: 9000
    #   servicePort: 9000
    #   protocol: UDP
    #   # Optionally set a static nodePort if the service type is NodePort
    #   # nodePort: 32080
    #   # Additional listen parameters, e.g. "ssl", "reuseport", "backlog=16384"
    #   # "ssl" is required for SNI-based routes. It is not supported on versions <2.0
    #   parameters: []

# Custom Kong plugins can be loaded into Kong by mounting the plugin code
# into the file-system of Kong container.
# The plugin code should be present in ConfigMap or Secret inside the same
# namespace as Kong is being installed.
# The `name` property refers to the name of the ConfigMap or Secret
# itself, while the pluginName refers to the name of the plugin as it appears
# in Kong.
# Subdirectories (which are optional) require separate ConfigMaps/Secrets.
# "path" indicates their directory under the main plugin directory: the example
# below will mount the contents of kong-plugin-rewriter-migrations at "/opt/kong/rewriter/migrations".
plugins: {}
  # configMaps:
  # - pluginName: rewriter
  #   name: kong-plugin-rewriter
  #   subdirectories:
  #   - name: kong-plugin-rewriter-migrations
  #     path: migrations
  # secrets:
  # - pluginName: rewriter
  #   name: kong-plugin-rewriter
# Inject specified secrets as a volume in Kong Container at path /etc/secrets/{secret-name}/
# This can be used to override default SSL certificates.
# Be aware that the secret name will be used verbatim, and that certain types
# of punctuation (e.g. `.`) can cause issues.
# Example configuration
# secretVolumes:
# - kong-proxy-tls
# - kong-admin-tls
secretVolumes: []

# Enable/disable migration jobs, and set annotations for them
migrations:
  # Enable pre-upgrade migrations (run "kong migrations up")
  preUpgrade: true
  # Enable post-upgrade migrations (run "kong migrations finish")
  postUpgrade: true
  # Annotations to apply to migrations job pods
  # By default, these disable service mesh sidecar injection for Istio and Kuma,
  # as the sidecar containers do not terminate and prevent the jobs from completing
  annotations:
    sidecar.istio.io/inject: false
  # Additional annotations to apply to migration jobs
  # This is helpful in certain non-Helm installation situations such as GitOps
  # where additional control is required around this job creation.
  jobAnnotations: {}
  # Optionally set a backoffLimit. If none is set, Jobs will use the cluster default
  backoffLimit:
  resources: {}
  # Example reasonable setting for "resources":
  # resources:
  #   limits:
  #     cpu: 100m
  #     memory: 256Mi
  #   requests:
  #     cpu: 50m
  #     memory: 128Mi
  ## Optionally specify any extra sidecar containers to be included in the deployment
  ## See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#container-v1-core
  ## Keep in mind these containers should be terminated along with the main
  ## migration containers
  # sidecarContainers:
  #   - name: sidecar
  #     image: sidecar:latest

# Kong's configuration for DB-less mode
# Note: Use this section only if you are deploying Kong in DB-less mode
# and not as an Ingress Controller.
dblessConfig:
  # Either Kong's configuration is managed from an existing ConfigMap (with Key: kong.yml)
  configMap: ""
  # Or Kong's configuration is managed from an existing Secret (with Key: kong.yml)
  secret: ""
  # Or the configuration is passed in full-text below
  config: |
  # # _format_version: "1.1"
  # # services:
  # #   # Example configuration
  # #   # - name: example.com
  # #   #   url: http://example.com
  # #   #   routes:
  # #   #   - name: example
  # #   #     paths:
  # #   #     - "/example"
  ## Optionally specify any extra sidecar containers to be included in the
  ## migration jobs
  ## See https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#container-v1-core
  # sidecarContainers:
  #   - name: sidecar
  #     image: sidecar:latest

# -----------------------------------------------------------------------------
# Ingress Controller parameters
# -----------------------------------------------------------------------------

# Kong Ingress Controller's primary purpose is to satisfy Ingress resources
# created in k8s. It uses CRDs for more fine grained control over routing and
# for Kong specific configuration.
ingressController:
  enabled: true
  image:
    repository: kong/kubernetes-ingress-controller
    tag: "3.2"
    # Optionally set a semantic version for version-gated features. This can normally
    # be left unset. You only need to set this if your tag is not a semver string,
    # such as when you are using a "next" tag. Set this to the effective semantic
    # version of your tag: for example if using a "next" image for an unreleased 3.1.0
    # version, set this to "3.1.0".
    effectiveSemver:
  args: []

  gatewayDiscovery:
    enabled: false
    generateAdminApiService: false
    adminApiService:
      namespace: ""
      name: ""

  # Specify individual namespaces to watch for ingress configuration. By default,
  # when no namespaces are set, the controller watches all namespaces and uses a
  # ClusterRole to grant access to Kubernetes resources. When you list specific
  # namespaces, the controller will watch those namespaces only and will create
  # namespaced-scoped Roles for each of them. The controller will still use a
  # ClusterRole for cluster-scoped resources.
  # Requires controller 2.0.0 or newer.
  watchNamespaces: []

  # Specify Kong Ingress Controller configuration via environment variables
  env:
    # The controller disables TLS verification by default because Kong
    # generates self-signed certificates by default. Set this to false once you
    # have installed CA-signed certificates.
    kong_admin_tls_skip_verify: true
    # If using Kong Enterprise with RBAC enabled, uncomment the section below
    # and specify the secret/key containing your admin token.
    # kong_admin_token:
    #   valueFrom:
    #     secretKeyRef:
    #        name: CHANGEME-admin-token-secret
    #        key: CHANGEME-admin-token-key

  # This section is any customer specific environments variables that doesn't require CONTROLLER_ prefix.
  # Example as below, uncomment if required and add additional attributes as required.
  # customEnv:
  #   TZ: "Europe/Berlin"

  # Load all ConfigMap or Secret keys as environment variables:
  # https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#configure-all-key-value-pairs-in-a-configmap-as-container-environment-variables
  envFrom: []

  admissionWebhook:
    enabled: true
    filterSecrets: false
    failurePolicy: Ignore
    port: 8080
    certificate:
      provided: false
    namespaceSelector: {}
    # Specifiy the secretName when the certificate is provided via a TLS secret
    # secretName: ""
    # Specifiy the CA bundle of the provided certificate.
    # This is a PEM encoded CA bundle which will be used to validate the webhook certificate. If unspecified, system trust roots on the apiserver are used.
    # caBundle:
    #   | Add the CA bundle content here.
    service:
      # Specify custom labels for the validation webhook service.
      labels: {}
    # Tune the default Kubernetes timeoutSeconds of 10 seconds
    # timeoutSeconds: 10

  ingressClass: kong
  # annotations for IngressClass resource (Kubernetes 1.18+)
  ingressClassAnnotations: {}

  ## Define any volumes and mounts you want present in the ingress controller container
  ## Volumes are defined above in deployment.userDefinedVolumes
  # userDefinedVolumeMounts:
  # - name: "volumeName"
  #   mountPath: "/opt/user/dir/mount"

  rbac:
    # Specifies whether RBAC resources should be created
    create: true

  # general properties
  livenessProbe:
    httpGet:
      path: "/healthz"
      port: 10254
      scheme: HTTP
    initialDelaySeconds: 5
    timeoutSeconds: 5
    periodSeconds: 10
    successThreshold: 1
    failureThreshold: 3
  readinessProbe:
    httpGet:
      path: "/readyz"
      port: 10254
      scheme: HTTP
    initialDelaySeconds: 5
    timeoutSeconds: 5
    periodSeconds: 10
    successThreshold: 1
    failureThreshold: 3
  resources: {}
  # Example reasonable setting for "resources":
  # resources:
  #   limits:
  #     cpu: 100m
  #     memory: 256Mi
  #   requests:
  #     cpu: 50m
  #     memory: 128Mi

  konnect:
    enabled: false

    # Specifies a Konnect Runtime Group's ID that the controller will push its data-plane config to.
    runtimeGroupID: ""

    # Specifies a Konnect API hostname that the controller will use to push its data-plane config to.
    # By default, this is set to US region's production API hostname.
    # If you are using a different region, you can set this to the appropriate hostname (e.g. "eu.kic.api.konghq.com").
    apiHostname: "us.kic.api.konghq.com"

    # Specifies a secret that contains a client TLS certificate that the controller
    # will use to authenticate against Konnect APIs.
    tlsClientCertSecretName: "konnect-client-tls"

    license:
      # Specifies whether the controller should fetch a license from Konnect and apply it to managed Gateways.
      enabled: false

  adminApi:
    tls:
      client:
        # Enable TLS client authentication for the Admin API.
        enabled: false

        # If set to false, Helm will generate certificates for you.
        # If set to true, you are expected to provide your own secret (see secretName, caSecretName).
        certProvided: false

        # Client TLS certificate/key pair secret name that Ingress Controller will use to authenticate with Kong Admin API.
        # If certProvided is set to false, it is optional (can be specified though if you want to force Helm to use
        # a specific secret name).
        secretName: ""

        # CA TLS certificate/key pair secret name that the client TLS certificate is signed by.
        # If certProvided is set to false, it is optional (can be specified though if you want to force Helm to use
        # a specific secret name).
        caSecretName: ""


# -----------------------------------------------------------------------------
# Postgres sub-chart parameters
# -----------------------------------------------------------------------------

# Kong can run without a database or use either Postgres or Cassandra
# as a backend datatstore for it's configuration.
# By default, this chart installs Kong without a database.

# If you would like to use a database, there are two options:
# - (recommended) Deploy and maintain a database and pass the connection
#   details to Kong via the `env` section.
# - You can use the below `postgresql` sub-chart to deploy a database
#   along-with Kong as part of a single Helm release. Running a database
#   independently is recommended for production, but the built-in Postgres is
#   useful for quickly creating test instances.

# PostgreSQL chart documentation:
# https://github.com/bitnami/charts/blob/master/bitnami/postgresql/README.md
#
# WARNING: by default, the Postgres chart generates a random password each
# time it upgrades, which breaks access to existing volumes. You should set a
# password explicitly:
# https://github.com/Kong/charts/blob/main/charts/kong/FAQs.md#kong-fails-to-start-after-helm-upgrade-when-postgres-is-used-what-do-i-do

postgresql:
  enabled: true
  auth:
    username: kong
    database: kong
  image:
    # use postgres < 14 until is https://github.com/Kong/kong/issues/8533 resolved and released
    # enterprise (kong-gateway) supports postgres 14
    tag: 13.11.0-debian-11-r20
  service:
    ports:
      postgresql: "5432"

# -----------------------------------------------------------------------------
# Configure cert-manager integration
# -----------------------------------------------------------------------------

certificates:
  enabled: false

  # Set either `issuer` or `clusterIssuer` to the name of the desired cert manager issuer
  # If left blank a built in self-signed issuer will be created and utilized
  issuer: ""
  clusterIssuer: ""

  # Set proxy.enabled to true to issue default kong-proxy certificate with cert-manager
  proxy:
    enabled: true
    # Set `issuer` or `clusterIssuer` to name of alternate cert-manager clusterIssuer to override default
    # self-signed issuer.
    issuer: ""
    clusterIssuer: ""
    # Use commonName and dnsNames to set the common name and dns alt names which this
    # certificate is valid for. Wildcard records are supported by the included self-signed issuer.
    commonName: "app.example"
    # Remove the "[]" and uncomment/change the examples to add SANs
    dnsNames: []
    # - "app.example"
    # - "*.apps.example"
    # - "*.kong.example"

  # Set admin.enabled true to issue kong admin api and manager certificate with cert-manager
  admin:
    enabled: true
    # Set `issuer` or `clusterIssuer` to name of alternate cert-manager clusterIssuer to override default
    # self-signed issuer.
    issuer: ""
    clusterIssuer: ""
    # Use commonName and dnsNames to set the common name and dns alt names which this
    # certificate is valid for. Wildcard records are supported by the included self-signed issuer.
    commonName: "kong.example"
    # Remove the "[]" and uncomment/change the examples to add SANs
    dnsNames: []
    # - "manager.kong.example"

  # Set portal.enabled to true to issue a developer portal certificate with cert-manager
  portal:
    enabled: true
    # Set `issuer` or `clusterIssuer` to name of alternate cert-manager clusterIssuer to override default
    # self-signed issuer.
    issuer: ""
    clusterIssuer: ""
    # Use commonName and dnsNames to set the common name and dns alt names which this
    # certificate is valid for. Wildcard records are supported by the included self-signed issuer.
    commonName: "developer.example"
    # Remove the "{}" and uncomment/change the examples to add SANs
    dnsNames: []
    # - "manager.kong.example"

  # Set cluster.enabled true to issue kong hybrid mtls certificate with cert-manager
  cluster:
    enabled: true
    # Issuers used by the control and data plane releases must match for this certificate.
    issuer: ""
    clusterIssuer: ""
    commonName: "kong_clustering"
    dnsNames: []

# -----------------------------------------------------------------------------
# Miscellaneous parameters
# -----------------------------------------------------------------------------

waitImage:
  # Wait for the database to come online before starting Kong or running migrations
  # If Kong is to access the database through a service mesh that injects a sidecar to
  # Kong's container, this must be disabled. Otherwise there'll be a deadlock:
  # InitContainer waiting for DB access that requires the sidecar, and the sidecar
  # waiting for InitContainers to finish.
  enabled: true
  # Optionally specify an image that provides bash for pre-migration database
  # checks. If none is specified, the chart uses the Kong image. The official
  # Kong images provide bash
  # repository: bash
  # tag: 5
  pullPolicy: IfNotPresent

# update strategy
updateStrategy: {}
  # type: RollingUpdate
  # rollingUpdate:
  #   maxSurge: "100%"
  #   maxUnavailable: "0%"

# If you want to specify resources, uncomment the following
# lines, adjust them as necessary, and remove the curly braces after 'resources:'.
resources: {}
  # limits:
  #  cpu: 1
  #  memory: 2G
  # requests:
  #  cpu: 1
  #  memory: 2G

# readinessProbe for Kong pods
readinessProbe:
  httpGet:
    path: "/status/ready"
    port: status
    scheme: HTTP
  initialDelaySeconds: 5
  timeoutSeconds: 5
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3

# livenessProbe for Kong pods
livenessProbe:
  httpGet:
    path: "/status"
    port: status
    scheme: HTTP
  initialDelaySeconds: 5
  timeoutSeconds: 5
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3

# startupProbe for Kong pods
# startupProbe:
#   httpGet:
#     path: "/status"
#     port: status
#     scheme: HTTP
#   initialDelaySeconds: 5
#   timeoutSeconds: 5
#   periodSeconds: 2
#   successThreshold: 1
#   failureThreshold: 40

# Proxy container lifecycle hooks
# Ref: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/
lifecycle:
  preStop:
    exec:
      # kong quit has a default timeout of 10 seconds, and a default wait of 0 seconds.
      # Note: together they should be less than the terminationGracePeriodSeconds setting below.
      command:
        - kong
        - quit
        - '--wait=15'

# Sets the termination grace period for pods spawned by the Kubernetes Deployment.
# Ref: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#hook-handler-execution
terminationGracePeriodSeconds: 30

# Affinity for pod assignment
# Ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity
# affinity: {}

# Topology spread constraints for pod assignment (requires Kubernetes >= 1.19)
# Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/
# topologySpreadConstraints: []

# Tolerations for pod assignment
# Ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
tolerations: []

# Node labels for pod assignment
# Ref: https://kubernetes.io/docs/user-guide/node-selection/
nodeSelector: {}

# Annotation to be added to Kong pods
podAnnotations:
  kuma.io/gateway: enabled
  traffic.sidecar.istio.io/includeInboundPorts: ""

# Labels to be added to Kong pods
podLabels: {}

# Kong pod count.
# It has no effect when autoscaling.enabled is set to true
replicaCount: 1

# Annotations to be added to Kong deployment
deploymentAnnotations: {}

# Enable autoscaling using HorizontalPodAutoscaler
# When configuring an HPA, you must set resource requests on all containers via
# "resources" and, if using the controller, "ingressController.resources" in values.yaml
autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 5
  behavior: {}
  ## targetCPUUtilizationPercentage only used if the cluster doesn't support autoscaling/v2 or autoscaling/v2beta
  targetCPUUtilizationPercentage:
  ## Otherwise for clusters that do support autoscaling/v2 or autoscaling/v2beta, use metrics
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80

# Kong Pod Disruption Budget
podDisruptionBudget:
  enabled: false
  # Uncomment only one of the following when enabled is set to true
  # maxUnavailable: "50%"
  # minAvailable: "50%"

podSecurityPolicy:
  enabled: false
  labels: {}
  annotations: {}
  spec:
    privileged: false
    fsGroup:
      rule: RunAsAny
    runAsUser:
      rule: RunAsAny
    runAsGroup:
      rule: RunAsAny
    seLinux:
      rule: RunAsAny
    supplementalGroups:
      rule: RunAsAny
    volumes:
      - 'configMap'
      - 'secret'
      - 'emptyDir'
      - 'projected'
    allowPrivilegeEscalation: false
    hostNetwork: false
    hostIPC: false
    hostPID: false
    # Make the root filesystem read-only. This is not compatible with Kong Enterprise <1.5.
    # If you use Kong Enterprise <1.5, this must be set to false.
    readOnlyRootFilesystem: true


priorityClassName: ""

# securityContext for Kong pods.
securityContext: {}

# securityContext for containers.
containerSecurityContext:
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  runAsUser: 1000
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault
  capabilities:
    drop:
    - ALL

## Optional DNS configuration for Kong pods
# dnsPolicy: ClusterFirst
# dnsConfig:
#   nameservers:
#   - "10.100.0.10"
#   options:
#   - name: ndots
#     value: "5"
#   searches:
#   - default.svc.cluster.local
#   - svc.cluster.local
#   - cluster.local
#   - us-east-1.compute.internal

serviceMonitor:
  # Specifies whether ServiceMonitor for Prometheus operator should be created
  # If you wish to gather metrics from a Kong instance with the proxy disabled (such as a hybrid control plane), see:
  # https://github.com/Kong/charts/blob/main/charts/kong/README.md#prometheus-operator-integration
  enabled: false
  # interval: 30s
  # Specifies namespace, where ServiceMonitor should be installed
  # namespace: monitoring
  # labels:
  #   foo: bar
  # targetLabels:
  #   - foo

  # honorLabels: false
  # metricRelabelings: []

# -----------------------------------------------------------------------------
# Kong Enterprise parameters
# -----------------------------------------------------------------------------

# Toggle Kong Enterprise features on or off
# RBAC and SMTP configuration have additional options that must all be set together
# Other settings should be added to the "env" settings below
enterprise:
  enabled: true
  # Kong Enterprise license secret name
  # This secret must contain a single 'license' key, containing your base64-encoded license data
  # The license secret is required to unlock all Enterprise features. If you omit it,
  # Kong will run in free mode, with some Enterprise features disabled.
  # license_secret: kong-enterprise-license
  vitals:
    enabled: true
  portal:
    enabled: false
  rbac:
    enabled: false
    admin_gui_auth: basic-auth
    # If RBAC is enabled, this Secret must contain an admin_gui_session_conf key
    # The key value must be a secret configuration, following the example at
    # https://docs.konghq.com/enterprise/latest/kong-manager/authentication/sessions
    # If using 3.6+ and OIDC, session configuration is instead handled in the auth configuration,
    # and this field can be left empty.
    session_conf_secret: "kong-session-config"  # CHANGEME
    # If admin_gui_auth is not set to basic-auth, provide a secret name which
    # has an admin_gui_auth_conf key containing the plugin config JSON
    admin_gui_auth_conf_secret: CHANGEME-admin-gui-auth-conf-secret
  # For configuring emails and SMTP, please read through:
  # https://docs.konghq.com/enterprise/latest/developer-portal/configuration/smtp
  # https://docs.konghq.com/enterprise/latest/kong-manager/networking/email
  smtp:
    enabled: false
    portal_emails_from: none@example.com
    portal_emails_reply_to: none@example.com
    admin_emails_from: none@example.com
    admin_emails_reply_to: none@example.com
    smtp_admin_emails: none@example.com
    smtp_host: smtp.example.com
    smtp_port: 587
    smtp_auth_type: ''
    smtp_ssl: nil
    smtp_starttls: true
    auth:
      # If your SMTP server does not require authentication, this section can
      # be left as-is. If smtp_username is set to anything other than an empty
      # string, you must create a Secret with an smtp_password key containing
      # your SMTP password and specify its name here.
      smtp_username: ''  # e.g. postmaster@example.com
      smtp_password_secret: CHANGEME-smtp-password

manager:
  # Enable creating a Kubernetes service for Kong Manager
  enabled: true
  type: ClusterIP
  loadBalancerClass:
  # To specify annotations or labels for the Manager service, add them to the respective
  # "annotations" or "labels" dictionaries below.
  annotations: {}
  #  service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
  labels: {}

  http:
    # Enable plaintext HTTP listen for Kong Manager
    enabled: true
    servicePort: 8002
    containerPort: 8002
    # Set a nodePort which is available if service type is NodePort
    # nodePort: 32080
    # Additional listen parameters, e.g. "reuseport", "backlog=16384"
    parameters: []

  tls:
    # Enable HTTPS listen for Kong Manager
    enabled: false
    servicePort: 8445
    containerPort: 8445
    # Set a nodePort which is available if service type is NodePort
    # nodePort: 32443
    # Additional listen parameters, e.g. "reuseport", "backlog=16384"
    parameters:
    - http2

  ingress:
    # Enable/disable exposure using ingress.
    enabled: true
    ingressClassName: "nginx"
    # TLS secret name.
    # tls: kong-manager.example.com-tls
    # Ingress hostname
    hostname: kongmgr.${pip}.nip.io
    # Map of ingress annotations.
    annotations: {}
      # alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:ap-northeast-2:530406784682:certificate/e13a99b8-bcba-497c-bc83-c74d8c2285f4
      # alb.ingress.kubernetes.io/scheme: internet-facing
      # alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-2016-08
      # alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
      # alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
      # alb.ingress.kubernetes.io/ssl-redirect: '443'
      # alb.ingress.kubernetes.io/target-type: ip
      # external-dns.alpha.kubernetes.io/hostname: kongmgr.hoony.shop
    # Ingress path.
    path: /
    # Each path in an Ingress is required to have a corresponding path type. (ImplementationSpecific/Exact/Prefix)
    pathType: ImplementationSpecific

portal:
  # Enable creating a Kubernetes service for the Developer Portal
  enabled: false
  type: NodePort
  loadBalancerClass:
  # To specify annotations or labels for the Portal service, add them to the respective
  # "annotations" or "labels" dictionaries below.
  annotations: {}
  #  service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
  labels: {}

  http:
    # Enable plaintext HTTP listen for the Developer Portal
    enabled: true
    servicePort: 8003
    containerPort: 8003
    # Set a nodePort which is available if service type is NodePort
    # nodePort: 32080
    # Additional listen parameters, e.g. "reuseport", "backlog=16384"
    parameters: []

  tls:
    # Enable HTTPS listen for the Developer Portal
    enabled: false
    servicePort: 8446
    containerPort: 8446
    # Set a nodePort which is available if service type is NodePort
    # nodePort: 32443
    # Additional listen parameters, e.g. "reuseport", "backlog=16384"
    parameters:
    - http2

  ingress:
    # Enable/disable exposure using ingress.
    enabled: false
    ingressClassName:
    # TLS secret name.
    # tls: kong-portal.example.com-tls
    # Ingress hostname
    hostname:
    # Map of ingress annotations.
    annotations: {}
    # Ingress path.
    path: /
    # Each path in an Ingress is required to have a corresponding path type. (ImplementationSpecific/Exact/Prefix)
    pathType: ImplementationSpecific

portalapi:
  # Enable creating a Kubernetes service for the Developer Portal API
  enabled: false
  type: NodePort
  loadBalancerClass:
  # To specify annotations or labels for the Portal API service, add them to the respective
  # "annotations" or "labels" dictionaries below.
  annotations: {}
  #  service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
  labels: {}

  http:
    # Enable plaintext HTTP listen for the Developer Portal API
    enabled: true
    servicePort: 8004
    containerPort: 8004
    # Set a nodePort which is available if service type is NodePort
    # nodePort: 32080
    # Additional listen parameters, e.g. "reuseport", "backlog=16384"
    parameters: []

  tls:
    # Enable HTTPS listen for the Developer Portal API
    enabled: false
    servicePort: 8447
    containerPort: 8447
    # Set a nodePort which is available if service type is NodePort
    # nodePort: 32443
    # Additional listen parameters, e.g. "reuseport", "backlog=16384"
    parameters:
    - http2

  ingress:
    # Enable/disable exposure using ingress.
    enabled: false
    ingressClassName:
    # TLS secret name.
    # tls: kong-portalapi.example.com-tls
    # Ingress hostname
    hostname:
    # Map of ingress annotations.
    annotations: {}
    # Ingress path.
    path: /
    # Each path in an Ingress is required to have a corresponding path type. (ImplementationSpecific/Exact/Prefix)
    pathType: ImplementationSpecific

clustertelemetry:
  enabled: false
  # To specify annotations or labels for the cluster telemetry service, add them to the respective
  # "annotations" or "labels" dictionaries below.
  annotations: {}
  #  service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
  labels: {}

  tls:
    enabled: false
    servicePort: 8006
    containerPort: 8006
    parameters: []

  type: ClusterIP
  loadBalancerClass:

  # Kong clustertelemetry ingress settings. Useful if you want to split
  # CP and DP in different clusters.
  ingress:
    # Enable/disable exposure using ingress.
    enabled: false
    ingressClassName:
    # TLS secret name.
    # tls: kong-clustertelemetry.example.com-tls
    # Ingress hostname
    hostname:
    # Map of ingress annotations.
    annotations: {}
    # Ingress path.
    path: /
    # Each path in an Ingress is required to have a corresponding path type. (ImplementationSpecific/Exact/Prefix)
    pathType: ImplementationSpecific

extraConfigMaps: []
# extraConfigMaps:
# - name: my-config-map
#   mountPath: /mount/to/my/location
#   subPath: my-subpath # Optional, if you wish to mount a single key and not the entire ConfigMap

extraSecrets: []
# extraSecrets:
# - name: my-secret
#   mountPath: /mount/to/my/location
#   subPath: my-subpath # Optional, if you wish to mount a single key and not the entire ConfigMap

extraObjects: []
# extraObjects:
# - apiVersion: configuration.konghq.com/v1
#   kind: KongClusterPlugin
#   metadata:
#     name: prometheus
#   config:
#     per_consumer: false
#   plugin: prometheus
