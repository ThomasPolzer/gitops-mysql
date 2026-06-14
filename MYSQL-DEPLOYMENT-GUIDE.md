# MySQL ArgoCD Deployment Anleitung

## 📋 Übersicht
Dieses Deployment stellt MySQL 8.0 in deinem Minikube-Cluster über ArgoCD bereit.

## 🚀 Schnellstart

### 1. Git-Repository vorbereiten
```bash
# Neues Repository erstellen (oder existierendes verwenden)
mkdir mysql-k8s
cd mysql-k8s

# Verzeichnisstruktur erstellen
mkdir mysql
cd mysql

# Alle Manifest-Dateien hier ablegen:
# - mysql-namespace.yaml
# - mysql-secret.yaml
# - mysql-pvc.yaml
# - mysql-configmap.yaml
# - mysql-deployment.yaml
# - mysql-service.yaml

# Zu Git hinzufügen und committen
git add .
git commit -m "Initial MySQL deployment manifests"
git push
```

### 2. ArgoCD Application erstellen
```bash
# Stelle sicher, dass ArgoCD läuft
kubectl get pods -n argocd

# Repository URL in mysql-argocd-app.yaml aktualisieren
# Ändere: https://github.com/your-username/mysql-k8s

# Application deployen
kubectl apply -f mysql-argocd-app.yaml
```

### 3. Deployment überprüfen
```bash
# ArgoCD Application Status
kubectl get application -n argocd
argocd app get mysql-deployment

# MySQL Pods prüfen
kubectl get pods -n mysql
kubectl logs -n mysql -l app=mysql

# Service Status
kubectl get svc -n mysql
```

## 🔐 Sicherheit - Wichtig!

### Passwörter sichern
⚠️ **NIEMALS echte Passwörter in Git committen!**

Nutze stattdessen:

**Option 1: Sealed Secrets**
```bash
# Sealed Secrets installieren
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml

# Secret versiegeln
echo -n "my-password" | kubectl create secret generic mysql-secret \
  --dry-run=client --from-file=/dev/stdin -o yaml | \
  kubeseal -o yaml > mysql-secret-sealed.yaml
```

**Option 2: External Secrets (mit Vault, AWS Secrets Manager, etc.)**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: mysql
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "mysql"
```

**Option 3: ArgoCD Secrets (native)**
```bash
# In ArgoCD UI oder CLI:
argocd secret create mysql-secret --from-file=password.txt
```

## 📊 Zugriff auf MySQL

### Von innerhalb des Clusters (ClusterIP Service)
```bash
kubectl run -it --rm debug --image=mysql:8.0 --restart=Never -n mysql -- \
  mysql -h mysql -u myapp_user -p myapp
# Passwort eingeben: myapp-password
```

### Von außen (NodePort Service)
```bash
# Minikube IP ermitteln
minikube ip  # z.B. 192.168.49.2

# Mit MySQL Client
mysql -h 192.168.49.2 -P 30306 -u myapp_user -p myapp
```

### Port Forwarding
```bash
kubectl port-forward -n mysql svc/mysql 3306:3306
# Dann: mysql -h 127.0.0.1 -u myapp_user -p myapp
```

## 🔄 Updates mit ArgoCD

### Automatische Synchronisierung
Das Deployment synchronisiert sich automatisch, wenn du Änderungen zu Git pushst:

```bash
# Änderung in mysql-deployment.yaml
git add .
git commit -m "Update MySQL resources"
git push

# ArgoCD erkennt die Änderung automatisch
kubectl get application -n argocd mysql-deployment
```

### Manuelle Synchronisierung
```bash
argocd app sync mysql-deployment
```

## 📈 Monitoring und Logs

```bash
# Pod Logs anschauen
kubectl logs -n mysql -l app=mysql -f

# Beschreibung des Pods
kubectl describe pod -n mysql -l app=mysql

# Events überwachen
kubectl get events -n mysql --sort-by='.lastTimestamp'

# Storage Status
kubectl get pvc -n mysql
```

## 🗑️ Cleanup

```bash
# ArgoCD Application löschen
kubectl delete application mysql-deployment -n argocd

# Namespace mit allen Ressourcen löschen
kubectl delete namespace mysql
```

## 🐛 Troubleshooting

### Pod startet nicht
```bash
kubectl describe pod -n mysql -l app=mysql
kubectl logs -n mysql -l app=mysql --previous  # Logs vom letzten Versuch
```

### PVC hängt fest
```bash
kubectl delete pvc mysql-pvc -n mysql
# Oder mit Finalizers:
kubectl patch pvc mysql-pvc -n mysql -p '{"metadata":{"finalizers":null}}'
```

### Verbindungsprobleme
```bash
# MySQL in Pod starten und lokale Tests machen
kubectl exec -it -n mysql deployment/mysql -- mysql -u root -p -e "SELECT 1;"
```

### ArgoCD synced aber nicht richtig
```bash
argocd app sync mysql-deployment --prune
argocd app wait mysql-deployment
```

## 📦 Ressourcen anpassen

Für WSL/Minikube empfohlene Einstellungen in mysql-deployment.yaml:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

Bei mehr Speicher verfügbar erhöhen:
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

## 📝 Zusätzliche Tipps

### Backup erstellen
```bash
kubectl exec -n mysql deployment/mysql -- mysqldump \
  -u root -p${MYSQL_ROOT_PASSWORD} --all-databases > backup.sql
```

### Restore durchführen
```bash
kubectl exec -n mysql deployment/mysql -- mysql \
  -u root -p${MYSQL_ROOT_PASSWORD} < backup.sql
```

### Health Check
```bash
kubectl run -it --rm healthcheck --image=mysql:8.0 --restart=Never -n mysql -- \
  mysqladmin -h mysql -u root ping
```

---

**Viel Erfolg mit deinem MySQL Deployment! 🎯**
