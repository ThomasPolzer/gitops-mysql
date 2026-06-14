# 🗄️ MySQL ArgoCD Deployment für Minikube (WSL Ubuntu 22.04)

Vollständiges Setup zur Bereitstellung von MySQL in Kubernetes mit GitOps über ArgoCD.

## 📦 Inhalt

```
├── mysql-argocd-app.yaml        # ArgoCD Application Definition
├── mysql-namespace.yaml          # Kubernetes Namespace
├── mysql-secret.yaml             # Zugangsdaten (Root, User)
├── mysql-configmap.yaml          # MySQL Konfiguration
├── mysql-pvc.yaml                # Persistenter Speicher
├── mysql-deployment.yaml         # MySQL Pod Deployment
├── mysql-service.yaml            # ClusterIP + NodePort Services
├── kustomization.yaml            # Kustomize Overlay
├── deploy-mysql.sh               # Automatisiertes Deployment Script
├── MYSQL-DEPLOYMENT-GUIDE.md     # Detaillierte Anleitung
└── README.md                     # Diese Datei
```

## 🚀 Schnellstart (3 Schritte)

### 1. **Manifest-Dateien vorbereiten**
```bash
# Alle YAML Dateien in ein Git-Repository legen
mkdir -p mysql-deployment/mysql
cd mysql-deployment/mysql
# Kopiere alle mysql-*.yaml und kustomization.yaml hierher
git init
git add .
git commit -m "Initial MySQL manifests"
```

### 2. **ArgoCD Application erstellen**
```bash
# Repository URL in mysql-argocd-app.yaml aktualisieren
kubectl apply -f mysql-argocd-app.yaml
```

### 3. **Status überprüfen**
```bash
kubectl get pods -n mysql
kubectl get svc -n mysql
```

## 💻 Mit dem Helper Script (empfohlen)

```bash
chmod +x deploy-mysql.sh
./deploy-mysql.sh

# Menü wählen:
# 1) Prüfe Voraussetzungen
# 2) Deploye MySQL
# 3) Deploye ArgoCD Application
# 4) Zeige Status
# 5) Teste Verbindung
# etc.
```

## 🔐 Sicherheit beachten!

⚠️ **Passwörter in `mysql-secret.yaml` ändern!**

Aktuell gesetzt:
- Root Password: `your-secure-password-here`
- App User: `myapp_user`
- App Password: `myapp-password`

### Sichere Alternativen:
1. **Sealed Secrets** (verschlüsselt in Git)
2. **External Secrets** (Integration mit Vault/AWS)
3. **ArgoCD Secrets** (native Unterstützung)

Siehe `MYSQL-DEPLOYMENT-GUIDE.md` für Details.

## 📊 Zugriff auf MySQL

### Option 1: In-Cluster (von anderen Pods)
```bash
# Aus anderen Pods im Cluster
mysql -h mysql.mysql.svc.cluster.local -u myapp_user -p
```

### Option 2: Port Forwarding
```bash
kubectl port-forward -n mysql svc/mysql 3306:3306
mysql -h 127.0.0.1 -u myapp_user -p
```

### Option 3: NodePort (von WSL Host)
```bash
# Minikube IP ermitteln
minikube ip  # z.B. 192.168.49.2

# Mit MySQL Client
mysql -h <MINIKUBE_IP> -P 30306 -u myapp_user -p
```

### Option 4: Direkter Pod-Zugriff
```bash
kubectl exec -it -n mysql deployment/mysql -- mysql -u root -p
```

## 🔄 GitOps Workflow mit ArgoCD

### Automatische Synchronisierung
```bash
# 1. Änderung im Git-Repository machen
# 2. Committen und Pushen
git push

# 3. ArgoCD erkennt die Änderung automatisch
# (oder manuell: kubectl apply -f mysql-argocd-app.yaml)
```

### Status überwachen
```bash
# ArgoCD CLI
argocd app get mysql-deployment
argocd app sync mysql-deployment

# Oder Kubernetes API
kubectl get application -n argocd mysql-deployment
```

## 📈 Monitoring & Debugging

```bash
# Logs anschauen
kubectl logs -n mysql -l app=mysql -f

# Pod beschreiben
kubectl describe pod -n mysql -l app=mysql

# Events
kubectl get events -n mysql --sort-by='.lastTimestamp'

# Storage Status
kubectl get pvc -n mysql
df -h
```

## 🗑️ Cleanup

```bash
# Alles löschen
kubectl delete namespace mysql

# Oder über ArgoCD
kubectl delete application mysql-deployment -n argocd
```

## 🛠️ Tipps für WSL/Minikube

### Minikube richtig starten
```bash
# Mit ausreichend Ressourcen
minikube start --cpus=4 --memory=4096

# Storage Plugin aktivieren
minikube addons enable storage-provisioner
```

### Performance optimieren
In `mysql-deployment.yaml`:
```yaml
resources:
  requests:
    memory: "256Mi"   # WSL: 256-512 Mi
    cpu: "250m"      # WSL: 250-500m
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Netzwerk-Probleme lösen
```bash
# Minikube Netzwerk prüfen
minikube ssh
  ip addr
  ping 8.8.8.8

# Docker/Containerd logs
minikube logs --follow
```

## 📋 Ressourcen-Anforderungen

- **Minikube**: 2+ CPU Kerne, 4+ GB RAM
- **MySQL Pod**: 256 MB - 1 GB RAM (konfigurierbar)
- **Storage**: 10 GB PVC (konfigurierbar)
- **WSL**: WSL2 empfohlen für bessere Performance

## 🆘 Häufige Probleme

### Pod startet nicht
```bash
kubectl describe pod -n mysql -l app=mysql
kubectl logs -n mysql -l app=mysql --previous
```

### Verbindung fehlgeschlagen
```bash
# Im Pod testen
kubectl exec -it -n mysql deployment/mysql -- \
  mysqladmin -u root ping
```

### PVC hängt fest
```bash
kubectl delete pvc mysql-pvc -n mysql --grace-period=0 --force
```

### ArgoCD synchronisiert nicht
```bash
argocd app sync mysql-deployment --prune
```

## 📚 Weitere Ressourcen

- [MySQL Docker Hub](https://hub.docker.com/_/mysql)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Dokumentation](https://argo-cd.readthedocs.io/)
- [Minikube Guide](https://minikube.sigs.k8s.io/)

## 📝 Next Steps

1. ✅ MySQL deployen
2. ✅ Zugangsdaten sichern (Sealed Secrets)
3. ✅ Backup-Strategie einrichten
4. ✅ Monitoring aktivieren (Prometheus/Grafana)
5. ✅ Multi-Replica Setup für HA
6. ✅ CI/CD Integration

## 👨‍💻 Support

Weitere Hilfe in `MYSQL-DEPLOYMENT-GUIDE.md` oder:
```bash
kubectl describe pod -n mysql -l app=mysql
kubectl logs -n mysql -l app=mysql
```

---

**Status**: Ready to deploy 🚀  
**Getestet mit**: Ubuntu 22.04 WSL, Minikube, ArgoCD  
**MySQL Version**: 8.0
