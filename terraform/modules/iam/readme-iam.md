
---

### 📄 `modules/iam/README.md`

```markdown
# 🔐 IAM Role and Policies Module

Este módulo cria a IAM Role de execução da Lambda e suas políticas necessárias.

---

## Recursos Criados

- `aws_iam_role` – Role com trust policy para Lambda
- `aws_iam_role_policy` – Políticas de logging e envio para SQS

---

## Entradas

| Nome                  | Tipo     | Descrição                                  |
|-----------------------|----------|---------------------------------------------|
| `lambda_role_name`     | `string` | Nome da role da Lambda                      |
| `logging_policy_name`  | `string` | Nome da política de logs                    |
| `publish_policy_name`  | `string` | Nome da política de publicação na SQS       |
| `sqs_queue_arn`        | `string` | ARN da fila SQS (para permissão de envio)   |

---

## Saídas

| Nome        | Tipo     | Descrição                          |
|-------------|----------|-------------------------------------|
| `role_arn`   | `string` | ARN da IAM Role atribuída à Lambda |

---

## Exemplo de Uso

```hcl
module "iam" {
  source              = "../iam"
  lambda_role_name    = "my-lambda-dev-role"
  logging_policy_name = "my-lambda-dev-logs"
  publish_policy_name = "my-lambda-dev-publish"
  sqs_queue_arn       = module.sqs.queue_arn
}
