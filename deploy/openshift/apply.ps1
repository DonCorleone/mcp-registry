# MCP Registry - OpenShift Deployment Script (PowerShell)
# Voraussetzungen: oc CLI installiert und eingeloggt (oc login ...)

$NAMESPACE = "mcp-registry"  # Anpassen falls anderer Namespace

# 1. Namespace erstellen (falls nicht vorhanden)
oc new-project $NAMESPACE --skip-config-write 2>$null
if ($LASTEXITCODE -ne 0) {
    oc project $NAMESPACE
}

# 2. Image bauen und pushen
# Anpassen: deine interne Registry
$REGISTRY = "your-registry.company.com"
$IMAGE = "$REGISTRY/mcp-registry:latest"

docker build -t $IMAGE ../..
docker push $IMAGE

# 3. Ressourcen anwenden
# WICHTIG: secret.yaml zuerst mit echten Werten befüllen!
oc apply -f secret.yaml
oc apply -f configmap.yaml
oc apply -f deployment.yaml
oc apply -f service.yaml
oc apply -f route.yaml

# 4. Status prüfen
Write-Host "`n==> Warte auf Deployment..."
oc rollout status deployment/mcp-registry -n $NAMESPACE

Write-Host "`n==> Route URL:"
oc get route mcp-registry -n $NAMESPACE -o jsonpath='{.spec.host}'
Write-Host ""
