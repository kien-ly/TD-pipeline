Rất tốt, để triển khai biến **nhạy cảm (secret variables)** trong repo `helm-redpanda-stack/`, ta sẽ sử dụng:

* ✅ `Kubernetes Secret` để lưu biến nhạy cảm
* ✅ `secretKeyRef` để inject vào Pod thông qua `env`
* ✅ (Tuỳ chọn) Dùng `SOPS` hoặc `Sealed Secrets` để **mã hoá và commit an toàn vào Git**

---

## 🎯 Bạn có 4 biến nhạy cảm (ví dụ):

1. `AWS_ACCESS_KEY_ID`
2. `AWS_SECRET_ACCESS_KEY`
3. `POSTGRES_USER`
4. `POSTGRES_PASSWORD`

---

## 🧱 Bước 1: Tạo thư mục chứa secrets

Tạo thư mục:

```bash
mkdir -p secrets/base
```

Tạo file: `secrets/base/redpanda-secrets.yaml`

---

## 🔐 Bước 2: Viết file `redpanda-secrets.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: redpanda-secrets
  namespace: redpanda
type: Opaque
stringData:
  AWS_ACCESS_KEY_ID: AKIAEXAMPLEKEY
  AWS_SECRET_ACCESS_KEY: s3cr3tEXAMPLE
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: example123
```

> Nếu bạn dùng `kubectl`, tạo bằng lệnh:

```bash
kubectl create secret generic redpanda-secrets \
  --from-literal=AWS_ACCESS_KEY_ID=AKIAEXAMPLEKEY \
  --from-literal=AWS_SECRET_ACCESS_KEY=s3cr3tEXAMPLE \
  --from-literal=POSTGRES_USER=postgres \
  --from-literal=POSTGRES_PASSWORD=example123 \
  -n redpanda \
  --dry-run=client -o yaml > secrets/base/redpanda-secrets.yaml
```

---

## 🎛️ Bước 3: Cấu hình `values.yaml` để sử dụng secrets

Ví dụ `environments/dev/values.yaml`:

```yaml
kafka-connect:
  env:
    - name: AWS_ACCESS_KEY_ID
      valueFrom:
        secretKeyRef:
          name: redpanda-secrets
          key: AWS_ACCESS_KEY_ID
    - name: AWS_SECRET_ACCESS_KEY
      valueFrom:
        secretKeyRef:
          name: redpanda-secrets
          key: AWS_SECRET_ACCESS_KEY

debezium:
  env:
    - name: POSTGRES_USER
      valueFrom:
        secretKeyRef:
          name: redpanda-secrets
          key: POSTGRES_USER
    - name: POSTGRES_PASSWORD
      valueFrom:
        secretKeyRef:
          name: redpanda-secrets
          key: POSTGRES_PASSWORD
```

---

## 🛠️ Bước 4: Inject secrets vào trong `deployment.yaml`

Trong `charts/kafka-connect/templates/deployment.yaml`:

```yaml
env:
{{- toYaml .Values.env | nindent 12 }}
```

---

## 🔒 Bước 5 (Khuyên dùng): **Encrypt secret bằng SOPS**

Nếu bạn muốn **commit `redpanda-secrets.yaml` vào Git**:

1. Cài `sops`: `brew install sops`
2. Dùng age/gpg để mã hoá:

```bash
sops --encrypt --output redpanda-secrets.enc.yaml secrets/base/redpanda-secrets.yaml
```

Và add `.gitignore`:

```gitignore
secrets/base/redpanda-secrets.yaml   # plain-text version
!secrets/base/redpanda-secrets.enc.yaml
```

---

## 📦 Tổng kết

| Mục                | Công cụ | File hoặc cú pháp                    |
| ------------------ | ------- | ------------------------------------ |
| Lưu biến nhạy cảm  | Secret  | `secrets/base/redpanda-secrets.yaml` |
| Inject vào Pod     | Helm    | `secretKeyRef` trong `values.yaml`   |
| Bảo vệ file secret | SOPS    | `*.enc.yaml` (đưa vào Git an toàn)   |

