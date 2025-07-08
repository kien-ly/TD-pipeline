Deploy Helm follow env

```bash
helm upgrade --install redpanda-stack . \
  -f environments/dev/values.yaml \
  -n redpanda --create-namespace
```

Dưới đây là nội dung mẫu cho file `environments/production/values.yaml`, được thiết kế phù hợp với môi trường thực tế, cloud-native (EKS, GKE, AKS...), tập trung vào bảo mật và tính ổn định:

### Gợi ý thêm cho Secret trong `production`:

```bash
kubectl create secret generic aws-creds \
  --from-literal=accessKey=PROD_ACCESS_KEY \
  --from-literal=secretKey=PROD_SECRET_KEY \
  -n redpanda

kubectl create secret generic pg-creds \
  --from-literal=username=postgres \
  --from-literal=password=prod-secure-password \
  -n redpanda
```

---
