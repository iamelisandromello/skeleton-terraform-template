
---

### 📄 `modules/sqs/README.md`

```markdown
# 🔁 SQS Queue Module

Este módulo provisiona uma fila Amazon SQS para uso com funções Lambda ou outros produtores/consumidores.

---

## Recursos Criados

- `aws_sqs_queue`

---

## Entradas

| Nome        | Tipo     | Descrição             |
|-------------|----------|------------------------|
| `queue_name` | `string` | Nome da fila SQS       |

---

## Saídas

| Nome        | Tipo     | Descrição          |
|-------------|----------|---------------------|
| `queue_url`  | `string` | URL da fila         |
| `queue_arn`  | `string` | ARN da fila SQS     |

---

## Exemplo de Uso

```hcl
module "sqs" {
  source     = "../sqs"
  queue_name = "my-lambda-dev-queue"
}
