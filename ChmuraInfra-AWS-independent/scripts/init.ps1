# 1. Ustawienie Credentiali
$env:AWS_ACCESS_KEY_ID     = "XXX"
$env:AWS_SECRET_ACCESS_KEY = "XXX"
$env:AWS_SESSION_TOKEN     = "XXX"
# 2. Ustawienie zmiennych projektu
$env:AWS_REGION     = "us-east-1"
$env:AWS_ACCOUNT_ID = "XXX"

# 3. Logowanie do ECR
aws ecr get-login-password --region $env:AWS_REGION | docker login --username AWS --password-stdin "$env:AWS_ACCOUNT_ID.dkr.ecr.$env:AWS_REGION.amazonaws.com"

# 4. Budowanie i Wypychanie
$registry = "$env:AWS_ACCOUNT_ID.dkr.ecr.$env:AWS_REGION.amazonaws.com"
$backendImage    = "$registry/$env:PROJECT_NAME-backend:latest"
$frontendImage   = "$registry/$env:PROJECT_NAME-frontend:latest"
$prometheusImage = "$registry/$env:PROJECT_NAME-prometheus:latest"
$grafanaImage    = "$registry/$env:PROJECT_NAME-grafana:latest"

docker build --platform linux/amd64 -t $backendImage    -f "../../../ProstyProjekt/backend/Dockerfile"                   "../../../ProstyProjekt/backend"
docker build --platform linux/amd64 -t $frontendImage   -f "../../../ProstyProjekt/frontend/simpleNotatnik/Dockerfile"   "../../../ProstyProjekt/frontend/simpleNotatnik"
docker build --platform linux/amd64 -t $prometheusImage -f "../../../ProstyProjekt/prometheus/Dockerfile"                "../../../ProstyProjekt/prometheus"
docker build --platform linux/amd64 -t $grafanaImage    -f "../../../ProstyProjekt/grafana/Dockerfile"                   "../../../ProstyProjekt/grafana"

# Push
docker push $backendImage
docker push $frontendImage
docker push $prometheusImage
docker push $grafanaImage

# 5. Aktualizacja serwisów 
aws ecs update-service --cluster notatnik-cluster --service notatnik-backend-service --force-new-deployment
aws ecs update-service --cluster notatnik-cluster --service notatnik-frontend-service --force-new-deployment
aws ecs update-service --cluster notatnik-cluster --service notatnik-prometheus --force-new-deployment
aws ecs update-service --cluster notatnik-cluster --service notatnik-grafana --force-new-deployment