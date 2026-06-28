#!/bin/bash

# MySQL ArgoCD Deployment Helper Script
# Vereinfacht die Bereitstellung und Verwaltung

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funktionen
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check Prerequisites
check_prerequisites() {
    print_header "Prüfe Voraussetzungen"
    
    # Kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl nicht gefunden"
        exit 1
    fi
    print_success "kubectl gefunden"
    
    # Minikube (optional)
    if command -v minikube &> /dev/null; then
        print_success "Minikube gefunden"
    else
        print_warning "Minikube nicht gefunden (optional)"
    fi
    
    # Git (optional)
    if command -v git &> /dev/null; then
        print_success "Git gefunden"
    else
        print_warning "Git nicht gefunden (benötigt für ArgoCD Integration)"
    fi
}

# Deploy MySQL
deploy_mysql() {
    print_header "Deploye MySQL"
    
    # Namespace erstellen
    kubectl apply -f mysql-namespace.yaml
    print_success "Namespace erstellt"
    
    # Secret erstellen
    kubectl apply -f mysql-secret.yaml
    print_success "Secret erstellt"
    
    # ConfigMap erstellen
    kubectl apply -f mysql-configmap.yaml
    print_success "ConfigMap erstellt"
    
    # PVC erstellen
    kubectl apply -f mysql-pvc.yaml
    print_success "PersistentVolumeClaim erstellt"
    
    # Deployment erstellen
    kubectl apply -f mysql-deployment.yaml
    print_success "Deployment erstellt"
    
    # Service erstellen
    kubectl apply -f mysql-service.yaml
    print_success "Services erstellt"
    
    # Warten auf Pod-Start
    print_warning "Warte auf MySQL Pod-Start..."
    kubectl wait --for=condition=ready pod -l app=mysql -n mysql --timeout=120s
    print_success "MySQL ist bereit"

    # Port-Weiterleitung auf Host zum Zugriff via MySQL-Workbench o.ä. 
    #kubectl port-forward -n mysql svc/mysql 3306:3306
    #print_success "Port-Weiterleitung eingerichtet"
}

# Deploy ArgoCD Application
deploy_argocd() {
    print_header "Deploye ArgoCD Application"
    
    # Prüfe ob ArgoCD läuft
    if ! kubectl get namespace argocd &> /dev/null; then
        print_error "ArgoCD Namespace nicht gefunden!"
        echo "Installiere ArgoCD mit:"
        echo "  kubectl create namespace argocd"
        echo "  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
        return 1
    fi
    
    # ArgoCD Application erstellen
    kubectl apply -f mysql-argocd-app.yaml
    print_success "ArgoCD Application erstellt"
}

# Show Status
show_status() {
    print_header "MySQL Deployment Status"
    
    echo ""
    echo "Pods:"
    kubectl get pods -n mysql
    
    echo ""
    echo "Services:"
    kubectl get svc -n mysql
    
    echo ""
    echo "PersistentVolumeClaims:"
    kubectl get pvc -n mysql
    
    echo ""
    echo "Deployment:"
    kubectl get deployment -n mysql
    
    if kubectl get application -n argocd 2>/dev/null | grep -q mysql-deployment; then
        echo ""
        echo "ArgoCD Application:"
        kubectl get application -n argocd mysql-deployment
    fi
}

# Test Connection
test_connection() {
    print_header "Teste MySQL Verbindung"
    
    # Port Forwarding starten
    kubectl port-forward -n mysql svc/mysql 3306:3306 &
    PF_PID=$!
    
    sleep 2
    
    if command -v mysql &> /dev/null; then
        echo ""
        echo "Versuche Verbindung zu MySQL..."
        mysql -h 127.0.0.1 -u myapp_user -pmyapp-password -e "SELECT VERSION();"
        if [ $? -eq 0 ]; then
            print_success "MySQL Verbindung funktioniert!"
        else
            print_error "MySQL Verbindung fehlgeschlagen"
        fi
    else
        print_warning "mysql-client nicht installiert, Verbindungstest übersprungen"
        echo "Installiere mit: sudo apt-get install mysql-client"
    fi
    
    # Port Forwarding beenden
    kill $PF_PID 2>/dev/null || true
}

# Show Logs
show_logs() {
    print_header "MySQL Logs"
    kubectl logs -n mysql -l app=mysql -f --tail=50
}

# Delete Deployment
delete_deployment() {
    print_header "Lösche MySQL Deployment"
    
    read -p "Sicher? (j/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Jj]$ ]]; then
        kubectl delete namespace mysql
        print_success "MySQL Namespace gelöscht"
    else
        print_warning "Abgebrochen"
    fi
}

# Get MySQL IP for access
get_mysql_info() {
    print_header "MySQL Zugriffsinformationen"
    
    echo "Im Cluster:"
    echo "  Host: mysql.mysql.svc.cluster.local"
    echo "  Port: 3306"
    echo ""
    
    echo "Von außen (NodePort):"
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "192.168.49.2")
    echo "  Host: $MINIKUBE_IP"
    echo "  Port: 30306"
    echo ""
    
    echo "Mit Port Forwarding:"
    echo "  kubectl port-forward -n mysql svc/mysql 3306:3306"
    echo "  Host: 127.0.0.1"
    echo "  Port: 3306"
    echo ""
    
    echo "Zugangsdaten:"
    echo "  Root User: root"
    echo "  Root Password: (siehe mysql-secret.yaml)"
    echo "  App User: myapp_user"
    echo "  App Password: myapp-password"
    echo "  Database: myapp"
}

# Main Menu
show_menu() {
    echo ""
    print_header "MySQL ArgoCD Deployment Helper"
    echo "1) Prüfe Voraussetzungen"
    echo "2) Deploye MySQL"
    echo "3) Deploye ArgoCD Application"
    echo "4) Zeige Status"
    echo "5) Teste Verbindung"
    echo "6) Zeige Logs"
    echo "7) Zeige MySQL Zugriffsinformationen"
    echo "8) Lösche Deployment"
    echo "9) Komplettes Setup (1-3)"
    echo "0) Beenden"
    echo ""
}

# Main Loop
main() {
    while true; do
        show_menu
        read -p "Wähle Option (0-9): " choice
        
        case $choice in
            1) check_prerequisites ;;
            2) deploy_mysql ;;
            3) deploy_argocd ;;
            4) show_status ;;
            5) test_connection ;;
            6) show_logs ;;
            7) get_mysql_info ;;
            8) delete_deployment ;;
            9) 
                check_prerequisites
                deploy_mysql
                deploy_argocd
                show_status
                ;;
            0) 
                print_success "Auf Wiedersehen!"
                exit 0 
                ;;
            *) print_error "Ungültige Option" ;;
        esac
    done
}

# Starte
main
