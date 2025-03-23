# Настройки
$CLUSTER_NAME = "minikube"
$CLUSTER_SERVER = "https://172.17.29.70:6443"  # Замените на адрес вашего API-сервера
$CA_CERT = "C:\Users\$env:USERNAME\.minikube\ca.crt"  # Путь к CA сертификату Minikube
$CA_KEY = "C:\Users\$env:USERNAME\.minikube\ca.key"   # Путь к CA ключу Minikube
$OUTPUT_DIR = "c:\yandex\sprint7\architecture-sprint-7\task4\users"     # Директория для хранения ключей и конфигов

# Создаем директорию для пользователей
New-Item -ItemType Directory -Path $OUTPUT_DIR -Force
Set-Location $OUTPUT_DIR

# Функция для создания пользователя
function Create-User {
    param (
        [string]$USER_NAME,
        [string]$GROUP_NAME
    )

    Write-Host "Creating user $USER_NAME..."

    # Генерация приватного ключа
    $KEY_PATH = "$OUTPUT_DIR\$USER_NAME.key"
    $CSR_PATH = "$OUTPUT_DIR\$USER_NAME.csr"
    $CRT_PATH = "$OUTPUT_DIR\$USER_NAME.crt"

    # Генерация приватного ключа и CSR
    openssl genrsa -out $KEY_PATH 2048
    if (-Not (Test-Path $KEY_PATH)) {
        throw "Couldn't create a private key for $USER_NAME"
    }

    openssl req -new -key $KEY_PATH -out $CSR_PATH -subj "/CN=$USER_NAME/O=$GROUP_NAME"
    if (-Not (Test-Path $CSR_PATH)) {
        throw "Failed to create CSR for $USER_NAME"
    }

    # Подписание CSR с помощью CA
    openssl x509 -req -in $CSR_PATH -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial -out $CRT_PATH -days 365
    if (-Not (Test-Path $CRT_PATH)) {
        throw "Couldn't sign the certificate for $USER_NAME"
    }

    # Создание kubeconfig
    $KUBECONFIG_PATH = "$OUTPUT_DIR\$USER_NAME.kubeconfig"
    kubectl config set-credentials $USER_NAME --client-certificate=$CRT_PATH --client-key=$KEY_PATH --embed-certs=true
    kubectl config set-context "$USER_NAME-context" --cluster=$CLUSTER_NAME --user=$USER_NAME
    kubectl config use-context "$USER_NAME-context"
    kubectl config view --flatten | Out-File -FilePath $KUBECONFIG_PATH

    Write-Host "Kubeconfig for $USER_NAME created: $KUBECONFIG_PATH"
}

# Создаем пользователей
Create-User -USER_NAME "userD" -GROUP_NAME "developer"
Create-User -USER_NAME "userM" -GROUP_NAME "manager"

# Возвращаем контекст на default (опционально)
kubectl config use-context default

Write-Host "Done"